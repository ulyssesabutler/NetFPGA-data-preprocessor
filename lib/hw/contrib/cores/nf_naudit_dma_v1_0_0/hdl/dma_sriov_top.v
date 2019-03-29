//
// Copyright (c) 2015 University of Cambridge
// All rights reserved.
//
// This software was developed by
// Stanford University and the University of Cambridge Computer Laboratory
// under National Science Foundation under Grant No. CNS-0855268,
// the University of Cambridge Computer Laboratory under EPSRC INTERNET Project EP/H040536/1 and
// by the University of Cambridge Computer Laboratory under DARPA/AFRL contract FA8750-11-C-0249 ("MRC2"),
// as part of the DARPA MRC research programme.
//
// @NETFPGA_LICENSE_HEADER_START@
//
// Licensed to NetFPGA C.I.C. (NetFPGA) under one or more
// contributor license agreements.  See the NOTICE file distributed with this
// work for additional information regarding copyright ownership.  NetFPGA
// licenses this file to you under the NetFPGA Hardware-Software License,
// Version 1.0 (the "License"); you may not use this file except in compliance
// with the License.  You may obtain a copy of the License at:
//
//   http://www.netfpga-cic.org
//
// Unless required by applicable law or agreed to in writing, Work distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations under the License.
//
// @NETFPGA_LICENSE_HEADER_END@
//
//
/**
@class dma_sriov_top
@author      Jose Fernando Zazo Rollon (josefernando.zazo@naudit.es)
@date        20/04/2015
@brief Top level design containing  the PCIe DMA core and SR-IOV level abstractions
*/

`timescale  1ns/1ns
/*
NOTATION: some compromises have been adopted.
INPUTS/OUTPUTS   to the module are expressed in capital letters.
INPUTS CONSTANTS to the module are expressed in capital letters.
STATES of a FMS  are expressed in capital letters.
Other values are in lower letters.
A register will be written as name_of_register"_r" (except registers associated to states)
A signal will be written as   name_of_register"_s"
Every constante will be preceded by "c_"name_of_the_constant
*/

// We cant use $clog2 to initialize vectors to 0, so we define the discrete ceil of the log2
`define CLOG2(x) \
(x <= 2) ? 1 : \
(x <= 4) ? 2 : \
(x <= 8) ? 3 : \
(x <= 16) ? 4 : \
(x <= 32) ? 5 : \
(x <= 64) ? 6 : \
(x <= 128) ? 7 : \
(x <= 256) ? 8 : \
(x <= 512) ? 9 : \
(x <= 1024) ? 10 : \
(x <= 2048) ? 11 : 12

module dma_sriov_top #(
	parameter C_BUS_DATA_WIDTH         = 256     ,
	parameter                                           C_BUS_KEEP_WIDTH = (C_BUS_DATA_WIDTH/32),
	parameter                                           C_AXI_KEEP_WIDTH = (C_BUS_DATA_WIDTH/8),
	parameter C_ADDR_WIDTH             = 24      , //At least 10 (Offset 200)
	parameter C_DATA_WIDTH             = 64      ,
	parameter C_ENGINE_TABLE_OFFSET    = 32'h200 ,
	parameter C_OFFSET_BETWEEN_ENGINES = 16'h2000,
	parameter C_NUMBER_INTERFACES      = 1       , // By default 2 engines: 1 S2C, 1 C2S (1 bidirectional interface)
	parameter C_USE_VIRTUALIZATION     = 0       , // If false (0), the number of devices MUST be set to 1
	parameter C_NUMBER_DEVICES         = 1       ,
	parameter C_WINDOW_SIZE            = 4       , // Number of parallel memory read requests. Must be a value between 1 and 2**9-1
	parameter C_LOG2_MAX_PAYLOAD       = 8       , // 2**C_LOG2_MAX_PAYLOAD in bytes
	parameter C_LOG2_MAX_READ_REQUEST  = 12        // 2**C_LOG2_MAX_READ_REQUEST in bytes
) (
	input  wire                                                               CLK                         ,
	input  wire                                                               RST_N                       ,
	////////////
	//  PCIe Interface: 1 AXI-Stream (completer side). There is the need of snooping the TARGET FUNCTION field.
	////////////
	input  wire [                                       C_BUS_DATA_WIDTH-1:0] M_AXIS_CQ_TDATA             ,
	input  wire [                                                       84:0] M_AXIS_CQ_TUSER             ,
	input  wire                                                               M_AXIS_CQ_TLAST             ,
	input  wire [                                       C_BUS_KEEP_WIDTH-1:0] M_AXIS_CQ_TKEEP             ,
	input  wire                                                               M_AXIS_CQ_TVALID            ,
	input  wire                                                               M_AXIS_CQ_TREADY            ,
	////////////
	//  PCIe Interface: 2 AXI-Stream (requester side)
	////////////
	output wire [                                       C_BUS_DATA_WIDTH-1:0] M_AXIS_RQ_TDATA             ,
	output wire [                                                       59:0] M_AXIS_RQ_TUSER             ,
	output wire                                                               M_AXIS_RQ_TLAST             ,
	output wire [                                       C_BUS_KEEP_WIDTH-1:0] M_AXIS_RQ_TKEEP             ,
	output wire                                                               M_AXIS_RQ_TVALID            ,
	input  wire [                                                        3:0] M_AXIS_RQ_TREADY            ,
	input  wire [                                       C_BUS_DATA_WIDTH-1:0] S_AXIS_RC_TDATA             ,
	input  wire [                                                       74:0] S_AXIS_RC_TUSER             ,
	input  wire                                                               S_AXIS_RC_TLAST             ,
	input  wire [                                       C_BUS_KEEP_WIDTH-1:0] S_AXIS_RC_TKEEP             ,
	input  wire                                                               S_AXIS_RC_TVALID            ,
	output wire [                                                       21:0] S_AXIS_RC_TREADY            ,
	////////////
	//  User Interface: 2 AXI-Stream. Every engine will have associate a  C_BUS_DATA_WIDTH
	//  AXI-Stream in each direction.
	////////////
	output wire [                 (C_NUMBER_INTERFACES*C_NUMBER_DEVICES)-1:0] S2C_TVALID                  ,
	input  wire [                 (C_NUMBER_INTERFACES*C_NUMBER_DEVICES)-1:0] S2C_TREADY                  ,
	output wire [C_BUS_DATA_WIDTH*(C_NUMBER_INTERFACES)*C_NUMBER_DEVICES-1:0] S2C_TDATA                   ,
	output wire [                 (C_NUMBER_INTERFACES*C_NUMBER_DEVICES)-1:0] S2C_TLAST                   ,
	output wire [C_AXI_KEEP_WIDTH*(C_NUMBER_INTERFACES*C_NUMBER_DEVICES)-1:0] S2C_TKEEP                   ,
	output wire [                 (C_NUMBER_INTERFACES*C_NUMBER_DEVICES)-1:0] C2S_TREADY                  ,
	input  wire [C_BUS_DATA_WIDTH*(C_NUMBER_INTERFACES*C_NUMBER_DEVICES)-1:0] C2S_TDATA                   ,
	input  wire [                 (C_NUMBER_INTERFACES*C_NUMBER_DEVICES)-1:0] C2S_TLAST                   ,
	input  wire [                 (C_NUMBER_INTERFACES*C_NUMBER_DEVICES)-1:0] C2S_TVALID                  ,
	input  wire [C_AXI_KEEP_WIDTH*(C_NUMBER_INTERFACES*C_NUMBER_DEVICES)-1:0] C2S_TKEEP                   ,
	////////////
	//  Memory Interface: Master interface, transferences from the CPU.
	////////////
	input  wire                                                               S_MEM_IFACE_EN              ,
	input  wire [                                           C_ADDR_WIDTH-1:0] S_MEM_IFACE_ADDR            ,
	output wire [                                           C_DATA_WIDTH-1:0] S_MEM_IFACE_DOUT            ,
	input  wire [                                           C_DATA_WIDTH-1:0] S_MEM_IFACE_DIN             ,
	input  wire [                                         C_DATA_WIDTH/8-1:0] S_MEM_IFACE_WE              ,
	output wire                                                               S_MEM_IFACE_ACK             ,
	// MSI-x Interrupts
	input  wire [                                                        1:0] cfg_interrupt_msix_enable   ,
	input  wire [                                                        1:0] cfg_interrupt_msix_mask     ,
	input  wire [                                                        5:0] cfg_interrupt_msix_vf_enable,
	input  wire [                                                        5:0] cfg_interrupt_msix_vf_mask  ,
	output wire [                                                       31:0] cfg_interrupt_msix_data     ,
	output wire [                                                       63:0] cfg_interrupt_msix_address  ,
	output wire                                                               cfg_interrupt_msix_int      ,
	input  wire                                                               cfg_interrupt_msix_sent     ,
	input  wire                                                               cfg_interrupt_msix_fail
);


	wire [C_NUMBER_DEVICES-1:0] ack_msix_s     ;
	wire                        ack_dma_s      ;
	wire [C_NUMBER_DEVICES-1:0] ack_dma_sriov_s;
	reg                         valid_dout_r   ; // 0 msix - 1 dma

	genvar i;

	wire [C_BUS_DATA_WIDTH-1:0] m_axis_rq_tdata_sriov_s [C_NUMBER_DEVICES-1:0];
	wire [                59:0] m_axis_rq_tuser_sriov_s [C_NUMBER_DEVICES-1:0];
	wire [C_BUS_KEEP_WIDTH-1:0] m_axis_rq_tkeep_sriov_s [C_NUMBER_DEVICES-1:0];
	wire [C_NUMBER_DEVICES-1:0] m_axis_rq_tvalid_sriov_s                      ;
	wire [C_NUMBER_DEVICES-1:0] m_axis_rq_tlast_sriov_s                       ;
	reg  [C_NUMBER_DEVICES-1:0] m_axis_rq_tready_sriov_r                      ;

	reg  [C_NUMBER_DEVICES-1:0] is_rq_sop_r                                        ;
	reg                         is_rc_sop_r                                        ;
	wire [C_BUS_DATA_WIDTH-1:0] m_axis_rq_tdata_nid_s        [C_NUMBER_DEVICES-1:0];
	wire [C_BUS_DATA_WIDTH-1:0] s_axis_rc_tdata_sriov_s      [C_NUMBER_DEVICES-1:0];
	wire [C_NUMBER_DEVICES-1:0] s_axis_rc_tvalid_sriov_s                           ;
	reg  [C_NUMBER_DEVICES-1:0] s_axis_rc_tvalid_sriov_pipe_r                      ;

	wire [C_NUMBER_DEVICES-1:0] en_sriov_s                 ;
	reg  [C_NUMBER_DEVICES-1:0] ready_sriov_state          ;
	wire [C_NUMBER_DEVICES-1:0] operation_in_course_sriov_s;

	wire [ 7:0] rc_engine_tag_s    [C_NUMBER_DEVICES-1:0];
	wire [ 7:0] rq_engine_tag_s    [C_NUMBER_DEVICES-1:0];
	wire [15:0] cq_engine_id_s                           ;
	reg  [15:0] cq_engine_id_r                           ;

	wire [7:0] current_sriov_s;
	wire [7:0] current_irq_s  ;

	wire [63:0] dout_msix_s [C_NUMBER_DEVICES-1:0];
	wire [63:0] dout_dma_s                        ;
	wire [63:0] dout_sriov_s[C_NUMBER_DEVICES-1:0];


	assign S_MEM_IFACE_DOUT = valid_dout_r == 0 ? dout_msix_s[current_sriov_s] : dout_dma_s;
	assign S_MEM_IFACE_ACK  = valid_dout_r == 0 ?  ack_msix_s[current_sriov_s] : ack_dma_s;


	assign M_AXIS_RQ_TLAST  = m_axis_rq_tlast_sriov_s[current_sriov_s];
	assign M_AXIS_RQ_TDATA  = m_axis_rq_tdata_sriov_s[current_sriov_s];
	assign M_AXIS_RQ_TUSER  = m_axis_rq_tuser_sriov_s[current_sriov_s];
	assign M_AXIS_RQ_TKEEP  = m_axis_rq_tkeep_sriov_s[current_sriov_s];
	assign M_AXIS_RQ_TVALID = m_axis_rq_tvalid_sriov_s[current_sriov_s];

	always @(negedge RST_N or posedge CLK) begin
		if (!RST_N) begin
			valid_dout_r <= 1'b0;
		end else  begin
			if(S_MEM_IFACE_ADDR[15:0] >= C_ENGINE_TABLE_OFFSET) begin
				valid_dout_r <= 1'b1;  // Select the dout from the dma component
			end else begin
				valid_dout_r <= 1'b0;  // Else msix
			end
		end
	end

	wire [                31:0] cfg_interrupt_msix_data_sriov_s   [C_NUMBER_DEVICES-1:0];
	wire [                63:0] cfg_interrupt_msix_address_sriov_s[C_NUMBER_DEVICES-1:0];
	wire [C_NUMBER_DEVICES-1:0] cfg_interrupt_msix_int_sriov_s                          ;
	wire [                 1:0] irq                               [C_NUMBER_DEVICES-1:0];
	reg  [C_NUMBER_DEVICES-1:0] irq_pending_r                                           ;


	assign cfg_interrupt_msix_data    = cfg_interrupt_msix_data_sriov_s[current_irq_s];
	assign cfg_interrupt_msix_address = cfg_interrupt_msix_address_sriov_s[current_irq_s];
	assign cfg_interrupt_msix_int     = cfg_interrupt_msix_int_sriov_s[current_irq_s];

	function [7:0] bit2pos(input [C_NUMBER_DEVICES-1:0] oh);
		integer k;
		begin
			bit2pos = 0;
			for (k=0; k<C_NUMBER_DEVICES; k=k+1) begin
				if (oh[k]) bit2pos = k;
			end
		end
	endfunction
	integer j;

	assign current_sriov_s = bit2pos(m_axis_rq_tready_sriov_r);
	assign current_irq_s   = bit2pos(irq_pending_r);



	always @(negedge RST_N or posedge CLK) begin
		if (!RST_N) begin
			is_rc_sop_r <= 1'b1;
		end else  begin
			if(S_AXIS_RC_TLAST && S_AXIS_RC_TVALID) begin
				is_rc_sop_r <= 1'b1;  // Select the dout from the dma component
			end else if(S_AXIS_RC_TVALID) begin
				is_rc_sop_r <= 1'b0;  // Else msix
			end else begin
				is_rc_sop_r <= is_rc_sop_r;
			end
		end
	end

	always @(negedge RST_N or posedge CLK) begin
		if (!RST_N) begin
			cq_engine_id_r <= 0;
		end else  begin
			if(M_AXIS_CQ_TREADY && M_AXIS_CQ_TVALID) begin
				cq_engine_id_r <= cq_engine_id_s;
			end else begin
				cq_engine_id_r <= cq_engine_id_r;
			end
		end
	end
	assign ack_dma_s  = ack_dma_sriov_s[cq_engine_id_r[2:0]];
	assign dout_dma_s = dout_sriov_s[cq_engine_id_r[2:0]];

	assign cq_engine_id_s = M_AXIS_CQ_TDATA[119:104];



	// In order to present compatibility with SR-IOV, a mux between the differents
	// RQ interfaces has to be presented. The valid in the RC interface is also
	// controlled.
	generate for(i=0; i<C_NUMBER_DEVICES; i=i+1) begin

			//////
			// Correlate valid and the current id.
			assign rc_engine_tag_s[i] = S_AXIS_RC_TDATA[71:64];
			//  assign s_axis_rc_tdata_sriov_s[i]  = is_rc_sop_r ? {S_AXIS_RC_TDATA[255:72], {8-`CLOG2(C_WINDOW_SIZE){1'h0}}, S_AXIS_RC_TDATA[$clog2(C_WINDOW_SIZE)+64-1:64],S_AXIS_RC_TDATA[63:0]}
			//                                                  : S_AXIS_RC_TDATA; //Restore the tag

			assign s_axis_rc_tdata_sriov_s[i][255:72]  = S_AXIS_RC_TDATA[255:72];
			assign s_axis_rc_tdata_sriov_s[i][63:0]    = S_AXIS_RC_TDATA[63:0];
			assign s_axis_rc_tdata_sriov_s[i][71:64]  = is_rc_sop_r ?  {{('d8-`CLOG2(C_WINDOW_SIZE)){1'h0}}, S_AXIS_RC_TDATA[$clog2(C_WINDOW_SIZE)+64-1:64]}
				: S_AXIS_RC_TDATA[71:64]; //Restore the tag
			if( C_NUMBER_DEVICES <= 1 ) begin
				assign s_axis_rc_tvalid_sriov_s[i] = S_AXIS_RC_TVALID;
				assign en_sriov_s[i] = S_MEM_IFACE_EN;
				assign rq_engine_tag_s[i] = { {(8-`CLOG2(C_WINDOW_SIZE)){1'b0}}, m_axis_rq_tdata_nid_s[i][$clog2(C_WINDOW_SIZE)+96-1:96]};
			end else begin
				assign s_axis_rc_tvalid_sriov_s[i] = is_rc_sop_r ?
					S_AXIS_RC_TVALID && rc_engine_tag_s[i][$clog2(C_NUMBER_DEVICES)+$clog2(C_WINDOW_SIZE)-1:$clog2(C_WINDOW_SIZE)] == i
						: s_axis_rc_tvalid_sriov_pipe_r[i] & S_AXIS_RC_TVALID;
				assign en_sriov_s[i] = S_MEM_IFACE_EN && cq_engine_id_s[$clog2(C_NUMBER_DEVICES)-1:0] == i;
				assign rq_engine_tag_s[i] = { {(8-`CLOG2(C_NUMBER_DEVICES)-`CLOG2(C_WINDOW_SIZE)){1'b0}},
					i[$clog2(C_NUMBER_DEVICES)-1:0],
					m_axis_rq_tdata_nid_s[i][$clog2(C_WINDOW_SIZE)+96-1:96]
				};
				// Keep the valid RC signal. It has to be 'AND' with the current RC_TVALID.
				always @(negedge RST_N or posedge CLK) begin
					if (!RST_N) begin
						s_axis_rc_tvalid_sriov_pipe_r[i] <= 1'b0;
					end else  begin
						if(is_rc_sop_r && rc_engine_tag_s[i][$clog2(C_NUMBER_DEVICES)+$clog2(C_WINDOW_SIZE)-1:$clog2(C_WINDOW_SIZE)] == i) begin
							s_axis_rc_tvalid_sriov_pipe_r[i] <= 1'b1;
						end else if(is_rc_sop_r) begin
							s_axis_rc_tvalid_sriov_pipe_r[i] <= 1'b0;
						end else begin
							s_axis_rc_tvalid_sriov_pipe_r[i] <= s_axis_rc_tvalid_sriov_pipe_r[i];
						end
					end
				end
			end



			//////
			// Alter the ID in a rq
			// bus number (8 bits) - device number (5 bits) - function number (3 bits)
			always @(negedge RST_N or posedge CLK) begin
				if (!RST_N) begin
					is_rq_sop_r[i] <= 1'b1;
				end else  begin
					if(m_axis_rq_tlast_sriov_s[i] && m_axis_rq_tvalid_sriov_s[i] && m_axis_rq_tready_sriov_r[i] && M_AXIS_RQ_TREADY) begin
						is_rq_sop_r[i] <= 1'b1;  // Select the dout from the dma component
					end else if(m_axis_rq_tvalid_sriov_s[i]  && m_axis_rq_tready_sriov_r[i] && M_AXIS_RQ_TREADY) begin
						is_rq_sop_r[i] <= 1'b0;  // Else msix
					end else begin
						is_rq_sop_r[i] <= is_rq_sop_r[i];
					end
				end
			end


			// Use rq_engine_tag_s[i] value
			assign m_axis_rq_tdata_sriov_s[i] = is_rq_sop_r[i] ? {m_axis_rq_tdata_nid_s[i][255:104], rq_engine_tag_s[i],  m_axis_rq_tdata_nid_s[i][95:0]}
				: m_axis_rq_tdata_nid_s[i];

			// We have to choose one virtual device in the RQ interface. Check every engine until we find one that wants to transfer data.
			// First virtual device has more prioprity in this implementation.
			// Ensure ready is kept until the end of the transferred (performance issues with other strategy).
			always @(negedge RST_N or posedge CLK) begin
				if (!RST_N) begin
					m_axis_rq_tready_sriov_r[i] <= 1'b0;
					ready_sriov_state[i]        <= 1'b0;
				end else  begin
					case(ready_sriov_state[i])
						1'b0: begin
							m_axis_rq_tready_sriov_r[i] <= 1'b0;
							if(i==0) begin
								ready_sriov_state[i]  <= operation_in_course_sriov_s[0];
							end else begin
								ready_sriov_state[i]  <= operation_in_course_sriov_s[i-1:0] ? 1'b0 : 1'b1;
							end
						end
						1'b1: begin
							if(!operation_in_course_sriov_s[i]) begin
								m_axis_rq_tready_sriov_r[i] <= 1'b0;
								ready_sriov_state[i]        <= 1'b0;
							end else begin
								m_axis_rq_tready_sriov_r[i] <= 1'b1;
								ready_sriov_state[i]        <= 1'b1;
							end
						end
						default: begin
							m_axis_rq_tready_sriov_r[i] <= 1'b0;
							ready_sriov_state[i]        <= 1'b0;
						end
					endcase
				end
			end

			//////
			// Instantiate a dma_logic for every virtual device.
			dma_logic #(
				.C_ENGINE_TABLE_OFFSET   (C_ENGINE_TABLE_OFFSET   ),
				.C_ADDR_WIDTH            (16                      ),
				.C_DATA_WIDTH            (C_DATA_WIDTH            ),
				.C_OFFSET_BETWEEN_ENGINES(C_OFFSET_BETWEEN_ENGINES),
				.C_NUM_ENGINES           (2*C_NUMBER_INTERFACES   ), // One engine for each direction (C2S and S2C)
				.C_WINDOW_SIZE           (C_WINDOW_SIZE           ),
				.C_LOG2_MAX_PAYLOAD      (C_LOG2_MAX_PAYLOAD      ),
				.C_LOG2_MAX_READ_REQUEST (C_LOG2_MAX_READ_REQUEST )
			) dma_logic_i (
				.CLK                (CLK                                                                  ),
				.RST_N              (RST_N                                                                ),

				.M_AXIS_RQ_TDATA    (m_axis_rq_tdata_nid_s[i]                                             ),
				.M_AXIS_RQ_TUSER    (m_axis_rq_tuser_sriov_s[i]                                           ),
				.M_AXIS_RQ_TLAST    (m_axis_rq_tlast_sriov_s[i]                                           ),
				.M_AXIS_RQ_TKEEP    (m_axis_rq_tkeep_sriov_s[i]                                           ),
				.M_AXIS_RQ_TVALID   (m_axis_rq_tvalid_sriov_s[i]                                          ),
				.M_AXIS_RQ_TREADY   ({4{m_axis_rq_tready_sriov_r[i]&&M_AXIS_RQ_TREADY}}                   ),

				.S_AXIS_RC_TDATA    (s_axis_rc_tdata_sriov_s[i]                                           ),
				.S_AXIS_RC_TUSER    (S_AXIS_RC_TUSER                                                      ),
				.S_AXIS_RC_TLAST    (S_AXIS_RC_TLAST                                                      ),
				.S_AXIS_RC_TKEEP    (S_AXIS_RC_TKEEP                                                      ),
				.S_AXIS_RC_TVALID   (s_axis_rc_tvalid_sriov_s[i]                                          ),
				.S_AXIS_RC_TREADY   (S_AXIS_RC_TREADY                                                     ),


				.C2S_TVALID         (C2S_TVALID[C_NUMBER_INTERFACES*i +: C_NUMBER_INTERFACES]             ),
				.C2S_TREADY         (C2S_TREADY[C_NUMBER_INTERFACES*i +: C_NUMBER_INTERFACES]             ),
				.C2S_TDATA          (C2S_TDATA[C_BUS_DATA_WIDTH*i +: C_BUS_DATA_WIDTH*C_NUMBER_INTERFACES]),
				.C2S_TLAST          (C2S_TLAST[C_NUMBER_INTERFACES*i +: C_NUMBER_INTERFACES]              ),
				.C2S_TKEEP          (C2S_TKEEP[C_AXI_KEEP_WIDTH*i +: C_AXI_KEEP_WIDTH*C_NUMBER_INTERFACES]),

				.S2C_TVALID         (S2C_TVALID[C_NUMBER_INTERFACES*i +: C_NUMBER_INTERFACES]             ),
				.S2C_TREADY         (S2C_TREADY[C_NUMBER_INTERFACES*i +: C_NUMBER_INTERFACES]             ),
				.S2C_TDATA          (S2C_TDATA[C_BUS_DATA_WIDTH*i +: C_BUS_DATA_WIDTH*C_NUMBER_INTERFACES]),
				.S2C_TLAST          (S2C_TLAST[C_NUMBER_INTERFACES*i +: C_NUMBER_INTERFACES]              ),
				.S2C_TKEEP          (S2C_TKEEP[C_AXI_KEEP_WIDTH*i +: C_AXI_KEEP_WIDTH*C_NUMBER_INTERFACES]),

				.S_MEM_IFACE_EN     (en_sriov_s[i] && (S_MEM_IFACE_ADDR[15:0]>=C_ENGINE_TABLE_OFFSET)     ),
				.S_MEM_IFACE_ADDR   (S_MEM_IFACE_ADDR[15:0]                                               ),
				.S_MEM_IFACE_DOUT   (dout_sriov_s[i]                                                      ),
				.S_MEM_IFACE_DIN    (S_MEM_IFACE_DIN                                                      ),
				.S_MEM_IFACE_WE     (S_MEM_IFACE_WE                                                       ),
				.S_MEM_IFACE_ACK    (ack_dma_sriov_s[i]                                                   ),
				.IRQ                (irq[i]                                                               ),
				.OPERATION_IN_COURSE(operation_in_course_sriov_s[i]                                       )
			);



			msix_manager_br #(
				.C_MSIX_TABLE_OFFSET(32'h0  ),
				.C_MSIX_PBA_OFFSET  (32'h100), /* PBA = Pending bit array */
				.C_NUM_IRQ_INPUTS   (2      )
			) msix_manager_br_i (
				.clk                         (CLK                                                             ), // input   wire
				.rst_n                       (RST_N                                                           ), // input   wire

				.s_mem_iface_en              (S_MEM_IFACE_EN && (S_MEM_IFACE_ADDR[15:0]<C_ENGINE_TABLE_OFFSET)), // input  wire
				.s_mem_iface_addr            (S_MEM_IFACE_ADDR[8:0]                                           ), // input  wire   [8:0]
				.s_mem_iface_dout            (dout_msix_s[i]                                                  ), // output  wire   [63:0]
				.s_mem_iface_din             (S_MEM_IFACE_DIN                                                 ), // input wire   [63:0]
				.s_mem_iface_we              (S_MEM_IFACE_WE                                                  ), // input wire   [7:0]
				.s_mem_iface_ack             (ack_msix_s[i]                                                   ), // output  wire

				// MSI-X interrupts
				.cfg_interrupt_msix_enable   (cfg_interrupt_msix_enable                                       ), // input  wire [1:0]
				.cfg_interrupt_msix_mask     (cfg_interrupt_msix_mask                                         ), // input  wire [1:0]
				.cfg_interrupt_msix_vf_enable(cfg_interrupt_msix_vf_enable                                    ), // input  wire [5:0]
				.cfg_interrupt_msix_vf_mask  (cfg_interrupt_msix_vf_mask                                      ), // input  wire [5:0]
				.cfg_interrupt_msix_data     (cfg_interrupt_msix_data_sriov_s[i]                              ), // output reg  [31:0]
				.cfg_interrupt_msix_address  (cfg_interrupt_msix_address_sriov_s[i]                           ), // output wire [63:0]
				.cfg_interrupt_msix_int      (cfg_interrupt_msix_int_sriov_s[i]                               ), // output reg
				.cfg_interrupt_msix_sent     (cfg_interrupt_msix_sent                                         ), // input  wire
				.cfg_interrupt_msix_fail     (cfg_interrupt_msix_fail                                         ), // input  wire

				.irq                         (irq[i]                                                          )  // input  wire [C_NUM_IRQ_INPUTS-1:0]           // TODO implement
			);



			always @(negedge RST_N or posedge CLK) begin
				if (!RST_N) begin
					irq_pending_r[i] <= 1'b0;
				end else  begin
					if(irq[i][0] || irq[i][1]) begin
						irq_pending_r[i] <= 1'b1;
					end else if(cfg_interrupt_msix_int_sriov_s[i]) begin
						irq_pending_r[i] <= 1'b0;
					end else begin
						irq_pending_r[i] <= irq_pending_r[i];
					end
				end
			end

		end
	endgenerate

endmodule
