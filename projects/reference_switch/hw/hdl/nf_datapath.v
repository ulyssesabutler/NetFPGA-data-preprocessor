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
  parameter IP_HDR_SIZE_BYTES  = 20,

  localparam SMALL_TDATA_WIDTH = TDATA_WIDTH / 4
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

  wire [SMALL_TDATA_WIDTH - 1:0]         small_axis_tdata;
  wire [((SMALL_TDATA_WIDTH / 8)) - 1:0] small_axis_tkeep;
  wire [TUSER_WIDTH-1:0]                 small_axis_tuser;
  wire                                   small_axis_tvalid;
  wire                                   small_axis_tready;
  wire                                   small_axis_tlast;

  axis_data_width_converter
  #(
    .IN_TDATA_WIDTH(TDATA_WIDTH),
    .OUT_TDATA_WIDTH(SMALL_TDATA_WIDTH),
    .TUSER_WIDTH(TUSER_WIDTH)
  )
  shrinker
  (
    .axis_aclk(axis_aclk),
    .axis_resetn(axis_resetn),

    .axis_original_tdata(s_axis_tdata),
    .axis_original_tkeep(s_axis_tkeep),
    .axis_original_tuser(s_axis_tuser),
    .axis_original_tvalid(s_axis_tvalid),
    .axis_original_tready(s_axis_tready),
    .axis_original_tlast(s_axis_tlast),

    .axis_resize_tdata(small_axis_tdata),
    .axis_resize_tkeep(small_axis_tkeep),
    .axis_resize_tuser(small_axis_tuser),
    .axis_resize_tvalid(small_axis_tvalid),
    .axis_resize_tready(small_axis_tready),
    .axis_resize_tlast(small_axis_tlast)
  );

  axis_data_width_converter
  #(
    .IN_TDATA_WIDTH(SMALL_TDATA_WIDTH),
    .OUT_TDATA_WIDTH(TDATA_WIDTH),
    .TUSER_WIDTH(TUSER_WIDTH)
  )
  expander
  (
    .axis_aclk(axis_aclk),
    .axis_resetn(axis_resetn),

    .axis_original_tdata(small_axis_tdata),
    .axis_original_tkeep(small_axis_tkeep),
    .axis_original_tuser(small_axis_tuser),
    .axis_original_tvalid(small_axis_tvalid),
    .axis_original_tready(small_axis_tready),
    .axis_original_tlast(small_axis_tlast),

    .axis_resize_tdata(m_axis_tdata),
    .axis_resize_tkeep(m_axis_tkeep),
    .axis_resize_tuser(m_axis_tuser),
    .axis_resize_tvalid(m_axis_tvalid),
    .axis_resize_tready(m_axis_tready),
    .axis_resize_tlast(m_axis_tlast)
  );

endmodule

module axis_flattener 
#(
  // AXI Stream Data Width
  parameter TDATA_WIDTH = 256,
  parameter TUSER_WIDTH = 128
)
(
  // Global Ports
  input                              axis_aclk,
  input                              axis_resetn,

  input  [TDATA_WIDTH - 1:0]         axis_original_tdata,
  input  [((TDATA_WIDTH / 8)) - 1:0] axis_original_tkeep,
  input  [TUSER_WIDTH-1:0]           axis_original_tuser,
  input                              axis_original_tvalid,
  output                             axis_original_tready,
  input                              axis_original_tlast,

  output [TDATA_WIDTH - 1:0]         axis_flattened_tdata,
  output [((TDATA_WIDTH / 8)) - 1:0] axis_flattened_tkeep,
  output [TUSER_WIDTH - 1:0]         axis_flattened_tuser,
  output                             axis_flattened_tvalid,
  input                              axis_flattened_tready,
  output                             axis_flattened_tlast
);

  axis_data_width_converter
  #(
    .IN_TDATA_WIDTH(TDATA_WIDTH),
    .OUT_TDATA_WIDTH(TDATA_WIDTH),
    .TUSER_WIDTH(TUSER_WIDTH)
  )
  flattener
  (
    .axis_aclk(axis_aclk),
    .axis_resetn(axis_resetn),

    .axis_original_tdata(axis_original_tdata),
    .axis_original_tkeep(axis_original_tkeep),
    .axis_original_tuser(axis_original_tuser),
    .axis_original_tvalid(axis_original_tvalid),
    .axis_original_tready(axis_original_tready),
    .axis_original_tlast(axis_original_tlast),

    .axis_resize_tdata(axis_flattened_tdata),
    .axis_resize_tkeep(axis_flattened_tkeep),
    .axis_resize_tuser(axis_flattened_tuser),
    .axis_resize_tvalid(axis_flattened_tvalid),
    .axis_resize_tready(axis_flattened_tready),
    .axis_resize_tlast(axis_flattened_tlast)
  );

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
