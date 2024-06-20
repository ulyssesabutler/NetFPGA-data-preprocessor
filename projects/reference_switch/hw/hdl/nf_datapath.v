`timescale 1ns / 1ps
//-
// Copyright (c) 2015 Noa Zilberman
// All rights reserved.
//
// This software was developed by Stanford University and the University of Cambridge Computer Laboratory 
// under National Science Foundation under Grant No. CNS-0855268,
// the University of Cambridge Computer Laboratory under EPSRC INTERNET Project EP/H040536/1 and
// by the University of Cambridge Computer Laboratory under DARPA/AFRL contract FA8750-11-C-0249 ("MRC2"), 
// as part of the DARPA MRC research programme.
//
//  File:
//        nf_datapath.v
//
//  Module:
//        nf_datapath
//
//  Author: Noa Zilberman
//
//  Description:
//        NetFPGA user data path wrapper, wrapping input arbiter, output port lookup and output queues
//
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


module nf_datapath #(
    //Slave AXI parameters
    parameter C_S_AXI_DATA_WIDTH    = 32,          
    parameter C_S_AXI_ADDR_WIDTH    = 32,          
     parameter C_BASEADDR            = 32'h00000000,

    // Master AXI Stream Data Width
    parameter C_M_AXIS_DATA_WIDTH=256,
    parameter C_S_AXIS_DATA_WIDTH=256,
    parameter C_M_AXIS_TUSER_WIDTH=128,
    parameter C_S_AXIS_TUSER_WIDTH=128,
    parameter NUM_QUEUES=5
)
(
    //Datapath clock
    input                                     axis_aclk,
    input                                     axis_resetn,
    //Registers clock
    input                                     axi_aclk,
    input                                     axi_resetn,

    // Slave AXI Ports
    input      [C_S_AXI_ADDR_WIDTH-1 : 0]     S0_AXI_AWADDR,
    input                                     S0_AXI_AWVALID,
    input      [C_S_AXI_DATA_WIDTH-1 : 0]     S0_AXI_WDATA,
    input      [C_S_AXI_DATA_WIDTH/8-1 : 0]   S0_AXI_WSTRB,
    input                                     S0_AXI_WVALID,
    input                                     S0_AXI_BREADY,
    input      [C_S_AXI_ADDR_WIDTH-1 : 0]     S0_AXI_ARADDR,
    input                                     S0_AXI_ARVALID,
    input                                     S0_AXI_RREADY,
    output                                    S0_AXI_ARREADY,
    output     [C_S_AXI_DATA_WIDTH-1 : 0]     S0_AXI_RDATA,
    output     [1 : 0]                        S0_AXI_RRESP,
    output                                    S0_AXI_RVALID,
    output                                    S0_AXI_WREADY,
    output     [1 :0]                         S0_AXI_BRESP,
    output                                    S0_AXI_BVALID,
    output                                    S0_AXI_AWREADY,
    
    input      [C_S_AXI_ADDR_WIDTH-1 : 0]     S1_AXI_AWADDR,
    input                                     S1_AXI_AWVALID,
    input      [C_S_AXI_DATA_WIDTH-1 : 0]     S1_AXI_WDATA,
    input      [C_S_AXI_DATA_WIDTH/8-1 : 0]   S1_AXI_WSTRB,
    input                                     S1_AXI_WVALID,
    input                                     S1_AXI_BREADY,
    input      [C_S_AXI_ADDR_WIDTH-1 : 0]     S1_AXI_ARADDR,
    input                                     S1_AXI_ARVALID,
    input                                     S1_AXI_RREADY,
    output                                    S1_AXI_ARREADY,
    output     [C_S_AXI_DATA_WIDTH-1 : 0]     S1_AXI_RDATA,
    output     [1 : 0]                        S1_AXI_RRESP,
    output                                    S1_AXI_RVALID,
    output                                    S1_AXI_WREADY,
    output     [1 :0]                         S1_AXI_BRESP,
    output                                    S1_AXI_BVALID,
    output                                    S1_AXI_AWREADY,

    input      [C_S_AXI_ADDR_WIDTH-1 : 0]     S2_AXI_AWADDR,
    input                                     S2_AXI_AWVALID,
    input      [C_S_AXI_DATA_WIDTH-1 : 0]     S2_AXI_WDATA,
    input      [C_S_AXI_DATA_WIDTH/8-1 : 0]   S2_AXI_WSTRB,
    input                                     S2_AXI_WVALID,
    input                                     S2_AXI_BREADY,
    input      [C_S_AXI_ADDR_WIDTH-1 : 0]     S2_AXI_ARADDR,
    input                                     S2_AXI_ARVALID,
    input                                     S2_AXI_RREADY,
    output                                    S2_AXI_ARREADY,
    output     [C_S_AXI_DATA_WIDTH-1 : 0]     S2_AXI_RDATA,
    output     [1 : 0]                        S2_AXI_RRESP,
    output                                    S2_AXI_RVALID,
    output                                    S2_AXI_WREADY,
    output     [1 :0]                         S2_AXI_BRESP,
    output                                    S2_AXI_BVALID,
    output                                    S2_AXI_AWREADY,

    
    // Slave Stream Ports (interface from Rx queues)
    input [C_S_AXIS_DATA_WIDTH - 1:0]         s_axis_0_tdata,
    input [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0] s_axis_0_tkeep,
    input [C_S_AXIS_TUSER_WIDTH-1:0]          s_axis_0_tuser,
    input                                     s_axis_0_tvalid,
    output                                    s_axis_0_tready,
    input                                     s_axis_0_tlast,
    input [C_S_AXIS_DATA_WIDTH - 1:0]         s_axis_1_tdata,
    input [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0] s_axis_1_tkeep,
    input [C_S_AXIS_TUSER_WIDTH-1:0]          s_axis_1_tuser,
    input                                     s_axis_1_tvalid,
    output                                    s_axis_1_tready,
    input                                     s_axis_1_tlast,
    input [C_S_AXIS_DATA_WIDTH - 1:0]         s_axis_2_tdata,
    input [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0] s_axis_2_tkeep,
    input [C_S_AXIS_TUSER_WIDTH-1:0]          s_axis_2_tuser,
    input                                     s_axis_2_tvalid,
    output                                    s_axis_2_tready,
    input                                     s_axis_2_tlast,
    input [C_S_AXIS_DATA_WIDTH - 1:0]         s_axis_3_tdata,
    input [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0] s_axis_3_tkeep,
    input [C_S_AXIS_TUSER_WIDTH-1:0]          s_axis_3_tuser,
    input                                     s_axis_3_tvalid,
    output                                    s_axis_3_tready,
    input                                     s_axis_3_tlast,
    input [C_S_AXIS_DATA_WIDTH - 1:0]         s_axis_4_tdata,
    input [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0] s_axis_4_tkeep,
    input [C_S_AXIS_TUSER_WIDTH-1:0]          s_axis_4_tuser,
    input                                     s_axis_4_tvalid,
    output                                    s_axis_4_tready,
    input                                     s_axis_4_tlast,


    // Master Stream Ports (interface to TX queues)
    output [C_M_AXIS_DATA_WIDTH - 1:0]         m_axis_0_tdata,
    output [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] m_axis_0_tkeep,
    output [C_M_AXIS_TUSER_WIDTH-1:0]          m_axis_0_tuser,
    output                                     m_axis_0_tvalid,
    input                                      m_axis_0_tready,
    output                                     m_axis_0_tlast,
    output [C_M_AXIS_DATA_WIDTH - 1:0]         m_axis_1_tdata,
    output [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] m_axis_1_tkeep,
    output [C_M_AXIS_TUSER_WIDTH-1:0]          m_axis_1_tuser,
    output                                     m_axis_1_tvalid,
    input                                      m_axis_1_tready,
    output                                     m_axis_1_tlast,
    output [C_M_AXIS_DATA_WIDTH - 1:0]         m_axis_2_tdata,
    output [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] m_axis_2_tkeep,
    output [C_M_AXIS_TUSER_WIDTH-1:0]          m_axis_2_tuser,
    output                                     m_axis_2_tvalid,
    input                                      m_axis_2_tready,
    output                                     m_axis_2_tlast,
    output [C_M_AXIS_DATA_WIDTH - 1:0]         m_axis_3_tdata,
    output [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] m_axis_3_tkeep,
    output [C_M_AXIS_TUSER_WIDTH-1:0]          m_axis_3_tuser,
    output                                     m_axis_3_tvalid,
    input                                      m_axis_3_tready,
    output                                     m_axis_3_tlast,
    output [C_M_AXIS_DATA_WIDTH - 1:0]         m_axis_4_tdata,
    output [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] m_axis_4_tkeep,
    output [C_M_AXIS_TUSER_WIDTH-1:0]          m_axis_4_tuser,
    output                                     m_axis_4_tvalid,
    input                                      m_axis_4_tready,
    output                                     m_axis_4_tlast


    );
    
    //internal connectivity
  
    wire [C_M_AXIS_DATA_WIDTH - 1:0]         m_axis_opl_tdata;
    wire [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] m_axis_opl_tkeep;
    wire [C_M_AXIS_TUSER_WIDTH-1:0]          m_axis_opl_tuser;
    wire                                     m_axis_opl_tvalid;
    wire                                     m_axis_opl_tready;
    wire                                     m_axis_opl_tlast;
     
    wire [C_M_AXIS_DATA_WIDTH - 1:0]         s_axis_opl_tdata;
    wire [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] s_axis_opl_tkeep;
    wire [C_M_AXIS_TUSER_WIDTH-1:0]          s_axis_opl_tuser;
    wire                                     s_axis_opl_tvalid;
    wire                                     s_axis_opl_tready;
    wire                                     s_axis_opl_tlast;

    wire [C_M_AXIS_DATA_WIDTH - 1:0]         processed_packet_axis_tdata;
    wire [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] processed_packet_axis_tkeep;
    wire [C_M_AXIS_TUSER_WIDTH-1:0]          processed_packet_axis_tuser;
    wire                                     processed_packet_axis_tvalid;
    wire                                     processed_packet_axis_tready;
    wire                                     processed_packet_axis_tlast;
   
  //Input Arbiter
  input_arbiter_ip 
 input_arbiter_v1_0 (
      .axis_aclk(axis_aclk), 
      .axis_resetn(axis_resetn), 
      .m_axis_tdata (s_axis_opl_tdata), 
      .m_axis_tkeep (s_axis_opl_tkeep), 
      .m_axis_tuser (s_axis_opl_tuser), 
      .m_axis_tvalid(s_axis_opl_tvalid), 
      .m_axis_tready(s_axis_opl_tready), 
      .m_axis_tlast (s_axis_opl_tlast), 
      .s_axis_0_tdata (s_axis_0_tdata), 
      .s_axis_0_tkeep (s_axis_0_tkeep), 
      .s_axis_0_tuser (s_axis_0_tuser), 
      .s_axis_0_tvalid(s_axis_0_tvalid), 
      .s_axis_0_tready(s_axis_0_tready), 
      .s_axis_0_tlast (s_axis_0_tlast), 
      .s_axis_1_tdata (s_axis_1_tdata), 
      .s_axis_1_tkeep (s_axis_1_tkeep), 
      .s_axis_1_tuser (s_axis_1_tuser), 
      .s_axis_1_tvalid(s_axis_1_tvalid), 
      .s_axis_1_tready(s_axis_1_tready), 
      .s_axis_1_tlast (s_axis_1_tlast), 
      .s_axis_2_tdata (s_axis_2_tdata), 
      .s_axis_2_tkeep (s_axis_2_tkeep), 
      .s_axis_2_tuser (s_axis_2_tuser), 
      .s_axis_2_tvalid(s_axis_2_tvalid), 
      .s_axis_2_tready(s_axis_2_tready), 
      .s_axis_2_tlast (s_axis_2_tlast), 
      .s_axis_3_tdata (s_axis_3_tdata), 
      .s_axis_3_tkeep (s_axis_3_tkeep), 
      .s_axis_3_tuser (s_axis_3_tuser), 
      .s_axis_3_tvalid(s_axis_3_tvalid), 
      .s_axis_3_tready(s_axis_3_tready), 
      .s_axis_3_tlast (s_axis_3_tlast), 
      .s_axis_4_tdata (s_axis_4_tdata), 
      .s_axis_4_tkeep (s_axis_4_tkeep), 
      .s_axis_4_tuser (s_axis_4_tuser), 
      .s_axis_4_tvalid(s_axis_4_tvalid), 
      .s_axis_4_tready(s_axis_4_tready), 
      .s_axis_4_tlast (s_axis_4_tlast), 
      .S_AXI_AWADDR(S0_AXI_AWADDR), 
      .S_AXI_AWVALID(S0_AXI_AWVALID),
      .S_AXI_WDATA(S0_AXI_WDATA),  
      .S_AXI_WSTRB(S0_AXI_WSTRB),  
      .S_AXI_WVALID(S0_AXI_WVALID), 
      .S_AXI_BREADY(S0_AXI_BREADY), 
      .S_AXI_ARADDR(S0_AXI_ARADDR), 
      .S_AXI_ARVALID(S0_AXI_ARVALID),
      .S_AXI_RREADY(S0_AXI_RREADY), 
      .S_AXI_ARREADY(S0_AXI_ARREADY),
      .S_AXI_RDATA(S0_AXI_RDATA),  
      .S_AXI_RRESP(S0_AXI_RRESP),  
      .S_AXI_RVALID(S0_AXI_RVALID), 
      .S_AXI_WREADY(S0_AXI_WREADY), 
      .S_AXI_BRESP(S0_AXI_BRESP),  
      .S_AXI_BVALID(S0_AXI_BVALID), 
      .S_AXI_AWREADY(S0_AXI_AWREADY),
      .S_AXI_ACLK (axi_aclk), 
      .S_AXI_ARESETN(axi_resetn),
      .pkt_fwd() 
    );
    
    
    
     //Output Port Lookup  
       output_port_lookup_ip 
     output_port_lookup_1  (
      .axis_aclk(axis_aclk), 
      .axis_resetn(axis_resetn), 
      .m_axis_tdata (m_axis_opl_tdata), 
      .m_axis_tkeep (m_axis_opl_tkeep), 
      .m_axis_tuser (m_axis_opl_tuser), 
      .m_axis_tvalid(m_axis_opl_tvalid), 
      .m_axis_tready(m_axis_opl_tready), 
      .m_axis_tlast (m_axis_opl_tlast), 
      .s_axis_tdata (s_axis_opl_tdata), 
      .s_axis_tkeep (s_axis_opl_tkeep), 
      .s_axis_tuser (s_axis_opl_tuser), 
      .s_axis_tvalid(s_axis_opl_tvalid), 
      .s_axis_tready(s_axis_opl_tready), 
      .s_axis_tlast (s_axis_opl_tlast), 

      .S_AXI_AWADDR(S1_AXI_AWADDR), 
      .S_AXI_AWVALID(S1_AXI_AWVALID),
      .S_AXI_WDATA(S1_AXI_WDATA),  
      .S_AXI_WSTRB(S1_AXI_WSTRB),  
      .S_AXI_WVALID(S1_AXI_WVALID), 
      .S_AXI_BREADY(S1_AXI_BREADY), 
      .S_AXI_ARADDR(S1_AXI_ARADDR), 
      .S_AXI_ARVALID(S1_AXI_ARVALID),
      .S_AXI_RREADY(S1_AXI_RREADY), 
      .S_AXI_ARREADY(S1_AXI_ARREADY),
      .S_AXI_RDATA(S1_AXI_RDATA),  
      .S_AXI_RRESP(S1_AXI_RRESP),  
      .S_AXI_RVALID(S1_AXI_RVALID), 
      .S_AXI_WREADY(S1_AXI_WREADY), 
      .S_AXI_BRESP(S1_AXI_BRESP),  
      .S_AXI_BVALID(S1_AXI_BVALID), 
      .S_AXI_AWREADY(S1_AXI_AWREADY),
      .S_AXI_ACLK (axi_aclk), 
      .S_AXI_ARESETN(axi_resetn)


    );



    network_packet_processor packet_processor
    (
        .axis_aclk(axis_aclk), 
        .axis_resetn(axis_resetn), 

        // Output to output queues
        .m_axis_tdata   (processed_packet_axis_tdata),
        .m_axis_tkeep   (processed_packet_axis_tkeep),
        .m_axis_tuser   (processed_packet_axis_tuser),
        .m_axis_tvalid  (processed_packet_axis_tvalid),
        .m_axis_tready  (processed_packet_axis_tready),
        .m_axis_tlast   (processed_packet_axis_tlast),

        // Input from output port lookup
        .s_axis_tdata   (m_axis_opl_tdata), 
        .s_axis_tkeep   (m_axis_opl_tkeep), 
        .s_axis_tuser   (m_axis_opl_tuser), 
        .s_axis_tvalid  (m_axis_opl_tvalid), 
        .s_axis_tready  (m_axis_opl_tready), 
        .s_axis_tlast   (m_axis_opl_tlast)
    );



      //Output queues
       output_queues_ip  
     bram_output_queues_1 (
      .axis_aclk(axis_aclk), 
      .axis_resetn(axis_resetn), 

      .s_axis_tdata   (processed_packet_axis_tdata),
      .s_axis_tkeep   (processed_packet_axis_tkeep),
      .s_axis_tuser   (processed_packet_axis_tuser),
      .s_axis_tvalid  (processed_packet_axis_tvalid),
      .s_axis_tready  (processed_packet_axis_tready),
      .s_axis_tlast   (processed_packet_axis_tlast),

      /*
      .s_axis_tdata   (m_axis_opl_tdata), 
      .s_axis_tkeep   (m_axis_opl_tkeep), 
      .s_axis_tuser   (m_axis_opl_tuser), 
      .s_axis_tvalid  (m_axis_opl_tvalid), 
      .s_axis_tready  (m_axis_opl_tready), 
      .s_axis_tlast   (m_axis_opl_tlast), 
      */

      .m_axis_0_tdata (m_axis_0_tdata), 
      .m_axis_0_tkeep (m_axis_0_tkeep), 
      .m_axis_0_tuser (m_axis_0_tuser), 
      .m_axis_0_tvalid(m_axis_0_tvalid), 
      .m_axis_0_tready(m_axis_0_tready), 
      .m_axis_0_tlast (m_axis_0_tlast), 
      .m_axis_1_tdata (m_axis_1_tdata), 
      .m_axis_1_tkeep (m_axis_1_tkeep), 
      .m_axis_1_tuser (m_axis_1_tuser), 
      .m_axis_1_tvalid(m_axis_1_tvalid), 
      .m_axis_1_tready(m_axis_1_tready), 
      .m_axis_1_tlast (m_axis_1_tlast), 
      .m_axis_2_tdata (m_axis_2_tdata), 
      .m_axis_2_tkeep (m_axis_2_tkeep), 
      .m_axis_2_tuser (m_axis_2_tuser), 
      .m_axis_2_tvalid(m_axis_2_tvalid), 
      .m_axis_2_tready(m_axis_2_tready), 
      .m_axis_2_tlast (m_axis_2_tlast), 
      .m_axis_3_tdata (m_axis_3_tdata), 
      .m_axis_3_tkeep (m_axis_3_tkeep), 
      .m_axis_3_tuser (m_axis_3_tuser), 
      .m_axis_3_tvalid(m_axis_3_tvalid), 
      .m_axis_3_tready(m_axis_3_tready), 
      .m_axis_3_tlast (m_axis_3_tlast), 
      .m_axis_4_tdata (m_axis_4_tdata), 
      .m_axis_4_tkeep (m_axis_4_tkeep), 
      .m_axis_4_tuser (m_axis_4_tuser), 
      .m_axis_4_tvalid(m_axis_4_tvalid), 
      .m_axis_4_tready(m_axis_4_tready), 
      .m_axis_4_tlast (m_axis_4_tlast), 
      .bytes_stored(), 
      .pkt_stored(), 
      .bytes_removed_0(), 
      .bytes_removed_1(), 
      .bytes_removed_2(), 
      .bytes_removed_3(), 
      .bytes_removed_4(), 
      .pkt_removed_0(), 
      .pkt_removed_1(), 
      .pkt_removed_2(), 
      .pkt_removed_3(), 
      .pkt_removed_4(), 
      .bytes_dropped(), 
      .pkt_dropped(), 

      .S_AXI_AWADDR(S2_AXI_AWADDR), 
      .S_AXI_AWVALID(S2_AXI_AWVALID),
      .S_AXI_WDATA(S2_AXI_WDATA),  
      .S_AXI_WSTRB(S2_AXI_WSTRB),  
      .S_AXI_WVALID(S2_AXI_WVALID), 
      .S_AXI_BREADY(S2_AXI_BREADY), 
      .S_AXI_ARADDR(S2_AXI_ARADDR), 
      .S_AXI_ARVALID(S2_AXI_ARVALID),
      .S_AXI_RREADY(S2_AXI_RREADY), 
      .S_AXI_ARREADY(S2_AXI_ARREADY),
      .S_AXI_RDATA(S2_AXI_RDATA),  
      .S_AXI_RRESP(S2_AXI_RRESP),  
      .S_AXI_RVALID(S2_AXI_RVALID), 
      .S_AXI_WREADY(S2_AXI_WREADY), 
      .S_AXI_BRESP(S2_AXI_BRESP),  
      .S_AXI_BVALID(S2_AXI_BVALID), 
      .S_AXI_AWREADY(S2_AXI_AWREADY),
      .S_AXI_ACLK (axi_aclk), 
      .S_AXI_ARESETN(axi_resetn)
    ); 
    
endmodule

module network_packet_processor
#(
  // AXI Stream Data Width
  parameter TDATA_WIDTH        = 256,
  parameter TUSER_WIDTH        = 128,

  // NETWORK PACKET HEADER SIZES
  parameter ETH_HDR_SIZE_BYTES = 14,
  parameter IP_HDR_SIZE_BYTES  = 20
)
(
  // Global Ports
  input                              axis_aclk,
  input                              axis_resetn,

  // Master Stream Ports (The output of this module)
  output [TDATA_WIDTH - 1:0]         m_axis_tdata,
  output [((TDATA_WIDTH / 8)) - 1:0] m_axis_tkeep,
  output [TUSER_WIDTH-1:0]           m_axis_tuser,
  output                             m_axis_tvalid,
  input                              m_axis_tready,
  output                             m_axis_tlast,

  // Slave Stream Ports (The input of this module)
  input [TDATA_WIDTH - 1:0]          s_axis_tdata,
  input [((TDATA_WIDTH / 8)) - 1:0]  s_axis_tkeep,
  input [TUSER_WIDTH-1:0]            s_axis_tuser,
  input                              s_axis_tvalid,
  output                             s_axis_tready,
  input                              s_axis_tlast
);  

  /*************************************************************************************************\
  |* INPUT QUEUE
  \*************************************************************************************************/

  // VARIABLES
  wire [TDATA_WIDTH - 1:0]         input_fifo_head_tdata;
  wire [((TDATA_WIDTH / 8)) - 1:0] input_fifo_head_tkeep;
  wire [TUSER_WIDTH-1:0]           input_fifo_head_tuser;
  wire                             input_fifo_head_tlast;

  wire                             input_fifo_nearly_full;
  wire                             input_fifo_empty;

  wire                             write_to_input_queue;
  wire                             read_from_input_queue;

  // INPUT QUEUE MODULE
  fallthrough_small_fifo
  #(
    .WIDTH(TDATA_WIDTH+TUSER_WIDTH+TDATA_WIDTH/8+1), // Fit the whole AXIS packet
    .MAX_DEPTH_BITS(4)
  )
  input_fifo
  (
    .din         ({s_axis_tdata, s_axis_tkeep, s_axis_tuser, s_axis_tlast}), // Pass the packet heads as input directly to the queue
    .wr_en       (write_to_input_queue), // Write enable
    .rd_en       (read_from_input_queue), // Read enabled
    .dout        ({input_fifo_head_tdata, input_fifo_head_tkeep, input_fifo_head_tuser, input_fifo_head_tlast}), // Return TLAST, TKEEP, and TUSER directly to the next stage. Write TDATA to a wire for processing
    .full        (),
    .prog_full   (),
    .nearly_full (input_fifo_nearly_full),
    .empty       (input_fifo_empty),
    .reset       (~axis_resetn),
    .clk         (axis_aclk)
  );

  // LOGIC
  reg    net_packet_reading_complete;

  assign s_axis_tready = ~input_fifo_nearly_full & ~net_packet_reading_complete; // There is room in the queue and we're processing the current packet
  assign write_to_input_queue = s_axis_tready & s_axis_tvalid;

  /*************************************************************************************************\
  |* OUTPUT QUEUE
  \*************************************************************************************************/

  // VARIABLES
  reg [TDATA_WIDTH - 1:0]         output_fifo_tdata;
  reg [((TDATA_WIDTH / 8)) - 1:0] output_fifo_tkeep;
  reg [TUSER_WIDTH-1:0]           output_fifo_tuser;
  reg                             output_fifo_tlast;

  wire                            output_fifo_nearly_full;
  wire                            output_fifo_empty;

  reg                             write_to_output_queue;
  wire                            read_from_output_queue;

  // OUTPUT QUEUE MODULE
  fallthrough_small_fifo
  #(
    .WIDTH(TDATA_WIDTH+TUSER_WIDTH+TDATA_WIDTH/8+1), // Fit the whole AXIS packet
    .MAX_DEPTH_BITS(4)
  )
  output_fifo
  (
    .din         ({output_fifo_tdata, output_fifo_tkeep, output_fifo_tuser, output_fifo_tlast}), // Pass the packet heads as input directly to the queue
    .wr_en       (write_to_output_queue), // Write enable
    .rd_en       (read_from_output_queue), // Read enabled
    .dout        ({m_axis_tdata, m_axis_tkeep, m_axis_tuser, m_axis_tlast}), // Return TLAST, TKEEP, and TUSER directly to the next stage. Write TDATA to a wire for processing
    .full        (),
    .prog_full   (),
    .nearly_full (output_fifo_nearly_full),
    .empty       (output_fifo_empty),
    .reset       (~axis_resetn),
    .clk         (axis_aclk)
  );

  // LOGIC
  assign m_axis_tvalid = ~output_fifo_empty;
  assign read_from_output_queue = m_axis_tvalid & m_axis_tready;

  /*************************************************************************************************\
  |* FSM
  \*************************************************************************************************/

  // Define the states
  localparam STATE_INFO_COLLECTION   = 0;
  localparam STATE_PACKET_PROCESSING = 1;

  // Store the current and next state
  reg [0:0]  state;
  reg [0:0]  state_next;

  // The info collector and packet processor will use these flags to signal state transitions
  reg        finished_info_collection;
  reg        finished_packet_processing;

  // State transition logic
  always @(*) begin
    state_next = state;

    case (state)

      STATE_INFO_COLLECTION: begin
        if (finished_info_collection)   state_next = STATE_PACKET_PROCESSING;
      end

      STATE_PACKET_PROCESSING: begin
        if (finished_packet_processing) state_next = STATE_INFO_COLLECTION;
      end

    endcase
  end

  always @(posedge axis_aclk) begin
    if (~axis_resetn) state <= STATE_INFO_COLLECTION;
    else              state <= state_next;
  end

  /*************************************************************************************************\
  |* INPUT PROCESSOR
  \*************************************************************************************************/

  // Keeps track of which axis packet we're currently on, starting at 0 for each network packet
  reg [31:0] axis_packet_already_read_count;
  reg [31:0] axis_packet_already_read_count_next;

  reg [31:0] axis_packet_reading_count;

  // Track our progresss
  reg        are_registers_loaded;
  reg        net_packet_reading_complete_next;

  // Packet info
  reg [31:0] body_offset;
  reg [31:0] body_offset_next;

  always @(*) begin
    axis_packet_reading_count           = axis_packet_already_read_count;
    axis_packet_already_read_count_next = axis_packet_already_read_count;
    net_packet_reading_complete_next    = net_packet_reading_complete;
    body_offset_next                    = body_offset;

    are_registers_loaded                = 0;
    finished_info_collection            = 0;

    // If we're currently writting a packet to the input queue, we're reading 1 more packet than we've read
    if (write_to_input_queue & state == STATE_INFO_COLLECTION) begin
      axis_packet_reading_count           = axis_packet_already_read_count + 1;
      axis_packet_already_read_count_next = axis_packet_already_read_count + 1;
    end

    // Determine whether or not the last AXI packet has already been read for this network packet.
    if (write_to_input_queue & s_axis_tlast)
      net_packet_reading_complete_next = 1;
    else if (finished_packet_processing)
      net_packet_reading_complete_next = 0;

    // This is where we actually collect the info, depending on what part of the packet we're currently processing
    if (state == STATE_INFO_COLLECTION) begin
      case (axis_packet_reading_count)

        // This is the second packet
        2: begin
          // We will collect the BMP offset in the future. For now, we're just writing a constant value as a placeholder
          body_offset_next = 34;

          // For now, that's all the data we need
          are_registers_loaded = 1;
        end

      endcase
    end

    // Finally, we need to decide whether or not to signal that the info collection is complete
    if (state == STATE_INFO_COLLECTION & are_registers_loaded) begin
      finished_info_collection = 1;
      // If we're moving from an info collection state, then reset the read packet count.
      axis_packet_already_read_count_next = 0;
    end
  end

  always @(posedge axis_aclk) begin
    if (~axis_resetn) begin
      axis_packet_already_read_count <= 0;
      net_packet_reading_complete    <= 0;
      body_offset                    <= 0;
    end else begin
      axis_packet_already_read_count <= axis_packet_already_read_count_next;
      net_packet_reading_complete    <= net_packet_reading_complete_next;
      body_offset                    <= body_offset_next;
    end
  end

  /*************************************************************************************************\
  |* PACKET PROCESSOR
  |* ================
  |* Once we're in a packet processing state, mutate the data as we move it from the input queue to
  |* the output queue.
  \*************************************************************************************************/

  // Packet Processing Timing Control
  assign read_from_input_queue = ~input_fifo_empty & ~output_fifo_nearly_full & (state == STATE_PACKET_PROCESSING);

  // Body Processing
  reg  [(TDATA_WIDTH / 8) - 1:0] body_processing_byte_mask;
  wire [TDATA_WIDTH - 1:0]       processed_output_tdata;

  image_processor image_pixel_processor
  (
    .data_in(input_fifo_head_tdata),
    .byte_mask(body_processing_byte_mask),
    .data_out(processed_output_tdata)
  );

  // Body Processing Mask
  wire [31:0] body_processing_bytes_in_current_axi_packet;
  assign      body_processing_bytes_in_current_axi_packet = (body_offset - bytes_processed_before_current_axi_packet);

  always @(*) begin
    // If we're already past the offset point, keep all non-null bytes
    if (bytes_processed_before_current_axi_packet > body_offset)
      body_processing_byte_mask = input_fifo_head_tkeep;
    else
      body_processing_byte_mask = (input_fifo_head_tkeep >> body_processing_bytes_in_current_axi_packet) << body_processing_bytes_in_current_axi_packet;
  end

  // Processed bytes tracking
  reg [31:0] bytes_processed_before_current_axi_packet;
  reg [31:0] bytes_processed_before_current_axi_packet_next;

  always @(*) begin
    bytes_processed_before_current_axi_packet_next = bytes_processed_before_current_axi_packet;

    case (state)

      STATE_INFO_COLLECTION: begin
        // If we're in the info collection state, we haven't processed any AXI packets, so make sure this is reset.
        bytes_processed_before_current_axi_packet_next = 0;
      end

      STATE_PACKET_PROCESSING: begin
        if (read_from_input_queue)
          // TODO: Replace with population could of TKEEP
          bytes_processed_before_current_axi_packet_next = bytes_processed_before_current_axi_packet + 32;
      end

    endcase
  end

  // Signal end of processing
  always @(*) begin
    if (read_from_output_queue & input_fifo_head_tlast)
      finished_packet_processing = 1;
    else
      finished_packet_processing = 0;
  end

  // Output
  always @(posedge axis_aclk) begin
      output_fifo_tdata <= processed_output_tdata;
      output_fifo_tkeep <= input_fifo_head_tkeep;
      output_fifo_tuser <= input_fifo_head_tuser;
      output_fifo_tlast <= input_fifo_head_tlast;

      bytes_processed_before_current_axi_packet <= bytes_processed_before_current_axi_packet_next;

      write_to_output_queue <= read_from_input_queue;
  end

endmodule

module image_processor
#(parameter TDATA_WIDTH = 256)
(
  input  [TDATA_WIDTH - 1:0]         data_in,
  input  [((TDATA_WIDTH / 8)) - 1:0] byte_mask,

  output [TDATA_WIDTH - 1:0]         data_out
);

  // WIRES
  wire [TDATA_WIDTH - 1:0] raw_processed_data;

  wire [TDATA_WIDTH - 1:0] bit_mask;

  wire [TDATA_WIDTH - 1:0] processed_data;
  wire [TDATA_WIDTH - 1:0] unprocessed_data;

  // HERE'S WHERE THE MAGIC HAPPENS!
  assign raw_processed_data = ~data_in; // Dummy operation

  // ONLY PROCESS THE MASKED BYTES
  byte_to_bit_mask bit_mask_generator
  (
    .byte_mask(byte_mask),
    .bit_mask(bit_mask)
  );

  assign processed_data   = raw_processed_data & bit_mask;
  assign unprocessed_data = data_in & ~bit_mask;

  // RETURN
  assign data_out = processed_data | unprocessed_data;

endmodule

module byte_to_bit_mask
#(parameter BYTE_MASK_WIDTH = 32)
(
  input [BYTE_MASK_WIDTH - 1:0] byte_mask,
  output reg [(BYTE_MASK_WIDTH * 8) - 1:0] bit_mask
);
  integer i;
  
  always @(*) begin
    for (i = 0; i < BYTE_MASK_WIDTH; i = i + 1) begin
      bit_mask[i*8 +: 8] = {8{byte_mask[i]}};
    end
  end
endmodule
