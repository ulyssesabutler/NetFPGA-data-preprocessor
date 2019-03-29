/*
 * Copyright (c) 2016 José Fernando Zazo Rollón
 * Copyright (c) 2016 Vincenzo Maffione
 * Copyright (c) 2016 Marcin Wójcik
 * All rights reserved.
 *
 * This software was developed by
 * Stanford University and the University of Cambridge Computer Laboratory
 * under National Science Foundation under Grant No. CNS-0855268,
 * the University of Cambridge Computer Laboratory under EPSRC INTERNET Project EP/H040536/1 and
 * by the University of Cambridge Computer Laboratory under DARPA/AFRL contract FA8750-11-C-0249 ("MRC2"),
 * as part of the DARPA MRC research programme and under the SSICLOPS (grant
 * agreement No. 644866) project as part of the European Union’s Horizon 2020
 * research and innovation programme 2014-2018.
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

#ifndef _SUME_UAM_H
#define _SUME_UAM_H

#include <linux/version.h>
#include <linux/netdevice.h>
#include <linux/types.h>
#include <linux/ethtool.h>
#include <linux/pci.h>
#include <linux/cdev.h>


#ifdef CONFIG_NR_PORTS
#warning "Only one network interface will be created"
#undef CONFIG_NR_PORTS
#define CONFIG_NR_PORTS   1
#endif

#define SUME_UAM_VENDOR_ID  0x10EE //PCI_VENDOR_ID_XILINX //0x10EE
#define SUME_UAM_DEVICE_ID  0x7038

#define get_netdev_priv(netdev) ((struct sume_uam_netdev_priv *)netdev_priv(netdev))
#define netdev_adapter(netdev)  (get_netdev_priv(netdev)->adapter)
#define netdev_port_num(netdev)  (get_netdev_priv(netdev)->port_num)

/* Maximum number of DMA engines in the DEVICE:
 *   0 -> Card2System (C2S)
 *   1 -> System2Card (S2C)
 */
#define NUM_DMA_ENGINES   2
#define DMA_ENG_RX    0
#define DMA_ENG_TX    1

#define NUM_DESCRIPTORS 1024

/* Offset in 64bit words between engines in the HDL design. */
#define OFFSET_BETWEEN_ENGINES  0x2000

/* Initial offset in the BAR0 to the DMA registers.
 *  At DMA_OFFSET                          dma_engine[0]
 *  At DMA_OFFSET+OFFSET_BETWEEN_ENGINES   dma_engine[1]
 *               ...
 *               ...
 *               ...
 *  At DMA_OFFSET+i*OFFSET_BETWEEN_ENGINES dma_engine[i]
 *  At DMA_OFFSET+NUM_DMA_ENGINES*OFFSET_BETWEEN_ENGINES:  dma_common_block
*/
#define DMA_OFFSET              0x200
#define BASE_ADDRESS_OFFSET              0x1FF
#define BASE_ADDRESS ((BASE_ADDRESS_OFFSET)*8)

#define RING_NEXT_IDX(_idx) \
  ((_idx) + 1 == NUM_DESCRIPTORS ? 0 : (_idx) + 1)

#define RING_PREV_IDX(_idx) \
    ((_idx) == 0 ? NUM_DESCRIPTORS - 1 : (_idx) - 1)

#define TAIL_RX_OFFSET ((DMA_OFFSET+OFFSET_BETWEEN_ENGINES*DMA_ENG_RX)*8+8)
#define TAIL_TX_OFFSET ((DMA_OFFSET+OFFSET_BETWEEN_ENGINES*DMA_ENG_TX)*8+8)

#define AXI4LITE_MASK 0x000FFFFF
#define BASE_ADDRESS_MASK ~AXI4LITE_MASK

struct dma_descriptor {
  u64  address;
  u64  size;
  u64  generate_irq : 1;
  u64  u0           : 63;
  u64  u1;
} __attribute__ ((__packed__));

struct dma_engine {
  /* Enable bit, used tell the hardware that descriptors are ready. */
  u64  enable : 1;
  /* Reset the state machines for this engine. */
  u64  reset  : 1;
  u64  irq_enable: 1;
  u64  u0     : 61;
  /* Next descriptor to be prepared by software.
   * Written by software, read by hardware. */
  u64  tail : 10;
  u64  u1 : 6;
  /* Next descriptor to be processed by hardware.
   * Written by hardware, read by software. */
  u64  head : 10;
  u64  u2 : 38;
  /* On read: time that was consumed during the previous operation.
   * On write: Maximum timeout for a C2S operation. */
  u64  total_time;
  u64  total_bytes; /* Read only. */
  struct dma_descriptor  dma_descriptor[NUM_DESCRIPTORS];
  u64 u4[OFFSET_BETWEEN_ENGINES - 4 -
         NUM_DESCRIPTORS * sizeof(struct dma_descriptor) / 8];
} __attribute__ ((__packed__));

struct dma_common_block {
  /* The maximum payload size being used by the DMA core.
   * This size may be different than the system-programmed Max Payload
         * The size is expressed as: 2^{max_payload} * 128 bytes. Common examples:
         *           · 000 = 128  Bytes
         *           · 001 = 256  Bytes
         *           · 010 = 512  Bytes
         *           · 011 = 1024 Bytes
         *           · 100 = 2048 Bytes
         *           · 101 = 4096 Bytes
   */
  uint64_t max_payload : 3;
  /* The read request size being used by the DMA core.
         * This size may be different than the system-programmed Max Read Request
         * The size is expressed as: 2^{max_payload} * 128 bytes. Common examples:
         *           · 000 = 128  Bytes
         *           · 001 = 256  Bytes
         *           · 010 = 512  Bytes
         *           · 011 = 1024 Bytes
         *           · 100 = 2048 Bytes
         *           · 101 = 4096 Bytes
   */
  uint64_t max_read_request : 3;
  /* Global DMA Interrupt Enable, to globally enable/disable
   * interrupts. */
  uint64_t irq_enable  : 1;
  uint64_t user_reset  : 1;
  /* Bitmask of engines that have completed the operation, useful for
   * polling. */
  uint64_t engine_finished : 16;
  uint64_t u0 : 32;
} __attribute__ ((__packed__));

struct dma_core {
  struct dma_engine       dma_engine[NUM_DMA_ENGINES];
  struct dma_common_block dma_common_block;
} __attribute__ ((__packed__));

//#define USE_BAR1

struct sume_uam_adapter {
  struct pci_dev *pdev;
  struct net_device *netdev[CONFIG_NR_PORTS];

  void __iomem *bar0;
#ifdef USE_BAR1
  void __iomem *bar1;
#endif
  void __iomem *bar2;

  u16 msg_enable;

  /* MSI-X nterrupt support. */
  struct msix_entry msix_entries[NUM_DMA_ENGINES];

  struct dma_core *dma;
};

struct desc_info {
  uint64_t paddr;
  uint64_t len;
  void *buf;
};

struct sume_uam_netdev_priv {
  struct sume_uam_adapter *adapter;
  struct net_device *netdev;
  int port_num;

  unsigned int tx_ntu;
  unsigned int tx_ntc;

  unsigned int rx_ntu;
  unsigned int rx_ntc;

  struct desc_info tx_desc_info[NUM_DESCRIPTORS];
  struct desc_info rx_desc_info[NUM_DESCRIPTORS];

  struct napi_struct napi;
};

extern void sume_uam_set_ethtool_ops(struct net_device *netdev);

static inline unsigned int
read_reg(struct sume_uam_adapter *adapter, int offset)
{
  return (readl(adapter->bar0 + offset ));
}

static inline unsigned int
read_reg_bar2(struct sume_uam_adapter *adapter, int offset)
{
  return (readl(adapter->bar2 + offset ));
}

static inline void
write_reg(struct sume_uam_adapter *adapter, int offset, unsigned int val)
{
  writel(val, adapter->bar0 + offset);
}

static inline void
write_reg_bar2(struct sume_uam_adapter *adapter, int offset, unsigned int val)
{
  writel(val, adapter->bar2 + offset);
}

/* Debug functions */
void dump_engine(int engine, struct dma_core *dma);
void dump_common_block(struct dma_core *dma);
void dump_descriptor(int engine, int descriptor, struct dma_core *dma);
void dump_common_block_mem(struct sume_uam_adapter *adapter);
void dump_engine_mem(int engine, struct sume_uam_adapter *adapter);
void dump_descriptor_mem(int engine, int descriptor, struct sume_uam_adapter *adapter);

#if defined(__linux__)
#define SUME_IOCTL_CMD_WRITE_REG        (SIOCDEVPRIVATE+1)
#define SUME_IOCTL_CMD_READ_REG         (SIOCDEVPRIVATE+2)
#elif defined(__FreeBSD__)
#define SUME_IOCTL_CMD_WRITE_REG        (SIOCGPRIVATE_0)
#define SUME_IOCTL_CMD_READ_REG         (SIOCGPRIVATE_1)
#else
#error NetFPGA SUME ioctls not supported on this OS
#endif

struct sume_ifreq {
        uint32_t        addr;
        uint32_t        val;
};

#endif
