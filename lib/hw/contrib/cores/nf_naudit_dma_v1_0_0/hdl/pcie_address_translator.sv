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
`timescale 1ns / 1ps
`default_nettype none

module pcie_address_translator #(
  parameter C_BAR_ADDR        = 64'h0000000044000000,
  parameter C_BAR_SIZE        = 64'h0000000000100000,
  parameter C_TRANSLATOR_ADDR = 16'h199             ,
  parameter C_ADDR_WIDTH      = 32                  ,
  parameter C_ADDR_WIDTH_IFACE = 16
) (
  input  wire                    USER_CLK         ,
  input  wire                    RESET_N          ,
  input  wire                    M_AXI_LITE_ACLK,
  input  wire                    M_AXI_LITE_ARESETN,
  input  wire [C_ADDR_WIDTH-1:0] M_AXI_LITE_AWADDR,
  input  wire [C_ADDR_WIDTH-1:0] M_AXI_LITE_ARADDR,
  output wire [C_ADDR_WIDTH-1:0] S_AXI_LITE_AWADDR,
  output wire [C_ADDR_WIDTH-1:0] S_AXI_LITE_ARADDR,
  input  wire                    S_MEM_IFACE_EN   ,
  input  wire [C_ADDR_WIDTH_IFACE-1 : 0] S_MEM_IFACE_ADDR ,
  output wire [            63:0] S_MEM_IFACE_DOUT ,
  input  wire [            63:0] S_MEM_IFACE_DIN  ,
  input  wire [             7:0] S_MEM_IFACE_WE   ,
  output reg                     S_MEM_IFACE_ACK

);

  reg [63:0] hw_base_addr;
  reg [31:0] axi_lite_hw_base_addr;
  wire [31:0] m_axis_hw_base_addr;
  wire rd_en;
  wire valid;

  always_ff @(negedge RESET_N or posedge USER_CLK) begin
        if(!RESET_N) begin
            hw_base_addr <= C_BAR_ADDR;
        end else begin
            if(S_MEM_IFACE_EN && S_MEM_IFACE_ADDR == C_TRANSLATOR_ADDR) begin
                if(S_MEM_IFACE_WE[0]) hw_base_addr[7:0]    <=  S_MEM_IFACE_DIN[7:0];
                if(S_MEM_IFACE_WE[1]) hw_base_addr[15:8]   <=  S_MEM_IFACE_DIN[15:8];
                if(S_MEM_IFACE_WE[2]) hw_base_addr[23:16]  <=  S_MEM_IFACE_DIN[23:16];
                if(S_MEM_IFACE_WE[3]) hw_base_addr[31:24]  <=  S_MEM_IFACE_DIN[31:24];
                if(S_MEM_IFACE_WE[4]) hw_base_addr[39:32]  <=  S_MEM_IFACE_DIN[39:32];
                if(S_MEM_IFACE_WE[5]) hw_base_addr[47:40]  <=  S_MEM_IFACE_DIN[47:40];
                if(S_MEM_IFACE_WE[6]) hw_base_addr[55:48]  <=  S_MEM_IFACE_DIN[55:48];
                if(S_MEM_IFACE_WE[7]) hw_base_addr[63:56]  <=  S_MEM_IFACE_DIN[63:56];
            end
        end
  end

  always_ff @(negedge RESET_N or posedge USER_CLK) begin
    if(!RESET_N) begin
        S_MEM_IFACE_ACK <= 1'b0;
    end else begin
      if(S_MEM_IFACE_EN && S_MEM_IFACE_ADDR == C_TRANSLATOR_ADDR) begin
        S_MEM_IFACE_ACK <= 1'b1;
      end else begin
        S_MEM_IFACE_ACK <= 1'b0;
      end
    end
  end

  axis_fifo_2clk_32d_12u wa_fifo (
    .s_aclk       (USER_CLK          ),
    .s_aresetn    (RESET_N           ),
    .s_axis_tvalid(S_MEM_IFACE_ACK   ), // latch when ACK
    .s_axis_tready(                  ),
    .s_axis_tdata (hw_base_addr[31:0]),
    .s_axis_tuser (12'b0             ),

    .m_aclk       (M_AXI_LITE_ACLK   ),
    .m_axis_tvalid(valid             ),
    .m_axis_tready(rd_en             ),
    .m_axis_tdata (m_axis_hw_base_addr),
    .m_axis_tuser (                  )
  );

 // drain fifo & latch the output
 assign rd_en = valid;

 always_ff @(negedge M_AXI_LITE_ARESETN or posedge M_AXI_LITE_ACLK) begin
    if(!M_AXI_LITE_ARESETN) begin
        axi_lite_hw_base_addr <= C_BAR_ADDR[31:0];
    end else begin
        if (valid)
            axi_lite_hw_base_addr <= m_axis_hw_base_addr;
    end
 end

  assign S_MEM_IFACE_DOUT  = 0;
  assign S_AXI_LITE_AWADDR = { axi_lite_hw_base_addr[31:$clog2(C_BAR_SIZE)], M_AXI_LITE_AWADDR[$clog2(C_BAR_SIZE)-1:0] };
  assign S_AXI_LITE_ARADDR = { axi_lite_hw_base_addr[31:$clog2(C_BAR_SIZE)], M_AXI_LITE_ARADDR[$clog2(C_BAR_SIZE)-1:0] };


endmodule
