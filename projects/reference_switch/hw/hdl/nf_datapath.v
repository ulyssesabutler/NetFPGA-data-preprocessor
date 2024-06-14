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


module nf_datapath
#(
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
    if (write_to_input_queue) begin
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
  |* PACKET PROCESSOR (NEW!!!!)
  |* ================
  |* Once we're in a packet processing state, mutate the data as we move it from the input queue to
  |* the output queue.
  \*************************************************************************************************/

  /*************************************************************************************************\
  |* BODY PROCESSOR
  \*************************************************************************************************/
  
  // Queue variables
  reg  [TDATA_WIDTH - 1:0]         body_processor_input_queue_head_tdata;
  reg  [((TDATA_WIDTH / 8)) - 1:0] body_processor_input_queue_head_tkeep;
  reg  [TUSER_WIDTH-1:0]           body_processor_input_queue_head_tuser;
  reg                              body_processor_input_queue_head_tlast;

  reg                              write_to_body_processor_input_queue;
  wire                             read_from_body_processor_input_queue;

  wire                             body_processor_input_queue_nearly_full;
  wire                             body_processor_input_queue_empty;

  // Image scaler interface
  wire [TDATA_WIDTH - 1:0]         image_body_unprocessed_tdata;
  wire [((TDATA_WIDTH / 8)) - 1:0] image_body_unprocessed_tkeep;
  wire [TUSER_WIDTH-1:0]           image_body_unprocessed_tuser;
  wire                             image_body_unprocessed_tvalid;
  wire                             image_body_unprocessed_tready;
  wire                             image_body_unprocessed_tlast;

  wire [TDATA_WIDTH - 1:0]         image_body_processed_tdata;
  wire [((TDATA_WIDTH / 8)) - 1:0] image_body_processed_tkeep;
  wire [TUSER_WIDTH-1:0]           image_body_processed_tuser;
  wire                             image_body_processed_tvalid;
  wire                             image_body_processed_tready;
  wire                             image_body_processed_tlast;

  fallthrough_small_fifo
  #(
    .WIDTH(TDATA_WIDTH+TUSER_WIDTH+TDATA_WIDTH/8+1), // Fit the whole AXIS packet
    .MAX_DEPTH_BITS(4)
  )
  body_processor_input_queue
  (
    .din         ({body_processor_input_queue_head_tdata, body_processor_input_queue_head_tkeep, body_processor_input_queue_head_tuser, body_processor_input_queue_head_tlast}),
    .wr_en       (write_to_body_processor_input_queue),
    .rd_en       (read_from_body_processor_input_queue),
    .dout        ({image_body_unprocessed_tdata, image_body_unprocessed_tkeep, image_body_unprocessed_tuser, image_body_unprocessed_tlast}),
    .full        (),
    .prog_full   (),
    .nearly_full (body_processor_input_queue_nearly_full),
    .empty       (body_processor_input_queue_empty),
    .reset       (~axis_resetn),
    .clk         (axis_aclk)
  );

  assign read_from_body_processor_input_queue = image_body_unprocessed_tready & image_body_unprocessed_tvalid;
  assign image_body_unprocessed_tvalid = ~body_processor_input_queue_empty;

  image_to_tensor_scaler image_body_scaler
  (
    .axis_aclk(axis_aclk),
    .axis_resetn(axis_resetn),

    .axis_image_tdata(image_body_unprocessed_tdata),
    .axis_image_tkeep(image_body_unprocessed_tkeep),
    .axis_image_tuser(image_body_unprocessed_tuser),
    .axis_image_tvalid(image_body_unprocessed_tvalid),
    .axis_image_tready(image_body_unprocessed_tready),
    .axis_image_tlast(image_body_unprocessed_tlast),

    .axis_tensor_tdata(image_body_processed_tdata),
    .axis_tensor_tkeep(image_body_processed_tkeep),
    .axis_tensor_tuser(image_body_processed_tuser),
    .axis_tensor_tvalid(image_body_processed_tvalid),
    .axis_tensor_tready(image_body_processed_tready),
    .axis_tensor_tlast(image_body_processed_tlast)
  );

  /*************************************************************************************************\
  |* HEADER EXTRACTOR
  \*************************************************************************************************/

  // Packet Processing Timing Control
  assign read_from_input_queue = ~input_fifo_empty & ~output_fifo_nearly_full & ~body_processor_input_queue_nearly_full & (state == STATE_PACKET_PROCESSING);

  // Processed bytes tracking
  reg [31:0] bytes_processed_before_current_axi_packet;
  reg [31:0] bytes_processed_after_current_axi_packet;

  // Header tracker
  wire does_current_axi_packet_contain_header = ~has_header_been_written_to_output_queue;
  
  reg  has_header_been_written_to_output_queue;
  reg  has_header_been_written_to_output_queue_next;
  
  wire [31:0] header_byte_count = body_offset - bytes_processed_before_current_axi_packet;

  // Body Tracker
  wire does_current_axi_packet_contain_body = bytes_processed_after_current_axi_packet > body_offset;

  // Output tracker
  reg writing_header_to_output_queue;
  reg writing_body_to_processor_queue;
  reg writing_processor_to_output_queue;

  wire write_to_output_queue_next = writing_header_to_output_queue | writing_processor_to_output_queue;
  wire write_to_body_processor_input_queue_next = writing_body_to_processor_queue;

  // Queue next
  reg [TDATA_WIDTH - 1:0]          output_fifo_tdata_next;
  reg [((TDATA_WIDTH / 8)) - 1:0]  output_fifo_tkeep_next;
  reg [TUSER_WIDTH-1:0]            output_fifo_tuser_next;
  reg                              output_fifo_tlast_next;

  reg  [TDATA_WIDTH - 1:0]         body_processor_input_queue_head_tdata_next;
  reg  [((TDATA_WIDTH / 8)) - 1:0] body_processor_input_queue_head_tkeep_next;
  reg  [TUSER_WIDTH-1:0]           body_processor_input_queue_head_tuser_next;
  reg                              body_processor_input_queue_head_tlast_next;

  // Logic
  assign image_body_processed_tready = ~output_fifo_nearly_full & has_header_been_written_to_output_queue;

  always @(*) begin
    // Default values
    bytes_processed_after_current_axi_packet     = bytes_processed_before_current_axi_packet;
    has_header_been_written_to_output_queue_next = has_header_been_written_to_output_queue;

    output_fifo_tdata_next = 0;
    output_fifo_tkeep_next = 0;
    output_fifo_tuser_next = 0;
    output_fifo_tlast_next = 0;

    body_processor_input_queue_head_tdata_next = 0;
    body_processor_input_queue_head_tkeep_next = 0;
    body_processor_input_queue_head_tuser_next = 0;
    body_processor_input_queue_head_tlast_next = 0;

    writing_header_to_output_queue    = 0;
    writing_body_to_processor_queue   = 0;
    writing_processor_to_output_queue = 0;

    finished_packet_processing = 0;

    case (state)

      STATE_INFO_COLLECTION: begin
        // If we're in the info collection state, we haven't processed any AXI packets, so make sure this is reset.
        bytes_processed_after_current_axi_packet = 0;
        has_header_been_written_to_output_queue_next = 0;
      end

      STATE_PACKET_PROCESSING: begin
        if (read_from_input_queue) begin
          // TODO: Replace with population could of TKEEP
          bytes_processed_after_current_axi_packet = bytes_processed_before_current_axi_packet + 32;

          if (does_current_axi_packet_contain_header) begin // Write the header directly to the queue
            if (bytes_processed_after_current_axi_packet <= body_offset) begin // This entire packet is part of the header
              output_fifo_tdata_next = input_fifo_head_tdata;
              output_fifo_tkeep_next = input_fifo_head_tkeep;
              output_fifo_tuser_next = input_fifo_head_tuser;
              output_fifo_tlast_next = 0;
            end else begin // Only part of the current packet is a part of the header
              output_fifo_tdata_next = input_fifo_head_tdata & ((1 << (header_byte_count * 8)) - 1);
              output_fifo_tkeep_next = input_fifo_head_tkeep & ((1 << header_byte_count) - 1);
              output_fifo_tuser_next = input_fifo_head_tuser;
              output_fifo_tlast_next = 0;

              has_header_been_written_to_output_queue_next = 1;
            end

            writing_header_to_output_queue = 1;
          end

          if (does_current_axi_packet_contain_body) begin
            if (bytes_processed_before_current_axi_packet >= body_offset) begin // The entire packet is body
              body_processor_input_queue_head_tdata_next = input_fifo_head_tdata;
              body_processor_input_queue_head_tkeep_next = input_fifo_head_tkeep;
              body_processor_input_queue_head_tuser_next = input_fifo_head_tuser;
              body_processor_input_queue_head_tlast_next = input_fifo_head_tlast;
            end else begin // Only part of the current packet is part of the header
              body_processor_input_queue_head_tdata_next = input_fifo_head_tdata >> (header_byte_count * 8);
              body_processor_input_queue_head_tkeep_next = input_fifo_head_tkeep >> header_byte_count;
              body_processor_input_queue_head_tuser_next = input_fifo_head_tuser;
              body_processor_input_queue_head_tlast_next = input_fifo_head_tlast;
            end

            writing_body_to_processor_queue = 1;
          end
        end

        if (image_body_processed_tready & image_body_processed_tvalid) begin
          output_fifo_tdata_next = image_body_processed_tdata;
          output_fifo_tkeep_next = image_body_processed_tkeep;
          output_fifo_tuser_next = image_body_processed_tuser;
          output_fifo_tlast_next = image_body_processed_tlast;

          finished_packet_processing = image_body_processed_tlast;

          writing_processor_to_output_queue = 1;
        end
      end

    endcase
  end

  always @(posedge axis_aclk) begin
    bytes_processed_before_current_axi_packet <= bytes_processed_after_current_axi_packet;
    has_header_been_written_to_output_queue   <= has_header_been_written_to_output_queue_next;

    output_fifo_tdata <= output_fifo_tdata_next;
    output_fifo_tkeep <= output_fifo_tkeep_next;
    output_fifo_tuser <= output_fifo_tuser_next;
    output_fifo_tlast <= output_fifo_tlast_next;

    body_processor_input_queue_head_tdata <= body_processor_input_queue_head_tdata_next;
    body_processor_input_queue_head_tkeep <= body_processor_input_queue_head_tkeep_next;
    body_processor_input_queue_head_tuser <= body_processor_input_queue_head_tuser_next;
    body_processor_input_queue_head_tlast <= body_processor_input_queue_head_tlast_next;

    write_to_output_queue               <= write_to_output_queue_next;
    write_to_body_processor_input_queue <= write_to_body_processor_input_queue_next;
  end

endmodule

/*************************************************************************************************\
|* SCALING
|* =======
|* Part of toTensor() is to map the pixel intensity values (from 0 to 255) to a percentage
|* (0 to 1). For our purposes, this essentially means converting an 8-bit int to a float.
\*************************************************************************************************/

module image_to_tensor_scaler
#(
  // AXI Stream Data Width
  parameter TDATA_WIDTH        = 256,
  parameter TUSER_WIDTH        = 128,
  
  localparam SMALL_TDATA_WIDTH = TDATA_WIDTH / 4
)
(
  // Global Ports
  input                              axis_aclk,
  input                              axis_resetn,

  input  [TDATA_WIDTH - 1:0]         axis_image_tdata,
  input  [((TDATA_WIDTH / 8)) - 1:0] axis_image_tkeep,
  input  [TUSER_WIDTH-1:0]           axis_image_tuser,
  input                              axis_image_tvalid,
  output                             axis_image_tready,
  input                              axis_image_tlast,

  output [TDATA_WIDTH - 1:0]         axis_tensor_tdata,
  output [((TDATA_WIDTH / 8)) - 1:0] axis_tensor_tkeep,
  output [TUSER_WIDTH-1:0]           axis_tensor_tuser,
  output                             axis_tensor_tvalid,
  input                              axis_tensor_tready,
  output                             axis_tensor_tlast
);

  // Internal Connectivity
  wire [SMALL_TDATA_WIDTH - 1:0]         axis_smaller_tdata;
  wire [((SMALL_TDATA_WIDTH / 8)) - 1:0] axis_smaller_tkeep;
  wire [TUSER_WIDTH - 1:0]               axis_smaller_tuser;
  wire                                   axis_smaller_tvalid;
  wire                                   axis_smaller_tready;
  wire                                   axis_smaller_tlast;

  axis_data_width_converter data_width_shrinker
  (
    .axis_aclk(axis_aclk),
    .axis_resetn(axis_resetn),

    .axis_original_tdata(axis_image_tdata),
    .axis_original_tkeep(axis_image_tkeep),
    .axis_original_tuser(axis_image_tuser),
    .axis_original_tvalid(axis_image_tvalid),
    .axis_original_tready(axis_image_tready),
    .axis_original_tlast(axis_image_tlast),

    .axis_resize_tdata(axis_smaller_tdata),
    .axis_resize_tkeep(axis_smaller_tkeep),
    .axis_resize_tuser(axis_smaller_tuser),
    .axis_resize_tvalid(axis_smaller_tvalid),
    .axis_resize_tready(axis_smaller_tready),
    .axis_resize_tlast(axis_smaller_tlast)
  );

  small_axis_image_to_tensor_scaler scaler
  (
    .axis_aclk(axis_aclk),
    .axis_resetn(axis_resetn),

    .axis_image_tdata(axis_smaller_tdata),
    .axis_image_tkeep(axis_smaller_tkeep),
    .axis_image_tuser(axis_smaller_tuser),
    .axis_image_tvalid(axis_smaller_tvalid),
    .axis_image_tready(axis_smaller_tready),
    .axis_image_tlast(axis_smaller_tlast),

    .axis_tensor_tdata(axis_tensor_tdata),
    .axis_tensor_tkeep(axis_tensor_tkeep),
    .axis_tensor_tuser(axis_tensor_tuser),
    .axis_tensor_tvalid(axis_tensor_tvalid),
    .axis_tensor_tready(axis_tensor_tready),
    .axis_tensor_tlast(axis_tensor_tlast)
  );

endmodule

module small_axis_image_to_tensor_scaler
#(
  // AXI Stream Data Width
  parameter TDATA_WIDTH        = 256,
  parameter TUSER_WIDTH        = 128,

  localparam SMALL_TDATA_WIDTH = TDATA_WIDTH / 4
)
(
  // Global Ports
  input                              axis_aclk,
  input                              axis_resetn,

  // Master Stream Ports (The output of this module)
  input  [SMALL_TDATA_WIDTH - 1:0]         axis_image_tdata,
  input  [((SMALL_TDATA_WIDTH / 8)) - 1:0] axis_image_tkeep,
  input  [TUSER_WIDTH - 1:0]               axis_image_tuser,
  input                                    axis_image_tvalid,
  output                                   axis_image_tready,
  input                                    axis_image_tlast,

  // Slave Stream Ports (The input of this module)
  output [TDATA_WIDTH - 1:0]               axis_tensor_tdata,
  output [((TDATA_WIDTH / 8)) - 1:0]       axis_tensor_tkeep,
  output [TUSER_WIDTH-1:0]                 axis_tensor_tuser,
  output                                   axis_tensor_tvalid,
  input                                    axis_tensor_tready,
  output                                   axis_tensor_tlast
);

  genvar i;

  generate
    for (i = 0; i < SMALL_TDATA_WIDTH; i = i + 8) begin
      uint8_to_float32 scaling_lookup_table
      (
        .uint8(axis_image_tdata[i + 7:i]),
        .float32(axis_tensor_tdata[4*i + 31:4*i]),
        .axis_aclk(axis_aclk),
        .axis_resetn(axis_resetn)
      );
    end
  endgenerate
    
  genvar j;
  
  generate
    for (i = 0; i < (SMALL_TDATA_WIDTH / 8); i = i + 1) begin
      assign axis_tensor_tkeep[4*i+3:4*i] = {4{axis_image_tkeep[i]}};
    end
  endgenerate

  assign axis_tensor_tuser  = axis_image_tuser;
  assign axis_tensor_tvalid = axis_image_tvalid;
  assign axis_image_tready  = axis_tensor_tready;
  assign axis_tensor_tlast  = axis_image_tlast;

endmodule

module axis_data_width_converter
#(
  // AXI Stream Data Width
  parameter IN_TDATA_WIDTH  = 256,
  parameter OUT_TDATA_WIDTH = IN_TDATA_WIDTH / 4,
  parameter TUSER_WIDTH     = 128,

  localparam BUFFER_WIDTH   = IN_TDATA_WIDTH + OUT_TDATA_WIDTH
)
(
  // Global Ports
  input                                  axis_aclk,
  input                                  axis_resetn,

  input  [IN_TDATA_WIDTH - 1:0]          axis_original_tdata,
  input  [((IN_TDATA_WIDTH / 8)) - 1:0]  axis_original_tkeep,
  input  [TUSER_WIDTH-1:0]               axis_original_tuser,
  input                                  axis_original_tvalid,
  output                                 axis_original_tready,
  input                                  axis_original_tlast,

  output [OUT_TDATA_WIDTH - 1:0]         axis_resize_tdata,
  output [((OUT_TDATA_WIDTH / 8)) - 1:0] axis_resize_tkeep,
  output [TUSER_WIDTH - 1:0]             axis_resize_tuser,
  output                                 axis_resize_tvalid,
  input                                  axis_resize_tready,
  output                                 axis_resize_tlast
);
  // Statefull Buffer: Latched at the end of every clock cycle
  reg [BUFFER_WIDTH - 1:0]               input_buffer_data;
  reg [(BUFFER_WIDTH / 8) - 1:0]         input_buffer_keep;
  reg [TUSER_WIDTH - 1:0]                input_buffer_user;
  reg                                    input_buffer_last;
 
  reg [OUT_TDATA_WIDTH - 1:0]            output_buffer_data;
  reg [(OUT_TDATA_WIDTH / 8) - 1:0]      output_buffer_keep;
  reg [TUSER_WIDTH - 1:0]                output_buffer_user;
  reg                                    output_buffer_last;
  
  reg                                    write_to_output_queue;

  fallthrough_small_fifo
  #(
    .WIDTH(OUT_TDATA_WIDTH+TUSER_WIDTH+OUT_TDATA_WIDTH/8+1), // Fit the whole AXIS packet and the headers
    .MAX_DEPTH_BITS(4)
  )
  output_fifo
  (
    .din         ({output_buffer_data, output_buffer_keep, output_buffer_user, output_buffer_last}), // Pass the packet heads as input directly to the queue
    .wr_en       (write_to_output_queue), // Write enable
    .rd_en       (send_from_module), // Read enabled
    .dout        ({axis_resize_tdata, axis_resize_tkeep, axis_resize_tuser, axis_resize_tlast}), // Return TLAST, TKEEP, and TUSER directly to the next stage. Write TDATA to a wire for processing
    .full        (),
    .prog_full   (),
    .nearly_full (output_fifo_nearly_full),
    .empty       (output_fifo_empty),
    .reset       (~axis_resetn),
    .clk         (axis_aclk)
  );

  assign send_from_module   = axis_resize_tvalid & axis_resize_tready;
  assign axis_resize_tvalid = ~output_fifo_empty;

  // Step 1: Move data from input to input buffer
  wire                                   should_write_to_input_buffer;

  wire [BUFFER_WIDTH - 1:0]              input_buffer_data_after_write;
  wire [(BUFFER_WIDTH / 8) - 1:0]        input_buffer_keep_after_write;

  reg  [BUFFER_WIDTH - 1:0]              input_buffer_data_after_writing_step;
  reg  [(BUFFER_WIDTH / 8) - 1:0]        input_buffer_keep_after_writing_step;
  reg  [TUSER_WIDTH - 1:0]               input_buffer_user_after_writing_step;
  reg                                    input_buffer_last_after_writing_step;

  copy_into_empty
  #(
    .SRC_DATA_WIDTH(IN_TDATA_WIDTH),
    .DEST_DATA_WIDTH(BUFFER_WIDTH)
  )
  copy_from_input_to_buffer
  (
    .src_data_in(axis_original_tdata), // TODO: FROM QUEUE
    .src_keep_in(axis_original_tkeep), // TODO: FROM QUEUE

    .dest_data_in(input_buffer_data),
    .dest_keep_in(input_buffer_keep),

    .dest_data_out(input_buffer_data_after_write),
    .dest_keep_out(input_buffer_keep_after_write)
  );

  assign should_write_to_input_buffer = axis_original_tready & axis_original_tvalid;
  assign axis_original_tready = ~input_buffer_keep[OUT_TDATA_WIDTH / 8];

  always @(*) begin
    input_buffer_data_after_writing_step = input_buffer_data;
    input_buffer_keep_after_writing_step = input_buffer_keep;
    input_buffer_user_after_writing_step = input_buffer_user;
    input_buffer_last_after_writing_step = input_buffer_last;

    if (should_write_to_input_buffer) begin
      input_buffer_data_after_writing_step = input_buffer_data_after_write;
      input_buffer_keep_after_writing_step = input_buffer_keep_after_write;
      input_buffer_user_after_writing_step = axis_original_tuser;
      input_buffer_last_after_writing_step = axis_original_tlast;
    end
  end

  // Step 2: Move data from input buffer to output buffer
  wire [BUFFER_WIDTH - 1:0]              input_buffer_data_after_read;
  wire [(BUFFER_WIDTH / 8) - 1:0]        input_buffer_keep_after_read;


  reg  [BUFFER_WIDTH - 1:0]              input_buffer_data_after_reading_step;
  reg  [(BUFFER_WIDTH / 8) - 1:0]        input_buffer_keep_after_reading_step;
  reg  [TUSER_WIDTH - 1:0]               input_buffer_user_after_reading_step;
  reg                                    input_buffer_last_after_reading_step;

  wire [OUT_TDATA_WIDTH - 1:0]           output_buffer_data_after_write;
  wire [(OUT_TDATA_WIDTH / 8) - 1:0]     output_buffer_keep_after_write;

  reg  [OUT_TDATA_WIDTH - 1:0]           output_buffer_data_after_writing_step;
  reg  [(OUT_TDATA_WIDTH / 8) - 1:0]     output_buffer_keep_after_writing_step;
  reg  [TUSER_WIDTH - 1:0]               output_buffer_user_after_writing_step;
  reg                                    output_buffer_last_after_writing_step;
  
  wire                                   will_input_buffer_be_empty          = ~|input_buffer_keep_after_read;
  wire                                   will_current_network_packet_be_read = will_input_buffer_be_empty & input_buffer_last;
  wire                                   should_write_to_output_buffer       = ((&output_buffer_keep_after_write) | will_current_network_packet_be_read) & ~output_fifo_nearly_full; // This fills the output buffer or empties the input buffer

  copy_into_empty 
  #(
    .SRC_DATA_WIDTH(BUFFER_WIDTH),
    .DEST_DATA_WIDTH(OUT_TDATA_WIDTH)
  )
  copy_from_buffer_to_output
  (
    .src_data_in(input_buffer_data_after_writing_step),
    .src_keep_in(input_buffer_keep_after_writing_step),

    .dest_data_in(0),
    .dest_keep_in(0),

    .src_data_out(input_buffer_data_after_read),
    .src_keep_out(input_buffer_keep_after_read),

    .dest_data_out(output_buffer_data_after_write),
    .dest_keep_out(output_buffer_keep_after_write)
  );

  always @(*) begin
    input_buffer_data_after_reading_step = input_buffer_data_after_writing_step;
    input_buffer_keep_after_reading_step = input_buffer_keep_after_writing_step;
    input_buffer_user_after_reading_step = input_buffer_user_after_writing_step;
    input_buffer_last_after_reading_step = input_buffer_last_after_writing_step;

    output_buffer_data_after_writing_step = output_buffer_data;
    output_buffer_keep_after_writing_step = output_buffer_keep;
    output_buffer_user_after_writing_step = output_buffer_user;
    output_buffer_last_after_writing_step = output_buffer_last;

    if (should_write_to_output_buffer) begin
      input_buffer_data_after_reading_step = input_buffer_data_after_read;
      input_buffer_keep_after_reading_step = input_buffer_keep_after_read;

      output_buffer_data_after_writing_step = output_buffer_data_after_write;
      output_buffer_keep_after_writing_step = output_buffer_keep_after_write;

      output_buffer_user_after_writing_step = input_buffer_user_after_writing_step;
      output_buffer_last_after_writing_step = will_current_network_packet_be_read;
    end

    if (will_current_network_packet_be_read) begin // Reset the input buffers
      input_buffer_last_after_reading_step = 0;
    end
  end

  always @(posedge axis_aclk) begin
    if (~axis_resetn) begin
      input_buffer_data     <= 0;
      input_buffer_keep     <= 0;
      input_buffer_user     <= 0;
      input_buffer_last     <= 0;

      output_buffer_data    <= 0;
      output_buffer_keep    <= 0;
      output_buffer_user    <= 0;
      output_buffer_last    <= 0;

      write_to_output_queue <= 0;
    end else begin
      input_buffer_data     <= input_buffer_data_after_reading_step;
      input_buffer_keep     <= input_buffer_keep_after_reading_step;
      input_buffer_user     <= input_buffer_user_after_reading_step;
      input_buffer_last     <= input_buffer_last_after_reading_step;

      output_buffer_data    <= output_buffer_data_after_writing_step;
      output_buffer_keep    <= output_buffer_keep_after_writing_step;
      output_buffer_user    <= output_buffer_user_after_writing_step;
      output_buffer_last    <= output_buffer_last_after_writing_step;

      write_to_output_queue <= should_write_to_output_buffer;
    end
  end

endmodule

/*************************************************************************************************\
|* UTILITY MODULES
|* ===============
|* These modules aren't included in the larger system architecture, but are small, reusable
|* helps we have to build along the way.
\*************************************************************************************************/

module apply_byte_mask
#(parameter TDATA_WIDTH = 256)
(
  input  [TDATA_WIDTH - 1:0]         processed_data_in,
  input  [TDATA_WIDTH - 1:0]         unprocessed_data_in,
  input  [((TDATA_WIDTH / 8)) - 1:0] byte_mask,

  output [TDATA_WIDTH - 1:0]         data_out
);

  wire [TDATA_WIDTH - 1:0] bit_mask;

  wire [TDATA_WIDTH - 1:0] processed_data_masked;
  wire [TDATA_WIDTH - 1:0] unprocessed_data_masked;

  byte_to_bit_mask bit_mask_generator
  (
    .byte_mask(byte_mask),
    .bit_mask(bit_mask)
  );

  assign processed_data_masked   = processed_data_in & bit_mask;
  assign unprocessed_data_masked = unprocessed_data_in & ~bit_mask;

  assign data_out = processed_data_masked | unprocessed_data_masked;

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

module copy_into_empty
#(
  parameter SRC_DATA_WIDTH   = 256,
  parameter DEST_DATA_WIDTH  = 256,
  localparam SRC_KEEP_WIDTH  = SRC_DATA_WIDTH / 8,
  localparam DEST_KEEP_WIDTH = DEST_DATA_WIDTH / 8
)
(
  input  [SRC_DATA_WIDTH - 1:0]  src_data_in,
  input  [SRC_KEEP_WIDTH - 1:0]  src_keep_in,

  input  [DEST_DATA_WIDTH - 1:0]  dest_data_in,
  input  [DEST_KEEP_WIDTH - 1:0]  dest_keep_in,

  output [SRC_DATA_WIDTH - 1:0] src_data_out,
  output [SRC_KEEP_WIDTH - 1:0] src_keep_out,

  output [DEST_DATA_WIDTH - 1:0] dest_data_out,
  output [DEST_KEEP_WIDTH - 1:0] dest_keep_out
);

  wire    [31:0] first_non_empty_in_dest_data_out;
  wire    [31:0] first_non_empty_in_dest_keep_out;

  first_null_index
  #(
    .DATA_WIDTH(DEST_KEEP_WIDTH)
  )
  first_non_empty_in_dest_keep_out_calc
  (
    .data(dest_keep_in),
    .index(first_non_empty_in_dest_keep_out)
  );
  assign first_non_empty_in_dest_data_out = first_non_empty_in_dest_keep_out * 8;

  assign dest_data_out = (src_data_in << first_non_empty_in_dest_data_out) | dest_data_in;
  assign dest_keep_out = (src_keep_in << first_non_empty_in_dest_keep_out) | dest_keep_in;

  assign src_data_out  = src_data_in >> (DEST_DATA_WIDTH - first_non_empty_in_dest_data_out);
  assign src_keep_out  = src_keep_in >> (DEST_KEEP_WIDTH - first_non_empty_in_dest_keep_out);

endmodule

module first_null_index
#(parameter DATA_WIDTH = 32)
(
  input      [DATA_WIDTH - 1:0] data,
  output reg [31:0]             index
);

  reg signed [31:0] i;
  reg               found_non_null_index;

  always @(*) begin
    found_non_null_index = 0;
    index                = DATA_WIDTH;
    
    for (i = DATA_WIDTH - 1; i >= 0; i = i - 1) begin
      if (data[i])
        found_non_null_index = 1;
      else if (~found_non_null_index)
        index = i;
    end
  end

endmodule

module uint8_to_float32
(
  input      [7:0]  uint8,
  output reg [31:0] float32,

  input             axis_aclk,
  input             axis_resetn
);

  reg [31:0] float_table [0:255];

  always @(uint8) begin
    float32 = float_table[uint8];
  end

  always @(posedge axis_aclk) begin
    /*
    import struct

    def float_to_hex(f):
        return struct.unpack('<I', struct.pack('<f', f))[0]

    for i in range(256):
        f = i / 255.0
        hex_value = float_to_hex(f)
        print(f"float_table[{i}] = 32'h{hex_value:08x}; // {f}")
    */
    if (~axis_resetn) begin
      float_table[0]   = 32'h00000000; // 0.0
      float_table[1]   = 32'h3b808081; // 0.00392156862745098
      float_table[2]   = 32'h3c008081; // 0.00784313725490196
      float_table[3]   = 32'h3c40c0c1; // 0.011764705882352941
      float_table[4]   = 32'h3c808081; // 0.01568627450980392
      float_table[5]   = 32'h3ca0a0a1; // 0.0196078431372549
      float_table[6]   = 32'h3cc0c0c1; // 0.023529411764705882
      float_table[7]   = 32'h3ce0e0e1; // 0.027450980392156862
      float_table[8]   = 32'h3d008081; // 0.03137254901960784
      float_table[9]   = 32'h3d109091; // 0.03529411764705882
      float_table[10]  = 32'h3d20a0a1; // 0.0392156862745098
      float_table[11]  = 32'h3d30b0b1; // 0.043137254901960784
      float_table[12]  = 32'h3d40c0c1; // 0.047058823529411764
      float_table[13]  = 32'h3d50d0d1; // 0.050980392156862744
      float_table[14]  = 32'h3d60e0e1; // 0.054901960784313725
      float_table[15]  = 32'h3d70f0f1; // 0.058823529411764705
      float_table[16]  = 32'h3d808081; // 0.06274509803921569
      float_table[17]  = 32'h3d888889; // 0.06666666666666667
      float_table[18]  = 32'h3d909091; // 0.07058823529411765
      float_table[19]  = 32'h3d989899; // 0.07450980392156863
      float_table[20]  = 32'h3da0a0a1; // 0.0784313725490196
      float_table[21]  = 32'h3da8a8a9; // 0.08235294117647059
      float_table[22]  = 32'h3db0b0b1; // 0.08627450980392157
      float_table[23]  = 32'h3db8b8b9; // 0.09019607843137255
      float_table[24]  = 32'h3dc0c0c1; // 0.09411764705882353
      float_table[25]  = 32'h3dc8c8c9; // 0.09803921568627451
      float_table[26]  = 32'h3dd0d0d1; // 0.10196078431372549
      float_table[27]  = 32'h3dd8d8d9; // 0.10588235294117647
      float_table[28]  = 32'h3de0e0e1; // 0.10980392156862745
      float_table[29]  = 32'h3de8e8e9; // 0.11372549019607843
      float_table[30]  = 32'h3df0f0f1; // 0.11764705882352941
      float_table[31]  = 32'h3df8f8f9; // 0.12156862745098039
      float_table[32]  = 32'h3e008081; // 0.12549019607843137
      float_table[33]  = 32'h3e048485; // 0.12941176470588237
      float_table[34]  = 32'h3e088889; // 0.13333333333333333
      float_table[35]  = 32'h3e0c8c8d; // 0.13725490196078433
      float_table[36]  = 32'h3e109091; // 0.1411764705882353
      float_table[37]  = 32'h3e149495; // 0.1450980392156863
      float_table[38]  = 32'h3e189899; // 0.14901960784313725
      float_table[39]  = 32'h3e1c9c9d; // 0.15294117647058825
      float_table[40]  = 32'h3e20a0a1; // 0.1568627450980392
      float_table[41]  = 32'h3e24a4a5; // 0.1607843137254902
      float_table[42]  = 32'h3e28a8a9; // 0.16470588235294117
      float_table[43]  = 32'h3e2cacad; // 0.16862745098039217
      float_table[44]  = 32'h3e30b0b1; // 0.17254901960784313
      float_table[45]  = 32'h3e34b4b5; // 0.17647058823529413
      float_table[46]  = 32'h3e38b8b9; // 0.1803921568627451
      float_table[47]  = 32'h3e3cbcbd; // 0.1843137254901961
      float_table[48]  = 32'h3e40c0c1; // 0.18823529411764706
      float_table[49]  = 32'h3e44c4c5; // 0.19215686274509805
      float_table[50]  = 32'h3e48c8c9; // 0.19607843137254902
      float_table[51]  = 32'h3e4ccccd; // 0.2
      float_table[52]  = 32'h3e50d0d1; // 0.20392156862745098
      float_table[53]  = 32'h3e54d4d5; // 0.20784313725490197
      float_table[54]  = 32'h3e58d8d9; // 0.21176470588235294
      float_table[55]  = 32'h3e5cdcdd; // 0.21568627450980393
      float_table[56]  = 32'h3e60e0e1; // 0.2196078431372549
      float_table[57]  = 32'h3e64e4e5; // 0.2235294117647059
      float_table[58]  = 32'h3e68e8e9; // 0.22745098039215686
      float_table[59]  = 32'h3e6ceced; // 0.23137254901960785
      float_table[60]  = 32'h3e70f0f1; // 0.23529411764705882
      float_table[61]  = 32'h3e74f4f5; // 0.23921568627450981
      float_table[62]  = 32'h3e78f8f9; // 0.24313725490196078
      float_table[63]  = 32'h3e7cfcfd; // 0.24705882352941178
      float_table[64]  = 32'h3e808081; // 0.25098039215686274
      float_table[65]  = 32'h3e828283; // 0.2549019607843137
      float_table[66]  = 32'h3e848485; // 0.25882352941176473
      float_table[67]  = 32'h3e868687; // 0.2627450980392157
      float_table[68]  = 32'h3e888889; // 0.26666666666666666
      float_table[69]  = 32'h3e8a8a8b; // 0.27058823529411763
      float_table[70]  = 32'h3e8c8c8d; // 0.27450980392156865
      float_table[71]  = 32'h3e8e8e8f; // 0.2784313725490196
      float_table[72]  = 32'h3e909091; // 0.2823529411764706
      float_table[73]  = 32'h3e929293; // 0.28627450980392155
      float_table[74]  = 32'h3e949495; // 0.2901960784313726
      float_table[75]  = 32'h3e969697; // 0.29411764705882354
      float_table[76]  = 32'h3e989899; // 0.2980392156862745
      float_table[77]  = 32'h3e9a9a9b; // 0.30196078431372547
      float_table[78]  = 32'h3e9c9c9d; // 0.3058823529411765
      float_table[79]  = 32'h3e9e9e9f; // 0.30980392156862746
      float_table[80]  = 32'h3ea0a0a1; // 0.3137254901960784
      float_table[81]  = 32'h3ea2a2a3; // 0.3176470588235294
      float_table[82]  = 32'h3ea4a4a5; // 0.3215686274509804
      float_table[83]  = 32'h3ea6a6a7; // 0.3254901960784314
      float_table[84]  = 32'h3ea8a8a9; // 0.32941176470588235
      float_table[85]  = 32'h3eaaaaab; // 0.3333333333333333
      float_table[86]  = 32'h3eacacad; // 0.33725490196078434
      float_table[87]  = 32'h3eaeaeaf; // 0.3411764705882353
      float_table[88]  = 32'h3eb0b0b1; // 0.34509803921568627
      float_table[89]  = 32'h3eb2b2b3; // 0.34901960784313724
      float_table[90]  = 32'h3eb4b4b5; // 0.35294117647058826
      float_table[91]  = 32'h3eb6b6b7; // 0.3568627450980392
      float_table[92]  = 32'h3eb8b8b9; // 0.3607843137254902
      float_table[93]  = 32'h3ebababb; // 0.36470588235294116
      float_table[94]  = 32'h3ebcbcbd; // 0.3686274509803922
      float_table[95]  = 32'h3ebebebf; // 0.37254901960784315
      float_table[96]  = 32'h3ec0c0c1; // 0.3764705882352941
      float_table[97]  = 32'h3ec2c2c3; // 0.3803921568627451
      float_table[98]  = 32'h3ec4c4c5; // 0.3843137254901961
      float_table[99]  = 32'h3ec6c6c7; // 0.38823529411764707
      float_table[100] = 32'h3ec8c8c9; // 0.39215686274509803
      float_table[101] = 32'h3ecacacb; // 0.396078431372549
      float_table[102] = 32'h3ecccccd; // 0.4
      float_table[103] = 32'h3ecececf; // 0.403921568627451
      float_table[104] = 32'h3ed0d0d1; // 0.40784313725490196
      float_table[105] = 32'h3ed2d2d3; // 0.4117647058823529
      float_table[106] = 32'h3ed4d4d5; // 0.41568627450980394
      float_table[107] = 32'h3ed6d6d7; // 0.4196078431372549
      float_table[108] = 32'h3ed8d8d9; // 0.4235294117647059
      float_table[109] = 32'h3edadadb; // 0.42745098039215684
      float_table[110] = 32'h3edcdcdd; // 0.43137254901960786
      float_table[111] = 32'h3edededf; // 0.43529411764705883
      float_table[112] = 32'h3ee0e0e1; // 0.4392156862745098
      float_table[113] = 32'h3ee2e2e3; // 0.44313725490196076
      float_table[114] = 32'h3ee4e4e5; // 0.4470588235294118
      float_table[115] = 32'h3ee6e6e7; // 0.45098039215686275
      float_table[116] = 32'h3ee8e8e9; // 0.4549019607843137
      float_table[117] = 32'h3eeaeaeb; // 0.4588235294117647
      float_table[118] = 32'h3eececed; // 0.4627450980392157
      float_table[119] = 32'h3eeeeeef; // 0.4666666666666667
      float_table[120] = 32'h3ef0f0f1; // 0.47058823529411764
      float_table[121] = 32'h3ef2f2f3; // 0.4745098039215686
      float_table[122] = 32'h3ef4f4f5; // 0.47843137254901963
      float_table[123] = 32'h3ef6f6f7; // 0.4823529411764706
      float_table[124] = 32'h3ef8f8f9; // 0.48627450980392156
      float_table[125] = 32'h3efafafb; // 0.49019607843137253
      float_table[126] = 32'h3efcfcfd; // 0.49411764705882355
      float_table[127] = 32'h3efefeff; // 0.4980392156862745
      float_table[128] = 32'h3f008081; // 0.5019607843137255
      float_table[129] = 32'h3f018182; // 0.5058823529411764
      float_table[130] = 32'h3f028283; // 0.5098039215686274
      float_table[131] = 32'h3f038384; // 0.5137254901960784
      float_table[132] = 32'h3f048485; // 0.5176470588235295
      float_table[133] = 32'h3f058586; // 0.5215686274509804
      float_table[134] = 32'h3f068687; // 0.5254901960784314
      float_table[135] = 32'h3f078788; // 0.5294117647058824
      float_table[136] = 32'h3f088889; // 0.5333333333333333
      float_table[137] = 32'h3f09898a; // 0.5372549019607843
      float_table[138] = 32'h3f0a8a8b; // 0.5411764705882353
      float_table[139] = 32'h3f0b8b8c; // 0.5450980392156862
      float_table[140] = 32'h3f0c8c8d; // 0.5490196078431373
      float_table[141] = 32'h3f0d8d8e; // 0.5529411764705883
      float_table[142] = 32'h3f0e8e8f; // 0.5568627450980392
      float_table[143] = 32'h3f0f8f90; // 0.5607843137254902
      float_table[144] = 32'h3f109091; // 0.5647058823529412
      float_table[145] = 32'h3f119192; // 0.5686274509803921
      float_table[146] = 32'h3f129293; // 0.5725490196078431
      float_table[147] = 32'h3f139394; // 0.5764705882352941
      float_table[148] = 32'h3f149495; // 0.5803921568627451
      float_table[149] = 32'h3f159596; // 0.5843137254901961
      float_table[150] = 32'h3f169697; // 0.5882352941176471
      float_table[151] = 32'h3f179798; // 0.592156862745098
      float_table[152] = 32'h3f189899; // 0.596078431372549
      float_table[153] = 32'h3f19999a; // 0.6
      float_table[154] = 32'h3f1a9a9b; // 0.6039215686274509
      float_table[155] = 32'h3f1b9b9c; // 0.6078431372549019
      float_table[156] = 32'h3f1c9c9d; // 0.611764705882353
      float_table[157] = 32'h3f1d9d9e; // 0.615686274509804
      float_table[158] = 32'h3f1e9e9f; // 0.6196078431372549
      float_table[159] = 32'h3f1f9fa0; // 0.6235294117647059
      float_table[160] = 32'h3f20a0a1; // 0.6274509803921569
      float_table[161] = 32'h3f21a1a2; // 0.6313725490196078
      float_table[162] = 32'h3f22a2a3; // 0.6352941176470588
      float_table[163] = 32'h3f23a3a4; // 0.6392156862745098
      float_table[164] = 32'h3f24a4a5; // 0.6431372549019608
      float_table[165] = 32'h3f25a5a6; // 0.6470588235294118
      float_table[166] = 32'h3f26a6a7; // 0.6509803921568628
      float_table[167] = 32'h3f27a7a8; // 0.6549019607843137
      float_table[168] = 32'h3f28a8a9; // 0.6588235294117647
      float_table[169] = 32'h3f29a9aa; // 0.6627450980392157
      float_table[170] = 32'h3f2aaaab; // 0.6666666666666666
      float_table[171] = 32'h3f2babac; // 0.6705882352941176
      float_table[172] = 32'h3f2cacad; // 0.6745098039215687
      float_table[173] = 32'h3f2dadae; // 0.6784313725490196
      float_table[174] = 32'h3f2eaeaf; // 0.6823529411764706
      float_table[175] = 32'h3f2fafb0; // 0.6862745098039216
      float_table[176] = 32'h3f30b0b1; // 0.6901960784313725
      float_table[177] = 32'h3f31b1b2; // 0.6941176470588235
      float_table[178] = 32'h3f32b2b3; // 0.6980392156862745
      float_table[179] = 32'h3f33b3b4; // 0.7019607843137254
      float_table[180] = 32'h3f34b4b5; // 0.7058823529411765
      float_table[181] = 32'h3f35b5b6; // 0.7098039215686275
      float_table[182] = 32'h3f36b6b7; // 0.7137254901960784
      float_table[183] = 32'h3f37b7b8; // 0.7176470588235294
      float_table[184] = 32'h3f38b8b9; // 0.7215686274509804
      float_table[185] = 32'h3f39b9ba; // 0.7254901960784313
      float_table[186] = 32'h3f3ababb; // 0.7294117647058823
      float_table[187] = 32'h3f3bbbbc; // 0.7333333333333333
      float_table[188] = 32'h3f3cbcbd; // 0.7372549019607844
      float_table[189] = 32'h3f3dbdbe; // 0.7411764705882353
      float_table[190] = 32'h3f3ebebf; // 0.7450980392156863
      float_table[191] = 32'h3f3fbfc0; // 0.7490196078431373
      float_table[192] = 32'h3f40c0c1; // 0.7529411764705882
      float_table[193] = 32'h3f41c1c2; // 0.7568627450980392
      float_table[194] = 32'h3f42c2c3; // 0.7607843137254902
      float_table[195] = 32'h3f43c3c4; // 0.7647058823529411
      float_table[196] = 32'h3f44c4c5; // 0.7686274509803922
      float_table[197] = 32'h3f45c5c6; // 0.7725490196078432
      float_table[198] = 32'h3f46c6c7; // 0.7764705882352941
      float_table[199] = 32'h3f47c7c8; // 0.7803921568627451
      float_table[200] = 32'h3f48c8c9; // 0.7843137254901961
      float_table[201] = 32'h3f49c9ca; // 0.788235294117647
      float_table[202] = 32'h3f4acacb; // 0.792156862745098
      float_table[203] = 32'h3f4bcbcc; // 0.796078431372549
      float_table[204] = 32'h3f4ccccd; // 0.8
      float_table[205] = 32'h3f4dcdce; // 0.803921568627451
      float_table[206] = 32'h3f4ececf; // 0.807843137254902
      float_table[207] = 32'h3f4fcfd0; // 0.8117647058823529
      float_table[208] = 32'h3f50d0d1; // 0.8156862745098039
      float_table[209] = 32'h3f51d1d2; // 0.8196078431372549
      float_table[210] = 32'h3f52d2d3; // 0.8235294117647058
      float_table[211] = 32'h3f53d3d4; // 0.8274509803921568
      float_table[212] = 32'h3f54d4d5; // 0.8313725490196079
      float_table[213] = 32'h3f55d5d6; // 0.8352941176470589
      float_table[214] = 32'h3f56d6d7; // 0.8392156862745098
      float_table[215] = 32'h3f57d7d8; // 0.8431372549019608
      float_table[216] = 32'h3f58d8d9; // 0.8470588235294118
      float_table[217] = 32'h3f59d9da; // 0.8509803921568627
      float_table[218] = 32'h3f5adadb; // 0.8549019607843137
      float_table[219] = 32'h3f5bdbdc; // 0.8588235294117647
      float_table[220] = 32'h3f5cdcdd; // 0.8627450980392157
      float_table[221] = 32'h3f5dddde; // 0.8666666666666667
      float_table[222] = 32'h3f5ededf; // 0.8705882352941177
      float_table[223] = 32'h3f5fdfe0; // 0.8745098039215686
      float_table[224] = 32'h3f60e0e1; // 0.8784313725490196
      float_table[225] = 32'h3f61e1e2; // 0.8823529411764706
      float_table[226] = 32'h3f62e2e3; // 0.8862745098039215
      float_table[227] = 32'h3f63e3e4; // 0.8901960784313725
      float_table[228] = 32'h3f64e4e5; // 0.8941176470588236
      float_table[229] = 32'h3f65e5e6; // 0.8980392156862745
      float_table[230] = 32'h3f66e6e7; // 0.9019607843137255
      float_table[231] = 32'h3f67e7e8; // 0.9058823529411765
      float_table[232] = 32'h3f68e8e9; // 0.9098039215686274
      float_table[233] = 32'h3f69e9ea; // 0.9137254901960784
      float_table[234] = 32'h3f6aeaeb; // 0.9176470588235294
      float_table[235] = 32'h3f6bebec; // 0.9215686274509803
      float_table[236] = 32'h3f6ceced; // 0.9254901960784314
      float_table[237] = 32'h3f6dedee; // 0.9294117647058824
      float_table[238] = 32'h3f6eeeef; // 0.9333333333333333
      float_table[239] = 32'h3f6feff0; // 0.9372549019607843
      float_table[240] = 32'h3f70f0f1; // 0.9411764705882353
      float_table[241] = 32'h3f71f1f2; // 0.9450980392156862
      float_table[242] = 32'h3f72f2f3; // 0.9490196078431372
      float_table[243] = 32'h3f73f3f4; // 0.9529411764705882
      float_table[244] = 32'h3f74f4f5; // 0.9568627450980393
      float_table[245] = 32'h3f75f5f6; // 0.9607843137254902
      float_table[246] = 32'h3f76f6f7; // 0.9647058823529412
      float_table[247] = 32'h3f77f7f8; // 0.9686274509803922
      float_table[248] = 32'h3f78f8f9; // 0.9725490196078431
      float_table[249] = 32'h3f79f9fa; // 0.9764705882352941
      float_table[250] = 32'h3f7afafb; // 0.9803921568627451
      float_table[251] = 32'h3f7bfbfc; // 0.984313725490196
      float_table[252] = 32'h3f7cfcfd; // 0.9882352941176471
      float_table[253] = 32'h3f7dfdfe; // 0.9921568627450981
      float_table[254] = 32'h3f7efeff; // 0.996078431372549
      float_table[255] = 32'h3f800000; // 1.0
    end
  end

endmodule
