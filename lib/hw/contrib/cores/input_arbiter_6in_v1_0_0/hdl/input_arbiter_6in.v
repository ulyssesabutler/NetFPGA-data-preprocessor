//-
// Copyright (C) 2010, 2011 The Board of Trustees of The Leland Stanford
//                          Junior University
// Copyright (C) 2010, 2011 Adam Covington
// Copyright (C) 2015 Noa Zilberman
// Copyright (C) 2018 Pietro Bressana
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
// Licensed to NetFPGA C.I.C. (NetFPGA) under one or more contributor
// license agreements.  See the NOTICE file distributed with this work for
// additional information regarding copyright ownership.  NetFPGA licenses this
// file to you under the NetFPGA Hardware-Software License, Version 1.0 (the
// "License"); you may not use this file except in compliance with the
// License.  You may obtain a copy of the License at:
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
/*******************************************************************************
 *  File:
 *        input_arbiter_6in.v
 *
 *  Library:
 *        hw/contrib/cores/input_arbiter_6in
 *
 *  Module:
 *        input_arbiter_6in
 *
 *  Author:
 *        Adam Covington
 *        Modified by Noa Zilberman
 *        Modified by Pietro Bressana
 *
 *  Description:
 *        Round Robin arbiter (N inputs to 1 output)
 *        One high-priority interface, that sustains 50G traffic
 *        Inputs have a parameterizable width
 *
 */

`include "input_arbiter_6in_cpu_regs_defines.v"

module input_arbiter_6in
#(
    // Master AXI Stream Data Width
    parameter C_M_AXIS_DATA_WIDTH=256,
    parameter C_S_AXIS_DATA_WIDTH=256,
    parameter C_M_AXIS_TUSER_WIDTH=256,
    parameter C_S_AXIS_TUSER_WIDTH=128,
    parameter C_S_AXIS6_TUSER_WIDTH=256,
    parameter NUM_QUEUES=6,

    // AXI Registers Data Width
    parameter C_S_AXI_DATA_WIDTH    = 32,
    parameter C_S_AXI_ADDR_WIDTH    = 12,
    parameter C_BASEADDR            = 32'h00000000

)
(
    // Part 1: System side signals
    // Global Ports
    input axis_aclk,
    input axis_resetn,

    // Master Stream Ports (interface to data path)
    output reg [C_M_AXIS_DATA_WIDTH - 1:0] m_axis_tdata,
    output reg [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] m_axis_tkeep,
    output reg [C_M_AXIS_TUSER_WIDTH-1:0] m_axis_tuser,
    output reg m_axis_tvalid,
    input  m_axis_tready,
    output reg m_axis_tlast,

    // Slave Stream Ports (interface to RX queues)
    input [C_S_AXIS_DATA_WIDTH - 1:0] s_axis_0_tdata,
    input [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0] s_axis_0_tkeep,
    input [C_S_AXIS_TUSER_WIDTH-1:0] s_axis_0_tuser,
    input  s_axis_0_tvalid,
    output s_axis_0_tready,
    input  s_axis_0_tlast,

    input [C_S_AXIS_DATA_WIDTH - 1:0] s_axis_1_tdata,
    input [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0] s_axis_1_tkeep,
    input [C_S_AXIS_TUSER_WIDTH-1:0] s_axis_1_tuser,
    input  s_axis_1_tvalid,
    output s_axis_1_tready,
    input  s_axis_1_tlast,

    input [C_S_AXIS_DATA_WIDTH - 1:0] s_axis_2_tdata,
    input [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0] s_axis_2_tkeep,
    input [C_S_AXIS_TUSER_WIDTH-1:0] s_axis_2_tuser,
    input  s_axis_2_tvalid,
    output s_axis_2_tready,
    input  s_axis_2_tlast,

    input [C_S_AXIS_DATA_WIDTH - 1:0] s_axis_3_tdata,
    input [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0] s_axis_3_tkeep,
    input [C_S_AXIS_TUSER_WIDTH-1:0] s_axis_3_tuser,
    input  s_axis_3_tvalid,
    output s_axis_3_tready,
    input  s_axis_3_tlast,

    input [C_S_AXIS_DATA_WIDTH - 1:0] s_axis_4_tdata,
    input [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0] s_axis_4_tkeep,
    input [C_S_AXIS_TUSER_WIDTH-1:0] s_axis_4_tuser,
    input  s_axis_4_tvalid,
    output s_axis_4_tready,
    input  s_axis_4_tlast,

    // 50G CHANNEL
    input [C_S_AXIS_DATA_WIDTH - 1:0] s_axis_5_tdata,
    input [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0] s_axis_5_tkeep,
    input [C_S_AXIS6_TUSER_WIDTH-1:0] s_axis_5_tuser,
    input  s_axis_5_tvalid,
    output s_axis_5_tready,
    input  s_axis_5_tlast,

    // Slave AXI Ports
    input                                     S_AXI_ACLK,
    input                                     S_AXI_ARESETN,
    input      [C_S_AXI_ADDR_WIDTH-1 : 0]     S_AXI_AWADDR,
    input                                     S_AXI_AWVALID,
    input      [C_S_AXI_DATA_WIDTH-1 : 0]     S_AXI_WDATA,
    input      [C_S_AXI_DATA_WIDTH/8-1 : 0]   S_AXI_WSTRB,
    input                                     S_AXI_WVALID,
    input                                     S_AXI_BREADY,
    input      [C_S_AXI_ADDR_WIDTH-1 : 0]     S_AXI_ARADDR,
    input                                     S_AXI_ARVALID,
    input                                     S_AXI_RREADY,
    output                                    S_AXI_ARREADY,
    output     [C_S_AXI_DATA_WIDTH-1 : 0]     S_AXI_RDATA,
    output     [1 : 0]                        S_AXI_RRESP,
    output                                    S_AXI_RVALID,
    output                                    S_AXI_WREADY,
    output     [1 :0]                         S_AXI_BRESP,
    output                                    S_AXI_BVALID,
    output                                    S_AXI_AWREADY,


   // stats
    output reg pkt_fwd

);

   function integer log2;
      input integer number;
      begin
         log2=0;
         while(2**log2<number) begin
            log2=log2+1;
         end
      end
   endfunction // log2

   // ------------ Internal Params --------

   localparam  NUM_QUEUES_WIDTH = log2(NUM_QUEUES);


   localparam NUM_STATES = 4;
   localparam IDLE = 0;
   localparam CHK = 1;
   localparam WR_PKT_50G = 2;
   localparam WR_PKT_QUE = 3;

   localparam MAX_PKT_SIZE = 2000; // In bytes
   localparam IN_FIFO_DEPTH_BIT = log2(MAX_PKT_SIZE/(C_M_AXIS_DATA_WIDTH / 8));

   // ------------- Regs/ wires -----------

   wire [NUM_QUEUES-1:0]               nearly_full;
   wire [NUM_QUEUES-1:0]               empty;
   wire [C_M_AXIS_DATA_WIDTH-1:0]        in_tdata      [NUM_QUEUES-1:0];
   wire [((C_M_AXIS_DATA_WIDTH/8))-1:0]  in_tkeep      [NUM_QUEUES-1:0];
   wire [C_M_AXIS_TUSER_WIDTH-1:0]             in_tuser      [NUM_QUEUES-1:0];
   wire [NUM_QUEUES-1:0]         in_tvalid;
   wire [NUM_QUEUES-1:0]               in_tlast;
   wire [C_M_AXIS_TUSER_WIDTH-1:0]             fifo_out_tuser[NUM_QUEUES-1:0];
   wire [C_M_AXIS_DATA_WIDTH-1:0]        fifo_out_tdata[NUM_QUEUES-1:0];
   wire [((C_M_AXIS_DATA_WIDTH/8))-1:0]  fifo_out_tkeep[NUM_QUEUES-1:0];
   wire [NUM_QUEUES-1:0]         fifo_out_tlast;
   wire                                fifo_tvalid;
   wire                                fifo_tlast;

   reg [NUM_QUEUES-1:0]                rd_en;

   reg [NUM_QUEUES_WIDTH-1:0]         cur_queue_plus1;

   reg [NUM_QUEUES_WIDTH-1:0]          cur_queue;
   reg [NUM_QUEUES_WIDTH-1:0]          cur_queue_next;

   reg [NUM_STATES-1:0]                state;

   reg                                 flag;

   //////////////////////////////////////////////////////

   // DEBUG:

   (* mark_debug = "true" *) wire [C_M_AXIS_DATA_WIDTH - 1:0] f_dbg_tdata0;
   (* mark_debug = "true" *) wire [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] f_dbg_tkeep0;
   (* mark_debug = "true" *) wire [C_M_AXIS_TUSER_WIDTH-1:0] f_dbg_tuser0;
   (* mark_debug = "true" *) wire f_dbg_tlast0;
   (* mark_debug = "true" *) wire f_dbg_empty0;
   assign f_dbg_tdata0 = fifo_out_tdata[0];
   assign f_dbg_tkeep0 = fifo_out_tkeep[0];
   assign f_dbg_tuser0 = fifo_out_tuser[0];
   assign f_dbg_tlast0 = fifo_out_tlast[0];
   assign f_dbg_empty0 = empty[0];

   (* mark_debug = "true" *) wire [NUM_QUEUES_WIDTH-1:0]  f_dbg_cur_queue;
   assign f_dbg_cur_queue = cur_queue;

   (* mark_debug = "true" *) wire [NUM_STATES-1:0]  f_dbg_state;
   assign f_dbg_state = state;

   //////////////////////////////////////////////////////

   reg               pkt_fwd_next;

   reg      [`REG_ID_BITS]    id_reg;
   reg      [`REG_VERSION_BITS]    version_reg;
   wire     [`REG_RESET_BITS]    reset_reg;
   reg      [`REG_FLIP_BITS]    ip2cpu_flip_reg;
   wire     [`REG_FLIP_BITS]    cpu2ip_flip_reg;
   reg      [`REG_PKTIN_BITS]    pktin_reg;
   wire                             pktin_reg_clear;
   reg      [`REG_PKTOUT_BITS]    pktout_reg;
   wire                             pktout_reg_clear;
   reg      [`REG_DEBUG_BITS]    ip2cpu_debug_reg;
   wire     [`REG_DEBUG_BITS]    cpu2ip_debug_reg;

   wire clear_counters;
   wire reset_registers;

   // ------------ Modules -------------

   generate
   genvar i;
   for(i=0; i<NUM_QUEUES; i=i+1) begin: in_arb_queues
     fallthrough_small_fifo
        #( .WIDTH(C_M_AXIS_DATA_WIDTH+C_M_AXIS_TUSER_WIDTH+C_M_AXIS_DATA_WIDTH/8+1),
           .MAX_DEPTH_BITS(IN_FIFO_DEPTH_BIT))
      in_arb_fifo
        (// Outputs
         .dout                           ({fifo_out_tlast[i], fifo_out_tuser[i], fifo_out_tkeep[i], fifo_out_tdata[i]}),
         .full                           (),
         .nearly_full                    (nearly_full[i]),
   .prog_full                      (),
         .empty                          (empty[i]),
         // Inputs
         .din                            ({in_tlast[i], in_tuser[i], in_tkeep[i], in_tdata[i]}),
         .wr_en                          (in_tvalid[i] & ~nearly_full[i]),
         .rd_en                          (rd_en[i]),
         .reset                          (~axis_resetn),
         .clk                            (axis_aclk));
   end
   endgenerate

   // ------------- Logic ------------

   assign in_tdata[0]        = s_axis_0_tdata;
   assign in_tkeep[0]        = s_axis_0_tkeep;
   assign in_tuser[0]        = s_axis_0_tuser;
   assign in_tvalid[0]       = s_axis_0_tvalid;
   assign in_tlast[0]        = s_axis_0_tlast;
   assign s_axis_0_tready    = !nearly_full[0];

   assign in_tdata[1]        = s_axis_1_tdata;
   assign in_tkeep[1]        = s_axis_1_tkeep;
   assign in_tuser[1]        = s_axis_1_tuser;
   assign in_tvalid[1]       = s_axis_1_tvalid;
   assign in_tlast[1]        = s_axis_1_tlast;
   assign s_axis_1_tready    = !nearly_full[1];

   assign in_tdata[2]        = s_axis_2_tdata;
   assign in_tkeep[2]        = s_axis_2_tkeep;
   assign in_tuser[2]        = s_axis_2_tuser;
   assign in_tvalid[2]       = s_axis_2_tvalid;
   assign in_tlast[2]        = s_axis_2_tlast;
   assign s_axis_2_tready    = !nearly_full[2];

   assign in_tdata[3]        = s_axis_3_tdata;
   assign in_tkeep[3]        = s_axis_3_tkeep;
   assign in_tuser[3]        = s_axis_3_tuser;
   assign in_tvalid[3]       = s_axis_3_tvalid;
   assign in_tlast[3]        = s_axis_3_tlast;
   assign s_axis_3_tready    = !nearly_full[3];

   assign in_tdata[4]        = s_axis_4_tdata;
   assign in_tkeep[4]        = s_axis_4_tkeep;
   assign in_tuser[4]        = s_axis_4_tuser;
   assign in_tvalid[4]       = s_axis_4_tvalid;
   assign in_tlast[4]        = s_axis_4_tlast;
   assign s_axis_4_tready    = !nearly_full[4];

   // 50G CHANNEL
   assign in_tdata[5]        = s_axis_5_tdata;
   assign in_tkeep[5]        = s_axis_5_tkeep;
   assign in_tuser[5]        = s_axis_5_tuser;
   assign in_tvalid[5]       = s_axis_5_tvalid;
   assign in_tlast[5]        = s_axis_5_tlast;
   assign s_axis_5_tready    = !nearly_full[5];

   always @(posedge axis_aclk) begin

      if(~axis_resetn) begin

        rd_en <= 0;
        pkt_fwd <= 0;
        m_axis_tuser <= 0;
        m_axis_tdata <= 0;
        m_axis_tlast <= 0;
        m_axis_tkeep <= 0;
        m_axis_tvalid <= 0;
        cur_queue <= 0;
        flag <= 0;
        state <= CHK;

      end // if

      else begin

            case(state)

              CHK: begin

                 if(!empty[5]) begin

                    if(m_axis_tready) begin
                       rd_en <= 6'b100000;
                       pkt_fwd <= 1;
                       m_axis_tuser <= 0;
                       m_axis_tdata <= 0;
                       m_axis_tlast <= 0;
                       m_axis_tkeep <= 0;
                       m_axis_tvalid <= 0;
                       flag <= 0;
                       state <= WR_PKT_50G;
                    end

                 end

                 else if(!empty[cur_queue]) begin

                    if(m_axis_tready) begin
                       rd_en <= {1'b0, (5'b00001 << cur_queue)};
                       pkt_fwd <= 1;
                       m_axis_tuser <= (fifo_out_tuser[cur_queue]) << 128;
                       m_axis_tdata <= fifo_out_tdata[cur_queue];
                       m_axis_tlast <= fifo_out_tlast[cur_queue];
                       m_axis_tkeep <= fifo_out_tkeep[cur_queue];
                       m_axis_tvalid <= ~empty[cur_queue];
                       flag <= 1;
                       state <= WR_PKT_QUE;
                    end

                 end

                 else begin
                   rd_en <= 0;
                   pkt_fwd <= 0;
                   m_axis_tuser <= 0;
                   m_axis_tdata <= 0;
                   m_axis_tlast <= 0;
                   m_axis_tkeep <= 0;
                   m_axis_tvalid <= 0;
                   cur_queue <= ((cur_queue + 1) > (NUM_QUEUES-2)) ? ((cur_queue + 1)-(NUM_QUEUES-2)-1) : cur_queue + 1;
                   flag <= 0;
                   state <= CHK;
                 end

              end // CHK

              WR_PKT_50G: begin

                 if(m_axis_tready) begin // tready

                   // BACK TO CHK STATE
                   if(fifo_out_tlast[5] & empty[5]) begin
                     rd_en[5] <= 0;
                     pkt_fwd <= 0;
                     m_axis_tuser <= fifo_out_tuser[5];
                     m_axis_tdata <= fifo_out_tdata[5];
                     m_axis_tlast <= fifo_out_tlast[5];
                     m_axis_tkeep <= fifo_out_tkeep[5];
                     m_axis_tvalid <= ~empty[5];
                     cur_queue <= ((cur_queue + 1) > (NUM_QUEUES-2)) ? ((cur_queue + 1)-(NUM_QUEUES-2)-1) : cur_queue + 1;
                     flag <= 0;
                     state <= CHK;
                   end

                   else if (!empty[5]) begin
                     rd_en[5] <= 1;
                     pkt_fwd <= 1;
                     m_axis_tuser <= fifo_out_tuser[5];
                     m_axis_tdata <= fifo_out_tdata[5];
                     m_axis_tlast <= fifo_out_tlast[5];
                     m_axis_tkeep <= fifo_out_tkeep[5];
                     m_axis_tvalid <= ~empty[5];
                     flag <= 0;
                     state <= WR_PKT_50G;
                   end

                   else begin
                     rd_en[5] <= 0;
                     pkt_fwd <= 0;
                     m_axis_tuser <= fifo_out_tuser[5];
                     m_axis_tdata <= fifo_out_tdata[5];
                     m_axis_tlast <= fifo_out_tlast[5];
                     m_axis_tkeep <= fifo_out_tkeep[5];
                     m_axis_tvalid <= ~empty[5];
                     flag <= 0;
                     state <= WR_PKT_50G;
                   end


                 end // tready

              end // case: WR_PKT_50G

              WR_PKT_QUE: begin

                if ((m_axis_tready) & (fifo_out_tlast[cur_queue])) begin // tready & tlast

                  rd_en[cur_queue] <= 1;
                  pkt_fwd <= 1;
                  m_axis_tuser <= (fifo_out_tuser[cur_queue]) << 128;
                  m_axis_tdata <= fifo_out_tdata[cur_queue];
                  m_axis_tlast <= fifo_out_tlast[cur_queue];
                  m_axis_tkeep <= fifo_out_tkeep[cur_queue];
                  m_axis_tvalid <= ~empty[cur_queue];
                  cur_queue <= ((cur_queue + 1) > (NUM_QUEUES-2)) ? ((cur_queue + 1)-(NUM_QUEUES-2)-1) : cur_queue + 1;
                  flag <= 0;
                  state <= CHK;

                end // tready & tlast

                else if ((m_axis_tready) & (!fifo_out_tlast[cur_queue])) begin // tready & !tlast

                  if (empty[cur_queue]) begin // empty

                    rd_en[cur_queue] <= 0;
                    pkt_fwd <= 0;
                    m_axis_tuser <= (fifo_out_tuser[cur_queue]) << 128;
                    m_axis_tdata <= fifo_out_tdata[cur_queue];
                    m_axis_tlast <= fifo_out_tlast[cur_queue];
                    m_axis_tkeep <= fifo_out_tkeep[cur_queue];
                    m_axis_tvalid <= ~empty[cur_queue];
                    state <= WR_PKT_QUE;

                  end // empty

                  else if ((!empty[cur_queue]) & (!flag)) begin // !empty & !flag

                    rd_en[cur_queue] <= 1;
                    pkt_fwd <= 1;
                    m_axis_tuser <= (fifo_out_tuser[cur_queue]) << 128;
                    m_axis_tdata <= fifo_out_tdata[cur_queue];
                    m_axis_tlast <= fifo_out_tlast[cur_queue];
                    m_axis_tkeep <= fifo_out_tkeep[cur_queue];
                    m_axis_tvalid <= ~empty[cur_queue];
                    flag <= 1;
                    state <= WR_PKT_QUE;

                  end // !empty & !flag

                  else if ((!empty[cur_queue]) & (flag)) begin // !empty & flag

                    rd_en[cur_queue] <= 0;
                    pkt_fwd <= 0;
                    m_axis_tuser <= 0;
                    m_axis_tdata <= 0;
                    m_axis_tlast <= 0;
                    m_axis_tkeep <= 0;
                    m_axis_tvalid <= 0;
                    flag <= 0;
                    state <= WR_PKT_QUE;

                  end // !empty & flag

                end // tready & !tlast

                else begin // !tready

                  rd_en[cur_queue] <= 0;
                  pkt_fwd <= 0;
                  m_axis_tuser <= 0;
                  m_axis_tdata <= 0;
                  m_axis_tlast <= 0;
                  m_axis_tkeep <= 0;
                  m_axis_tvalid <= 0;
                  state <= WR_PKT_QUE;

                end

              end // case: WR_PKT_QUE

              default: begin

                rd_en <= 0;
                pkt_fwd <= 0;
                m_axis_tuser <= 0;
                m_axis_tdata <= 0;
                m_axis_tlast <= 0;
                m_axis_tkeep <= 0;
                m_axis_tvalid <= 0;
                cur_queue <= 0;
                flag <= 0;
                state <= CHK;

              end // DEFAULT

            endcase // case(state)

      end // else

   end // always

//Registers section
 input_arbiter_6in_cpu_regs
 #(
   .C_S_AXI_DATA_WIDTH (C_S_AXI_DATA_WIDTH),
   .C_S_AXI_ADDR_WIDTH (C_S_AXI_ADDR_WIDTH),
   .C_BASE_ADDRESS    (C_BASEADDR)
 ) arbiter_cpu_regs_inst
 (
   // General ports
    .clk                    (axis_aclk),
    .resetn                 (axis_resetn),
   // AXI Lite ports
    .S_AXI_ACLK             (S_AXI_ACLK),
    .S_AXI_ARESETN          (S_AXI_ARESETN),
    .S_AXI_AWADDR           (S_AXI_AWADDR),
    .S_AXI_AWVALID          (S_AXI_AWVALID),
    .S_AXI_WDATA            (S_AXI_WDATA),
    .S_AXI_WSTRB            (S_AXI_WSTRB),
    .S_AXI_WVALID           (S_AXI_WVALID),
    .S_AXI_BREADY           (S_AXI_BREADY),
    .S_AXI_ARADDR           (S_AXI_ARADDR),
    .S_AXI_ARVALID          (S_AXI_ARVALID),
    .S_AXI_RREADY           (S_AXI_RREADY),
    .S_AXI_ARREADY          (S_AXI_ARREADY),
    .S_AXI_RDATA            (S_AXI_RDATA),
    .S_AXI_RRESP            (S_AXI_RRESP),
    .S_AXI_RVALID           (S_AXI_RVALID),
    .S_AXI_WREADY           (S_AXI_WREADY),
    .S_AXI_BRESP            (S_AXI_BRESP),
    .S_AXI_BVALID           (S_AXI_BVALID),
    .S_AXI_AWREADY          (S_AXI_AWREADY),


   // Register ports
   .id_reg          (id_reg),
   .version_reg          (version_reg),
   .reset_reg          (reset_reg),
   .ip2cpu_flip_reg          (ip2cpu_flip_reg),
   .cpu2ip_flip_reg          (cpu2ip_flip_reg),
   .pktin_reg          (pktin_reg),
   .pktin_reg_clear    (pktin_reg_clear),
   .pktout_reg          (pktout_reg),
   .pktout_reg_clear    (pktout_reg_clear),
   .ip2cpu_debug_reg          (ip2cpu_debug_reg),
   .cpu2ip_debug_reg          (cpu2ip_debug_reg),
   // Global Registers - user can select if to use
   .cpu_resetn_soft(),//software reset, after cpu module
   .resetn_soft    (),//software reset to cpu module (from central reset management)
   .resetn_sync    (resetn_sync)//synchronized reset, use for better timing
);

assign clear_counters = reset_reg[0];
assign reset_registers = reset_reg[4];

always @(posedge axis_aclk)
  if (~resetn_sync | reset_registers) begin
    id_reg <= #1    `REG_ID_DEFAULT;
    version_reg <= #1    `REG_VERSION_DEFAULT;
    ip2cpu_flip_reg <= #1    `REG_FLIP_DEFAULT;
    pktin_reg <= #1    `REG_PKTIN_DEFAULT;
    pktout_reg <= #1    `REG_PKTOUT_DEFAULT;
    ip2cpu_debug_reg <= #1    `REG_DEBUG_DEFAULT;
  end
  else begin
    id_reg <= #1    `REG_ID_DEFAULT;
    version_reg <= #1    `REG_VERSION_DEFAULT;
    ip2cpu_flip_reg <= #1    ~cpu2ip_flip_reg;
    pktin_reg[`REG_PKTIN_WIDTH -2: 0] <= #1  clear_counters | pktin_reg_clear ? 'h0  : pktin_reg[`REG_PKTIN_WIDTH-2:0] + (s_axis_0_tlast && s_axis_0_tvalid && s_axis_0_tready ) + (s_axis_1_tlast && s_axis_1_tvalid && s_axis_1_tready) + (s_axis_2_tlast && s_axis_2_tvalid && s_axis_2_tready) + (s_axis_3_tlast && s_axis_3_tvalid && s_axis_3_tready) + (s_axis_4_tlast && s_axis_4_tvalid && s_axis_4_tready) + (s_axis_5_tlast && s_axis_5_tvalid && s_axis_5_tready) ;
        pktin_reg[`REG_PKTIN_WIDTH-1] <= #1 clear_counters | pktin_reg_clear ? 1'h0 : pktin_reg_clear ? 'h0  : pktin_reg[`REG_PKTIN_WIDTH-2:0] + pktin_reg[`REG_PKTIN_WIDTH-2:0] + (s_axis_0_tlast && s_axis_0_tvalid && s_axis_0_tready ) + (s_axis_1_tlast && s_axis_1_tvalid && s_axis_1_tready) + (s_axis_2_tlast && s_axis_2_tvalid && s_axis_2_tready) + (s_axis_3_tlast && s_axis_3_tvalid && s_axis_3_tready) + (s_axis_4_tlast && s_axis_4_tvalid && s_axis_4_tready) + (s_axis_5_tlast && s_axis_5_tvalid && s_axis_5_tready) > {(`REG_PKTIN_WIDTH-1){1'b1}} ? 1'b1 : pktin_reg[`REG_PKTIN_WIDTH-1];

    pktout_reg [`REG_PKTOUT_WIDTH-2:0]<= #1  clear_counters | pktout_reg_clear ? 'h0  : pktout_reg [`REG_PKTOUT_WIDTH-2:0] + (m_axis_tvalid && m_axis_tlast && m_axis_tready ) ;
                pktout_reg [`REG_PKTOUT_WIDTH-1]<= #1  clear_counters | pktout_reg_clear ? 'h0  : pktout_reg [`REG_PKTOUT_WIDTH-2:0] + (m_axis_tvalid && m_axis_tlast && m_axis_tready) > {(`REG_PKTOUT_WIDTH-1){1'b1}} ?
                                                                1'b1 : pktout_reg [`REG_PKTOUT_WIDTH-1];
                ip2cpu_debug_reg <= #1    `REG_DEBUG_DEFAULT+cpu2ip_debug_reg;
        end



endmodule
