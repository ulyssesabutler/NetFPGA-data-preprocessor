/*
 * Copyright (c) 2014 Hwanju Kim
 * Copyright (c) 2016 José Fernando Zazo Rollón
 * Copyright (c) 2016, 2017 Vincenzo Maffione
 * Copyright (c) 2016, 2017, 2019 Marcin Wójcik
 * All rights reserved.
 *
 * This software was developed by
 * Stanford University and the University of Cambridge Computer Laboratory
 * under National Science Foundation under Grant No. CNS-0855268,
 * the University of Cambridge Computer Laboratory under EPSRC INTERNET Project EP/H040536/1 and
 * by the University of Cambridge Computer Laboratory under DARPA/AFRL contract FA8750-11-C-0249 ("MRC2"),
 * as part of the DARPA MRC research programme and under the SSICLOPS (grant
 * agreement No. 644866) project as part of the European Union’s Horizon 2020
 * research and innovation programme 2014-2018 and under EPSRC EARL project EP/P025374/1. 
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/types.h>
#include <linux/pci.h>
#include <linux/netdevice.h>
#include <linux/etherdevice.h>
#include <linux/interrupt.h>
#include <linux/spinlock.h>
#include <linux/proc_fs.h>
#include "sume_uam.h"

u64 sume_uam_default_dev_addr = 0x000f530dd164;
#define	SUME_RIFFA_MAGIC		0xcafe

/* UAM register offsets. */
#define	RIFFA_RX_SG_LEN_REG_OFF		0x0

#define DEFAULT_MSG_ENABLE (NETIF_MSG_DRV|NETIF_MSG_PROBE|NETIF_MSG_LINK|NETIF_MSG_IFDOWN|NETIF_MSG_IFUP|NETIF_MSG_RX_ERR)
static int debug = -1;

#define SUME_UAM_DRV_NAME	"sume_uam"

#define DISABLE_INTR

#define SUME_METADATA_LEN	16

static bool verbose = false;
module_param(verbose, bool, 0444);

struct sume_uam_adapter *adapter_glob;

unsigned int flags;
spinlock_t lock;

static irqreturn_t sume_uam_int_handler(int irq, void *opaque);
static int
sume_uam_rx_refill(struct sume_uam_netdev_priv *priv);

static int
mod_show(struct seq_file *m, void *v)
{
	struct sume_uam_adapter *adapter = adapter_glob;
	struct sume_uam_netdev_priv *priv = netdev_priv(adapter->netdev[0]);

	seq_printf(m, "simulating an interrupt \n");
	if (verbose){
		pr_info("TX head #%d\n", priv->adapter->dma->dma_engine[1].head);
		pr_info("TX tail #%d\n", priv->adapter->dma->dma_engine[1].tail);
		pr_info("TX NTC #%d\n", priv->tx_ntc);
		pr_info("RX head #%d\n", priv->adapter->dma->dma_engine[0].head);
		pr_info("RX tail #%d\n", priv->adapter->dma->dma_engine[0].tail);
		pr_info("RX NTC #%d\n", priv->rx_ntc);
	}
	return 0;
}

static int
mod_open(struct inode *inode, struct file *file)
{
    return single_open(file, mod_show, NULL);
}

static const struct file_operations mod_fops = {
    .owner      = THIS_MODULE,
    .open       = mod_open,
    .read       = seq_read,
    .llseek     = seq_lseek,
    .release    = single_release,
};

static irqreturn_t
sume_uam_int_handler(int irq, void *opaque)
{
	struct sume_uam_adapter *adapter = opaque;
	struct sume_uam_netdev_priv *priv = netdev_priv(adapter->netdev[0]);

	 if (verbose) {
		pr_info("IRQ handler %d\n", irq);
	 }
	napi_schedule(&priv->napi);

	return IRQ_HANDLED;
}

static void
reset_core_dma(struct sume_uam_adapter *adapter)
{
	struct dma_engine *engine = adapter->dma->dma_engine + 2;
	u64 val = -1;
	memcpy_toio(engine, &val, sizeof(val));
}

static int
sume_uam_rx_refill(struct sume_uam_netdev_priv *priv)
{
	struct sume_uam_adapter *adapter = priv->adapter;
	struct dma_descriptor *desc_base;
	struct dma_descriptor *desc;
	struct dma_engine *engine;
	struct desc_info *info;
	struct sk_buff *skb;
	u64 len = 1600;
	int n = 0;

	engine = adapter->dma->dma_engine + DMA_ENG_RX;
	desc_base = engine->dma_descriptor;

	while (RING_NEXT_IDX(priv->rx_ntu) != priv->rx_ntc) {

		desc = desc_base + priv->rx_ntu;
		info = priv->rx_desc_info + priv->rx_ntu;

		skb = netdev_alloc_skb_ip_align(priv->netdev, len);
		if (!skb) {
			pr_err("Failed to alloc RX skb\n");
			break;
		}

		info->buf = skb;
		info->len = len;
		info->paddr = pci_map_single(adapter->pdev, skb->data,
					     info->len, PCI_DMA_FROMDEVICE);

		memcpy_toio(&desc->address, &info->paddr, 8);
		memcpy_toio(&desc->size, &info->len, 8);
		desc->generate_irq = 1;

		/* Make room for metadata. This increments skb->data, and
		 * so must be done after pci_map_single(). */
		skb_reserve(skb, SUME_METADATA_LEN);

		priv->rx_ntu = RING_NEXT_IDX(priv->rx_ntu);
		n ++;
	}

	if (n && verbose) {
		pr_info("Refilled %d RX buffers\n", n);
	}

	/* See the comment related to TAIL_TX_OFFSET. */
  if (n){
		write_reg(adapter, TAIL_RX_OFFSET, priv->rx_ntu);
	}

	return 0;
}

static int
sume_uam_rx_clean(struct sume_uam_netdev_priv *priv)
{
	struct sume_uam_adapter *adapter = priv->adapter;
	struct dma_engine *engine;
	struct dma_descriptor *desc;
	struct desc_info *info;
	struct sk_buff *skb;
	int n = 0;

	engine = adapter->dma->dma_engine + DMA_ENG_RX;

	while (priv->rx_ntc != priv->rx_ntu) {
		desc = engine->dma_descriptor + priv->rx_ntc;
		info = priv->rx_desc_info + priv->rx_ntc;

		if (info->buf) {
			skb = info->buf;
			pci_unmap_single(adapter->pdev, info->paddr,
				         info->len, PCI_DMA_FROMDEVICE);
			dev_kfree_skb_any(skb);
			info->buf = 0;
		}

		priv->rx_ntc = RING_NEXT_IDX(priv->rx_ntc);
		n ++;
	}
	if (verbose) {
		pr_info("Cleaned %d unused RX buffers\n", n);
	}

	return 0;
}

static int
sume_uam_tx_clean(struct sume_uam_netdev_priv *priv)
{
	struct desc_info *info;
	int i;

	for (i = 0; i < NUM_DESCRIPTORS; i++) {
		info = priv->tx_desc_info + i;
		if (info->buf) {
			kfree(info->buf);
			info->buf = NULL;
		}
	}

	return 0;
}

static int
sume_uam_tx_alloc(struct sume_uam_netdev_priv *priv)
{
	struct desc_info *info;
	int len = 1560;
	int i;

	for (i = 0; i < NUM_DESCRIPTORS; i++) {
		info = priv->tx_desc_info + i;
		if (!info->buf) {
			info->buf = kmalloc(len, GFP_KERNEL);
			if (!info->buf) {
				sume_uam_tx_clean(priv);
				return -ENOMEM;
			}
		}
	}

	return 0;
}

static int
sume_uam_up(struct net_device *netdev)
{
	struct sume_uam_netdev_priv *priv = netdev_priv(netdev);
	char msix_name[32];
	int err;
	int i;

 #if LINUX_VERSION_CODE >= KERNEL_VERSION(3,12,0)
	/* The reason to reset pci here in up handler is
	 * that reset is possible once pdev is probed, but
	 * in probe handler, pdev/bus is locked so defer
	 * the reset to up handler. The reset is for
	 * initializing all state machines of DMA */
	err = pci_reset_bus(priv->adapter->pdev->bus);
	if (err) {
		pr_err("failed to reset bus (err=%d)\n", err);
		return err;
	}
	pr_info("PCI bus reset");
#endif

	reset_core_dma(priv->adapter);

	memset(priv->tx_desc_info, 0, sizeof(priv->tx_desc_info));
	memset(priv->rx_desc_info, 0, sizeof(priv->rx_desc_info));

	err = sume_uam_rx_refill(priv);
	if (err) {
		pr_err("Failed to refill RX ring\n");
		return err;
	}

	err = sume_uam_tx_alloc(priv);
	if (err) {
		pr_err("Failed to allocate TX buffers\n");
		sume_uam_rx_clean(priv);
		return err;
	}

	for (i = 0; i < NUM_DMA_ENGINES; i++) {
		snprintf(msix_name, sizeof(msix_name), "sume-%d", i);
		err = request_irq(priv->adapter->msix_entries[i].vector,
				  sume_uam_int_handler, 0, msix_name, priv->adapter);
		if (err) {
			pr_err("Unable to allocate interrupt #%d", i);
			for (; i >= 0; i--) {
				free_irq(priv->adapter->msix_entries[i].vector, priv->adapter);
			}
		}
		pr_info("IRQ %d will be used for sume-%d\n",
			priv->adapter->msix_entries[i].vector, i);
	}

	netif_start_queue(netdev);
	napi_enable(&priv->napi);

	priv->adapter->dma->dma_common_block.irq_enable = 1;

	pr_info("sume_uam_up(%p)\n", netdev);

	return 0;
}

static int
sume_uam_down(struct net_device *netdev)
{
	struct sume_uam_netdev_priv *priv = netdev_priv(netdev);
	int i;

	pr_info("sume_uam_down(%p)\n", netdev);

	priv->adapter->dma->dma_common_block.irq_enable = 0;

	napi_disable(&priv->napi);
	netif_stop_queue(netdev);

	sume_uam_tx_clean(priv);
	sume_uam_rx_clean(priv);

	for (i = 0; i < NUM_DMA_ENGINES; i++) {
		free_irq(priv->adapter->msix_entries[i].vector, priv->adapter);
	}

	return 0;
}

static netdev_tx_t
sume_uam_start_xmit(struct sk_buff *skb, struct net_device *netdev)
{
	struct sume_uam_netdev_priv *priv = netdev_priv(netdev);
	unsigned int port;
	struct sume_uam_adapter *adapter;
	struct dma_core *dma;
	struct dma_engine *engine;
	struct dma_descriptor *desc;
	struct desc_info *info;
	uint32_t *p32;
	uint16_t *p16;

	port = netdev_port_num(netdev);

	adapter = netdev_adapter(netdev);

	dma = adapter->dma;
	engine = dma->dma_engine + DMA_ENG_TX;
	desc = engine->dma_descriptor + priv->tx_ntu;
	info = priv->tx_desc_info + priv->tx_ntu;

	/* Pad to the minimum length. */
	if (skb_padto(skb, ETH_ZLEN) != 0) {
		netdev->stats.tx_dropped++;
		return NETDEV_TX_OK;
	}
	if (unlikely(skb->len < ETH_ZLEN)) {
		skb->len = ETH_ZLEN;
	}

	info->len = skb->len + SUME_METADATA_LEN;

	/* Fill in the metadata. */
	p16 = (uint16_t *)info->buf;
	/* Write CPU(DMA) source port (odd number). */
	*p16++ = cpu_to_le16(1 << (port * 2 + 1));
	/* Write MAC destination port (even number). */
	*p16++ = cpu_to_le16(1 << (port * 2));
	/* Buffer length and magic number. */
	*p16++ = cpu_to_le16(info->len);
	*p16++ = cpu_to_le16(SUME_RIFFA_MAGIC);
	/* Write 64 bit timestamp. */
	p32 = (uint32_t *)p16;
	*p32++ = cpu_to_le32(0);
	*p32++ = cpu_to_le32(0);

	/* Fill in payload. */
	skb_copy_from_linear_data(skb, info->buf + SUME_METADATA_LEN, skb->len);
	dev_kfree_skb_any(skb);

	info->paddr = pci_map_single(adapter->pdev, info->buf, info->len,
				     PCI_DMA_TODEVICE);

	/* Initialize descriptor. */
	memcpy_toio(&desc->address, &info->paddr, 8);
	memcpy_toio(&desc->size, &info->len, 8);
	desc->generate_irq = 1;

	 if (verbose) {
			pr_info("Using TX desc #%d (buf=%p,paddr=%llx,size=%llu,"
			"irq=%x)\n", priv->tx_ntu, info->buf,
			desc->address, desc->size, desc->generate_irq);
	 }

	/* To start the DMA transaction we have to write to the tail register,
	 * but using the instruction
	 *
	 *      engine->tail = priv->tx_ntu;
	 *
	 * will only set the lower 8 bits of the 10 bits register.
	 * We use write_reg() instead, which does not overwrite upper bits,
	 * since the head register is read only.
	*/
	write_reg(adapter, TAIL_TX_OFFSET, priv->tx_ntu);

	priv->tx_ntu = RING_NEXT_IDX(priv->tx_ntu);

	netdev->stats.tx_packets++;
	netdev->stats.tx_bytes += info->len - SUME_METADATA_LEN;

	if (RING_NEXT_IDX(priv->tx_ntu) == priv->tx_ntc) {
			/* TX queue is full. */
			netif_stop_queue(netdev);
	}

	return NETDEV_TX_OK;
}

static int
sume_uam_poll(struct napi_struct *napi, int budget)
{
	struct sume_uam_netdev_priv *priv = container_of(napi,
				struct sume_uam_netdev_priv, napi);
	struct sume_uam_adapter *adapter = priv->adapter;
	struct dma_engine *engine;
	struct net_device *netdev = priv->netdev;
	struct dma_descriptor *desc;
	struct desc_info *info;
	bool tx_complete = true;
	bool rx_complete = true;
	int n;

  if (verbose) {
		pr_info("NAPI scheduled on %p\n", priv);
  }

#ifdef DISABLE_INTR
	adapter->dma->dma_common_block.irq_enable = 0;
#endif

	/* Clean up TX ring. */
	engine = adapter->dma->dma_engine + DMA_ENG_TX;

	for (n = 0; priv->tx_ntc != engine->head && n < budget; n++) {
		desc = engine->dma_descriptor + priv->tx_ntc;
		info = priv->tx_desc_info + priv->tx_ntc;

		pci_unmap_single(adapter->pdev, info->paddr, info->len,
				 PCI_DMA_TODEVICE);

	  if (verbose) {
			pr_info("Clean TX desc #%d (buf=%p,paddr=%llx,size=%llu,irq=%x"
				")\n", priv->tx_ntc, info->buf,
				desc->address, desc->size, desc->generate_irq);
	  }

		priv->tx_ntc = RING_NEXT_IDX(priv->tx_ntc);
	}

	if (n == budget){
		tx_complete = false;
	}

	if (n && netif_queue_stopped(netdev)) {
			netif_wake_queue(netdev);
	}

	/* Clean up RX ring. */
	engine = adapter->dma->dma_engine + DMA_ENG_RX;

	for (n = 0; priv->rx_ntc != engine->head && n < budget; n++) {

		struct sk_buff *skb;
		uint64_t readlen;

		desc = engine->dma_descriptor + priv->rx_ntc;
		info = priv->rx_desc_info + priv->rx_ntc;

		pci_unmap_single(adapter->pdev, info->paddr, info->len,
				 PCI_DMA_FROMDEVICE);

		if (verbose) {
			pr_info("Clean RX desc #%d (buf=%p,paddr=%llx,size=%llu,irq=%x"
				")\n", priv->rx_ntc, info->buf,
				desc->address, desc->size, desc->generate_irq);
		}

		memcpy_fromio(&readlen, &desc->size, 8);

		readlen -= SUME_METADATA_LEN; /* Subtract metadata length. */

		skb = info->buf;
		info->buf = NULL;

		skb_put(skb, readlen);
		priv->netdev->stats.rx_packets++;
		priv->netdev->stats.rx_bytes += skb->len;
		skb->protocol = eth_type_trans(skb, priv->netdev);
		napi_gro_receive(napi, skb);

		priv->rx_ntc = RING_NEXT_IDX(priv->rx_ntc);
	}

	sume_uam_rx_refill(priv);

	if (n == budget){
		rx_complete = false;
	}
	rx_complete &= tx_complete;

	if (!rx_complete){
		return budget;
	}

	napi_complete(napi);

#ifdef DISABLE_INTR
	adapter->dma->dma_common_block.irq_enable = 1;
#endif

	return 0;
}

static int
sume_uam_do_ioctl(struct net_device *netdev, struct ifreq *ifr, int cmd)
{

	struct sume_uam_adapter *adapter = netdev_adapter(netdev);
	struct sume_ifreq sifr;

	int err;

	err = 0;
	switch (cmd) {
	case SUME_IOCTL_CMD_WRITE_REG:

		err = copy_from_user(&sifr, ifr->ifr_data, sizeof(sifr));
		if (err) {
			return err;
		}

		write_reg(adapter, BASE_ADDRESS_OFFSET, sifr.addr & BASE_ADDRESS_MASK);
		write_reg_bar2(adapter, sifr.addr & ~BASE_ADDRESS_MASK, sifr.val);

		if (verbose) {
			pr_info("req_addr=%x, paddr=%p, val=%x\n", sifr.addr, adapter->bar2 + (sifr.addr & AXI4LITE_MASK), sifr.val);
		}
		break;
	case SUME_IOCTL_CMD_READ_REG:

		err = copy_from_user(&sifr, ifr->ifr_data, sizeof(sifr));
		if (err) {
			return err;
		}
		write_reg(adapter, BASE_ADDRESS_OFFSET, sifr.addr & BASE_ADDRESS_MASK);
		sifr.val = read_reg_bar2(adapter, sifr.addr & ~BASE_ADDRESS_MASK);

		err = copy_to_user(ifr->ifr_data, &sifr, sizeof(sifr));
		if (err) {
			return err;
		}

		if (verbose) {
			pr_info("IOCTL read called\n");
			pr_info("req_addr=%x, paddr=%p, val=%x\n", sifr.addr, adapter->bar2 + (sifr.addr & AXI4LITE_MASK), sifr.val);
		}
		break;
	default:

		if (verbose) {
			pr_info("%s: unsupported ioctl 0x%08x\n", __func__, cmd);
		}
			err = -EOPNOTSUPP;
			break;
	}

	return err;
}


static const struct net_device_ops sume_uam_netdev_ops = {
	.ndo_open			= sume_uam_up,
	.ndo_stop			= sume_uam_down,
	.ndo_start_xmit		= sume_uam_start_xmit,
	.ndo_do_ioctl		= sume_uam_do_ioctl,
};

static int
sume_uam_irqs_init(struct pci_dev *pdev, struct sume_uam_adapter *adapter)
{
	int i;
	int err;

	for (i = 0; i < NUM_DMA_ENGINES; i++) {
		adapter->msix_entries[i].entry = i;
	}

	err = pci_enable_msix(pdev, adapter->msix_entries, NUM_DMA_ENGINES);
	if (err) {
		if (err > 0) {
			pci_disable_msix(pdev);
		}
		pr_err("Failed to allocate %d MSI-X vectors [%d]\n", NUM_DMA_ENGINES, err);

		return err;
	}

	pr_info("Allocated %d MSI-X vectors\n", NUM_DMA_ENGINES);

	return 0;
}

static int
sume_uam_irqs_fini(struct pci_dev *pdev, struct sume_uam_adapter *adapter)
{

	pci_disable_msix(pdev);

	return 0;
}

static void
sume_uam_free_netdevs(struct sume_uam_adapter *adapter)
{
	int i;
	for (i = 0; i < CONFIG_NR_PORTS; i++) {
		if (adapter->netdev[i]) {
			struct sume_uam_netdev_priv *priv;

			priv = netdev_priv(adapter->netdev[i]);

			unregister_netdev(adapter->netdev[i]);
			netif_napi_del(&priv->napi);
			free_netdev(adapter->netdev[i]);
			adapter->netdev[i] = NULL;
		}
	}
}

static void sume_uam_init_netdev(struct net_device *netdev)
{
       ether_setup(netdev);

}

static int
sume_uam_create_netdevs(struct pci_dev *pdev,
		        struct sume_uam_adapter *adapter)
{
	struct sume_uam_netdev_priv *priv;
	struct net_device *netdev;
	int i;
	int err;

	for (i = 0; i < CONFIG_NR_PORTS; i++) {
		netdev = alloc_netdev(sizeof(struct sume_uam_netdev_priv),
                                      "nf%d",  NET_NAME_UNKNOWN, sume_uam_init_netdev);
		if (netdev == NULL) {
			pr_err("Error: failed to alloc netdev #%d\n", i);
			err = -ENOMEM;
			goto out;
		}
		/* Link netdev to PCI device. */
		SET_NETDEV_DEV(netdev, &pdev->dev);

		/* Assign MAC address */
		memcpy(netdev->dev_addr, &sume_uam_default_dev_addr, ETH_ALEN);
		netdev->dev_addr[ETH_ALEN - 1] = i;

		/* Cross-link data structures. */
		priv = netdev_priv(netdev);
		priv->netdev = netdev;
		priv->adapter = adapter;

		priv->port_num = i;
		priv->tx_ntu = 0;
		priv->tx_ntc = 0;
		priv->rx_ntu = 0;
		priv->rx_ntc = 0;

		netdev->netdev_ops = &sume_uam_netdev_ops;
		sume_uam_set_ethtool_ops(netdev);

		/* to enable GSO, fake SG:
		 * although SG is not supported by our HW, it is good to
		 * enable GSO. (SGed tx packets are handled by copying to
		 * lbuf tx buffer).
		 * in old kernel versions, dependency is more tricky,
		 * SG and GRO rely on checksum offload, they are not
		 * allowed to be turned on */
		//netdev->features |= NETIF_F_SG;
#if LINUX_VERSION_CODE >= KERNEL_VERSION(2,6,39)
		netdev->hw_features |= netdev->features;
#endif
		err = register_netdev(netdev);
		if (err) {
			free_netdev(netdev);
			pr_err("failed to register netdev\n");
			goto out;
		}

		/* non-NULL netdev[i] if both allocated and registered */
		adapter->netdev[i] = netdev;

		netif_napi_add(netdev, &priv->napi, sume_uam_poll,
			       NAPI_POLL_WEIGHT);

		pr_info("Netdev #%d registered\n", i);
	}

	return 0;
out:
	sume_uam_free_netdevs(adapter);

	return err;
}


static int
sume_uam_probe(struct pci_dev *pdev, const struct pci_device_id *id)
{
	struct sume_uam_adapter *adapter;
	int err;
	int i;

	pr_info("Start probing\n");

	/* 1. PCI device init. */
	err = pci_enable_device(pdev);
	if (err) {
		return err;
	}

	err = pcie_set_mps(pdev, 128);
	if (err) {
		pr_err("nfp: Unable to adjust the PCIe payload!\n");
		goto err_dma;
	}

	err = pcie_set_readrq(pdev, 4096);
	if (err) {
		pr_err("nfp: Unable to adjust the PCIe read request!\n");
		goto err_dma;
	}

	if ((err = pci_set_dma_mask(pdev, DMA_BIT_MASK(64))) ||
	    (err = pci_set_consistent_dma_mask(pdev, DMA_BIT_MASK(64)))) {
		pr_err("Failed to set 64 bit DMA mask\n");
		goto err_dma;
	}

	err = pci_request_regions(pdev, SUME_UAM_DRV_NAME);
	if (err) {
		goto err_dma;
	}

	pci_set_master(pdev);

	/* 2. create adapter & netdev and cross-link data structures. */
	adapter = kzalloc(sizeof(struct sume_uam_adapter), GFP_KERNEL);
	if (adapter == NULL) {
		err = -ENOMEM;
		goto err_alloc_adapter;
	}
	pci_set_drvdata(pdev, adapter);
	adapter->pdev = pdev;

	err = sume_uam_create_netdevs(pdev, adapter);
	if (err) {
		goto err_create_netdevs;
	}

	/* This can be updated by 'ethtool -s <iface> msglvl <value>' */
	adapter->msg_enable = netif_msg_init(debug, DEFAULT_MSG_ENABLE);

	/* Map BAR0, BAR1 and BAR2 memory regions. */
	if ((adapter->bar0 = pci_iomap(pdev, 0, 0)) == NULL) {
		err = -EIO;
		goto err_pci_iomap_bar0;
	}

#ifdef USE_BAR1
	if ((adapter->bar1 = pci_iomap(pdev, 1, 0)) == NULL) {
		err = -EIO;
		goto err_pci_iomap_bar1;
	}
#endif

	if ((adapter->bar2 = pci_iomap(pdev, 2, 0)) == NULL) {
		err = -EIO;
		goto err_pci_iomap_bar2;
	}

	adapter->dma = adapter->bar0 + (DMA_OFFSET * 8);

	/* Reset the descriptors. */
	for (i = 0; i < NUM_DMA_ENGINES; i++) {
		memset(adapter->dma->dma_engine[i].dma_descriptor, 0,
		       sizeof(adapter->dma->dma_engine[i].dma_descriptor));
	}

	/* 3. Init interrupts. */
	err = sume_uam_irqs_init(pdev, adapter);
	if (err < 0) {
		pr_err("nfp: failed to initialize interfaces\n");
		goto err_enable_msix;
	}

	pr_info("Probe completed\n");

	//temporary for /proc int generation
	adapter_glob = adapter;

	return 0;

err_enable_msix:
	pci_iounmap(pdev, adapter->bar2);
err_pci_iomap_bar2:
#ifdef USE_BAR1
	pci_iounmap(pdev, adapter->bar1);
err_pci_iomap_bar1:
#endif
	pci_iounmap(pdev, adapter->bar0);
err_pci_iomap_bar0:
	sume_uam_free_netdevs(adapter);
err_create_netdevs:
	pci_set_drvdata(pdev, NULL);
	kfree(adapter);
err_alloc_adapter:
	pci_clear_master(pdev);
	pci_release_regions(pdev);
err_dma:
	pci_disable_device(pdev);

	return err;
}

static void
sume_uam_remove(struct pci_dev *pdev)
{
	struct sume_uam_adapter *adapter = pci_get_drvdata(pdev);

	pr_info("sume_uam removing\n");

	if (!adapter) {
		return;
	}

	sume_uam_free_netdevs(adapter);
	sume_uam_irqs_fini(pdev, adapter);
	pci_iounmap(pdev, adapter->bar2);
#ifdef USE_BAR1
	pci_iounmap(pdev, adapter->bar1);
#endif
	pci_iounmap(pdev, adapter->bar0);
	pci_set_drvdata(pdev, NULL);
	pci_clear_master(pdev);
	pci_release_regions(pdev);
	pci_disable_device(pdev);
	kfree(adapter);

	pr_info("sume_uam: remove is done successfully\n");
}

static struct pci_device_id sume_uam_pci_table[] = {
	{PCI_DEVICE(SUME_UAM_VENDOR_ID, SUME_UAM_DEVICE_ID)},
	{0}
};
MODULE_DEVICE_TABLE(pci, sume_uam_pci_table);

static struct pci_driver sume_uam_driver = {
	.name 			= SUME_UAM_DRV_NAME,
	.id_table 		= sume_uam_pci_table,
	.probe 			= sume_uam_probe,
	.remove 		= sume_uam_remove,
};

static int __init
sume_uam_drv_init(void)
{
	pr_info("Init SUME UAM\n");
	proc_create(SUME_UAM_DRV_NAME, 0, NULL, &mod_fops);
	return pci_register_driver(&sume_uam_driver);
}

static void __exit
sume_uam_drv_exit(void)
{
	pr_info("Exit SUME UAM\n");
	remove_proc_entry(SUME_UAM_DRV_NAME, NULL );
	pci_unregister_driver(&sume_uam_driver);
}

module_init(sume_uam_drv_init);
module_exit(sume_uam_drv_exit);

MODULE_LICENSE("Dual BSD/GPL");
MODULE_DESCRIPTION("Device driver for NetFPGA-SUME NIC");
