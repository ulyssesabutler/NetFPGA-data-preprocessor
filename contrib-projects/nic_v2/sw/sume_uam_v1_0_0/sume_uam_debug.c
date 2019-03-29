/*
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
 *
 */

#include "sume_uam.h"

void
dump_engine(int engine, struct dma_core *dma)
{
	pr_info("dma->dma_engine[%d].enable 0x%x\n", engine, dma->dma_engine[engine].enable);
	pr_info("dma->dma_engine[%d].reset 0x%x\n",  engine, dma->dma_engine[engine].reset);
	pr_info("dma->dma_engine[%d].u0 0x%llx\n", engine, (u64)dma->dma_engine[engine].u0);
	pr_info("dma->dma_engine[%d].tail 0x%x\n",  engine, dma->dma_engine[engine].tail);
	pr_info("dma->dma_engine[%d].head 0x%x\n",  engine, dma->dma_engine[engine].head);
	pr_info("dma->dma_engine[%d].u1 0x%llx\n", engine, (u64)dma->dma_engine[engine].u1);
	pr_info("dma->dma_engine[%d].total_time 0x%llx\n", engine, dma->dma_engine[engine].total_time);
	pr_info("dma->dma_engine[%d].total_bytes 0x%llx\n", engine, dma->dma_engine[engine].total_bytes);
}

void
dump_common_block(struct dma_core *dma)
{
	pr_info("dma->dma_common_block.max_payload 0x%x\n", dma->dma_common_block.max_payload);
	pr_info("dma->dma_common_block.max_read_request 0x%x\n", dma->dma_common_block.max_read_request);
	pr_info("dma->dma_common_block.irq_enable 0x%x\n", dma->dma_common_block.irq_enable);
	pr_info("dma->dma_common_block.user_reset 0x%x\n", dma->dma_common_block.user_reset);
	pr_info("dma->dma_common_block.engine_finished 0x%x\n", dma->dma_common_block.engine_finished);
	pr_info("dma->dma_common_block.u0 0x%x\n", dma->dma_common_block.u0);
}

void
dump_descriptor(int engine, int descriptor, struct dma_core *dma)
{
	pr_info("dma->dma_engine[%d].dma_descriptor[%d].size %llx\n", engine, descriptor, dma->dma_engine[engine].dma_descriptor[descriptor].size);
	pr_info("dma->dma_engine[%d].dma_descriptor[%d].address %llx\n", engine, descriptor, dma->dma_engine[engine].dma_descriptor[descriptor].address);
	pr_info("dma->dma_engine[%d].dma_descriptor[%d].generate_irq %x\n", engine, descriptor, dma->dma_engine[engine].dma_descriptor[descriptor].generate_irq);
	pr_info("dma->dma_engine[%d].dma_descriptor[%d].u1 %llx\n", engine, descriptor, dma->dma_engine[engine].dma_descriptor[descriptor].u1);
}

void
dump_common_block_mem(struct sume_uam_adapter *adapter)
{
	int i;

	pr_info("dma_common_block");
	for (i=(DMA_OFFSET+NUM_DMA_ENGINES*OFFSET_BETWEEN_ENGINES)*8; i <(DMA_OFFSET+NUM_DMA_ENGINES*OFFSET_BETWEEN_ENGINES+1)*8; i+=8){
		pr_info("%llx %08x %08x\n", (u64)adapter->bar0+i, read_reg(adapter, i+4), read_reg(adapter, i));
	}
}

void
dump_engine_mem(int engine, struct sume_uam_adapter *adapter)
{
	int i;

	pr_info("dma_engine[%d]", engine);
	for (i=(DMA_OFFSET+OFFSET_BETWEEN_ENGINES*engine)*8; i <(DMA_OFFSET+OFFSET_BETWEEN_ENGINES*engine+4)*8; i+=8){
		pr_info("%llx %08x %08x\n", (u64)adapter->bar0+i, read_reg(adapter, i+4), read_reg(adapter, i));
	}
}

void
dump_descriptor_mem(int engine, int descriptor, struct sume_uam_adapter *adapter)
{
	int i;
	int desc_offset = 4;
	int desc_size = sizeof(struct dma_descriptor)/8;
	int offset = 0;

	offset = desc_offset + desc_size*descriptor;

	pr_info("dma_engine[%d] desc[%d]", engine, descriptor);
	for (i=(DMA_OFFSET+OFFSET_BETWEEN_ENGINES*engine+offset)*8; i <(DMA_OFFSET+OFFSET_BETWEEN_ENGINES*engine+offset+sizeof(struct dma_descriptor)/8)*8; i+=8){
		pr_info("%llx %08x %08x\n", (u64)adapter->bar0+i, read_reg(adapter, i+4), read_reg(adapter, i));
	}
}
