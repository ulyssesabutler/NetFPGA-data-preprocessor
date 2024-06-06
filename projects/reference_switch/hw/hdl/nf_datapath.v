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

      // Input from packet processor
      .s_axis_tdata   (processed_packet_axis_tdata),
      .s_axis_tkeep   (processed_packet_axis_tkeep),
      .s_axis_tuser   (processed_packet_axis_tuser),
      .s_axis_tvalid  (processed_packet_axis_tvalid),
      .s_axis_tready  (processed_packet_axis_tready),
      .s_axis_tlast   (processed_packet_axis_tlast),

      /*
      // Old input from output port lookup
      .s_axis_tdata   (m_axis_opl_tdata), 
      .s_axis_tkeep   (m_axis_opl_tkeep), 

      // Overriding this to hardcode output port
      .s_axis_tuser   (output_port_lookup_tuser), 
      //.s_axis_tuser   (m_axis_opl_tuser), 

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





/*************************************************************************************************\
|* NETWORK PACKET PROCESSOR
|* ========================
\*************************************************************************************************/
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
  |* INTERNAL CONNECTIVITY
  \*************************************************************************************************/

  // Splitter output, processor input
  wire [(ETH_HDR_SIZE_BYTES * 8) - 1:0] unprocessed_eth_hdr;
  wire [(IP_HDR_SIZE_BYTES * 8) - 1:0]  unprocessed_ip_hdr;

  wire [TDATA_WIDTH - 1:0]              unprocessed_body_axis_tdata;
  wire [((TDATA_WIDTH / 8)) - 1:0]      unprocessed_body_axis_tkeep;
  wire [TUSER_WIDTH-1:0]                unprocessed_body_axis_tuser;
  wire                                  unprocessed_body_axis_tvalid;
  wire                                  unprocessed_body_axis_tready;
  wire                                  unprocessed_body_axis_tlast;

  // Processor output, constructor input
  wire [(ETH_HDR_SIZE_BYTES * 8) - 1:0] processed_eth_hdr;
  wire [(IP_HDR_SIZE_BYTES * 8) - 1:0]  processed_ip_hdr;

  wire [TDATA_WIDTH - 1:0]              processed_body_axis_tdata;
  wire [((TDATA_WIDTH / 8)) - 1:0]      processed_body_axis_tkeep;
  wire [TUSER_WIDTH-1:0]                processed_body_axis_tuser;
  wire                                  processed_body_axis_tvalid;
  wire                                  processed_body_axis_tready;
  wire                                  processed_body_axis_tlast;

  /*************************************************************************************************\
  |* STEP 1: PACKET SPLITTER
  \*************************************************************************************************/

  network_packet_splitter packet_splitter
  (
    .axis_aclk(axis_aclk),
    .axis_resetn(axis_resetn),

    .nf_axis_tdata(s_axis_tdata),
    .nf_axis_tkeep(s_axis_tkeep),
    .nf_axis_tuser(s_axis_tuser),
    .nf_axis_tvalid(s_axis_tvalid),
    .nf_axis_tready(s_axis_tready),
    .nf_axis_tlast(s_axis_tlast),

    .eth_hdr(unprocessed_eth_hdr),
    .ip_hdr(unprocessed_ip_hdr),

    .body_axis_tdata(unprocessed_body_axis_tdata),
    .body_axis_tkeep(unprocessed_body_axis_tkeep),
    .body_axis_tuser(unprocessed_body_axis_tuser),
    .body_axis_tvalid(unprocessed_body_axis_tvalid),
    .body_axis_tready(unprocessed_body_axis_tready),
    .body_axis_tlast(unprocessed_body_axis_tlast)
  );

  /*************************************************************************************************\
  |* STEP 2: PACKET PROCESSOR
  \*************************************************************************************************/

  network_packet_body_processor packet_body_processor
  (
    .axis_aclk(axis_aclk),
    .axis_resetn(axis_resetn),

    .unprocessed_eth_hdr(unprocessed_eth_hdr),
    .unprocessed_ip_hdr(unprocessed_ip_hdr),

    .processed_eth_hdr(processed_eth_hdr),
    .processed_ip_hdr(processed_ip_hdr),

    .unprocessed_body_axis_tdata(unprocessed_body_axis_tdata),
    .unprocessed_body_axis_tkeep(unprocessed_body_axis_tkeep),
    .unprocessed_body_axis_tuser(unprocessed_body_axis_tuser),
    .unprocessed_body_axis_tvalid(unprocessed_body_axis_tvalid),
    .unprocessed_body_axis_tready(unprocessed_body_axis_tready),
    .unprocessed_body_axis_tlast(unprocessed_body_axis_tlast),

    .processed_body_axis_tdata(processed_body_axis_tdata),
    .processed_body_axis_tkeep(processed_body_axis_tkeep),
    .processed_body_axis_tuser(processed_body_axis_tuser),
    .processed_body_axis_tvalid(processed_body_axis_tvalid),
    .processed_body_axis_tready(processed_body_axis_tready),
    .processed_body_axis_tlast(processed_body_axis_tlast)
  );

  /*************************************************************************************************\
  |* STEP 3: PACKET CONSTRUCTOR
  \*************************************************************************************************/

  network_packet_constructor packet_constructor
  (
    .axis_aclk(axis_aclk),
    .axis_resetn(axis_resetn),

    .processed_eth_hdr(processed_eth_hdr),
    .processed_ip_hdr(processed_ip_hdr),

    .processed_body_axis_tdata(processed_body_axis_tdata),
    .processed_body_axis_tkeep(processed_body_axis_tkeep),
    .processed_body_axis_tuser(processed_body_axis_tuser),
    .processed_body_axis_tvalid(processed_body_axis_tvalid),
    .processed_body_axis_tready(processed_body_axis_tready),
    .processed_body_axis_tlast(processed_body_axis_tlast),

    .nf_axis_tdata(m_axis_tdata),
    .nf_axis_tkeep(m_axis_tkeep),
    .nf_axis_tuser(m_axis_tuser),
    .nf_axis_tvalid(m_axis_tvalid),
    .nf_axis_tready(m_axis_tready),
    .nf_axis_tlast(m_axis_tlast)
  );

endmodule





/*************************************************************************************************\
|* NETWORK PACKET SPLITTER
|* =======================
\*************************************************************************************************/
module network_packet_splitter
#(
  // AXI Stream Data Width
  parameter TDATA_WIDTH        = 256,
  parameter TUSER_WIDTH        = 128,

  // NETWORK PACKET HEADER SIZES
  parameter ETH_HDR_SIZE_BYTES = 14,
  parameter IP_HDR_SIZE_BYTES  = 20
)
(
  // GLOBAL PORTS
  input                                   axis_aclk,
  input                                   axis_resetn,

  // INPUT AXI STREAM
  input [TDATA_WIDTH - 1:0]               nf_axis_tdata,
  input [((TDATA_WIDTH / 8)) - 1:0]       nf_axis_tkeep,
  input [TUSER_WIDTH-1:0]                 nf_axis_tuser,
  input                                   nf_axis_tvalid,
  output                                  nf_axis_tready,
  input                                   nf_axis_tlast,

  // OUTPUT HEADERS
  output [(ETH_HDR_SIZE_BYTES * 8) - 1:0] eth_hdr,
  output [(IP_HDR_SIZE_BYTES * 8) - 1:0]  ip_hdr,

  // OUTPUT BODY
  output [TDATA_WIDTH - 1:0]              body_axis_tdata,
  output [((TDATA_WIDTH / 8)) - 1:0]      body_axis_tkeep,
  output [TUSER_WIDTH-1:0]                body_axis_tuser,
  output                                  body_axis_tvalid,
  input                                   body_axis_tready,
  output                                  body_axis_tlast
);

  /*************************************************************************************************\
  |* INPUT QUEUE
  |* ===========
  |* Create an input queue to store each AXI Stream (AXIS) packet as they are send to this module.
  |* Specifically, we want to store the TLAST, TUSER, TKEEP, and TDATA fields.
  \*************************************************************************************************/

  // INPUT QUEUE VARIABLES
  wire [TDATA_WIDTH-1:0]           input_fifo_head_tdata; // Holds the TDATA of the packet at the head of the input queue
  wire [((TDATA_WIDTH / 8)) - 1:0] input_fifo_head_tkeep;
  wire [TUSER_WIDTH-1:0]           input_fifo_head_tuser;
  wire                             input_fifo_head_tlast;

  wire input_fifo_nearly_full;
  wire input_fifo_empty;

  wire receiving_packet_to_module;
  wire read_packet_from_input_queue;
  
  // INPUT QUEUE MODULE
  fallthrough_small_fifo
  #(
    .WIDTH(TDATA_WIDTH+TUSER_WIDTH+TDATA_WIDTH/8+1), // Fit the whole AXIS packet
    .MAX_DEPTH_BITS(4)
  )
  input_fifo
  (
    .din         ({nf_axis_tlast, nf_axis_tuser, nf_axis_tkeep, nf_axis_tdata}), // Pass the packet heads as input directly to the queue
    .wr_en       (receiving_packet_to_module), // Write enable
    .rd_en       (read_packet_from_input_queue), // Read enabled
    .dout        ({input_fifo_head_tlast, input_fifo_head_tuser, input_fifo_head_tkeep, input_fifo_head_tdata}), // Return TLAST, TKEEP, and TUSER directly to the next stage. Write TDATA to a wire for processing
    .full        (),
    .prog_full   (),
    .nearly_full (input_fifo_nearly_full),
    .empty       (input_fifo_empty),
    .reset       (~axis_resetn),
    .clk         (axis_aclk)
  );

  // QUEUE LOGIC
  assign receiving_packet_to_module = nf_axis_tvalid & nf_axis_tready; // A packet should be pushed to the queue

  // INPUT LOGIC
  assign nf_axis_tready = ~input_fifo_nearly_full; // We're ready to receive as long as the queue has room

  /*************************************************************************************************\
  |* OUTPUT QUEUE
  |* ===========
  |* Create an output queue to store each AXI Stream (AXIS) packet as they are sent from this module.
  |* Specifically, we want to store the TLAST, TUSER, TKEEP, and TDATA fields.
  \*************************************************************************************************/

  // OUTPUT QUEUE VARIABLES
  reg  [TDATA_WIDTH-1:0]               output_fifo_tdata; // Holds the TDATA of the packet at the head of the input queue
  reg  [((TDATA_WIDTH / 8)) - 1:0]     output_fifo_tkeep;
  reg  [TUSER_WIDTH-1:0]               output_fifo_tuser;
  reg                                  output_fifo_tlast;
  reg [(ETH_HDR_SIZE_BYTES * 8) - 1:0] output_fifo_eth_hdr;
  reg [(IP_HDR_SIZE_BYTES * 8) - 1:0]  output_fifo_ip_hdr;
  
  always @(posedge axis_aclk) begin
    if (~axis_resetn) begin
      output_fifo_tdata   <= 0;
      output_fifo_tkeep   <= 0;
      output_fifo_tuser   <= 0;
      output_fifo_tlast   <= 0;
      output_fifo_eth_hdr <= 0;
      output_fifo_ip_hdr  <= 0;
    end
  end

  wire output_fifo_nearly_full;
  wire output_fifo_empty;

  reg  write_to_output_queue;
  wire send_from_module;
  
  // OUTPUT QUEUE MODULE
  fallthrough_small_fifo
  #(
    .WIDTH(TDATA_WIDTH+TUSER_WIDTH+TDATA_WIDTH/8+1+ETH_HDR_SIZE_BYTES*8+IP_HDR_SIZE_BYTES*8), // Fit the whole AXIS packet and the headers
    .MAX_DEPTH_BITS(4)
  )
  output_fifo
  (
    .din         ({output_fifo_tdata, output_fifo_tuser, output_fifo_tkeep, output_fifo_tlast, output_fifo_eth_hdr, output_fifo_ip_hdr}), // Pass the packet heads as input directly to the queue
    .wr_en       (write_to_output_queue), // Write enable
    .rd_en       (send_from_module), // Read enabled
    .dout        ({body_axis_tdata, body_axis_tuser, body_axis_tkeep, body_axis_tlast, eth_hdr, ip_hdr}), // Return TLAST, TKEEP, and TUSER directly to the next stage. Write TDATA to a wire for processing
    .full        (),
    .prog_full   (),
    .nearly_full (output_fifo_nearly_full),
    .empty       (output_fifo_empty),
    .reset       (~axis_resetn),
    .clk         (axis_aclk)
  );

  // QUEUE LOGIC
  assign send_from_module = body_axis_tvalid & body_axis_tready; // A packet should be pushed to the queue

  // INPUT LOGIC
  assign body_axis_tvalid = ~output_fifo_empty; // We're ready to send as long as there is stuff in the queue

  /*************************************************************************************************\
  |* PACKET SPLITTING LOGIC
  |* =======================
  |* The main purpose of this section is to split out the headers and the body.
  |* We then forward them to the body, along with the headers, to the packet_body_processor.
  \*************************************************************************************************/

  // TRACKING VARIABLES
  integer                          axis_packet_count_for_net_packet;

  // LOGIC
  assign read_packet_from_input_queue = ~input_fifo_empty & ~output_fifo_nearly_full;

  always @(posedge axis_aclk) begin
    if (~axis_resetn) begin
      axis_packet_count_for_net_packet <= 0;
      write_to_output_queue            <= 0;
    end else begin
      // TODO: This isn't the most effecient approach, since the queue doesn't need room to process the headers.
      if (read_packet_from_input_queue) begin
        case (axis_packet_count_for_net_packet)

          0: begin // This is the first AXIS packet of this net packet
            // Load the Ethernet header
            output_fifo_eth_hdr                                                                         <= input_fifo_head_tdata[(ETH_HDR_SIZE_BYTES * 8) - 1:0];
            // Load the first part of the IP header
            output_fifo_ip_hdr[TDATA_WIDTH - (ETH_HDR_SIZE_BYTES * 8) - 1:0]                            <= input_fifo_head_tdata[TDATA_WIDTH - 1:ETH_HDR_SIZE_BYTES * 8];
                        
            // Load the metadata
            output_fifo_tuser                                                                           <= input_fifo_head_tuser;
          end

          1: begin // This is the second AXIS packet of this net packet
            // Load the second part of the IP header
            output_fifo_ip_hdr[(IP_HDR_SIZE_BYTES * 8) - 1:TDATA_WIDTH - (ETH_HDR_SIZE_BYTES * 8)]      <= input_fifo_head_tdata[(IP_HDR_SIZE_BYTES * 8) - (TDATA_WIDTH - (ETH_HDR_SIZE_BYTES * 8)) - 1:0];

            // Load the beginning of the payload
            output_fifo_tdata[2 * TDATA_WIDTH - (ETH_HDR_SIZE_BYTES * 8 + IP_HDR_SIZE_BYTES * 8) - 1:0] <= input_fifo_head_tdata[TDATA_WIDTH - 1:(IP_HDR_SIZE_BYTES * 8) - (TDATA_WIDTH - (ETH_HDR_SIZE_BYTES * 8))];
            output_fifo_tkeep                                                                           <= input_fifo_head_tkeep >> (IP_HDR_SIZE_BYTES - ((TDATA_WIDTH / 8) - ETH_HDR_SIZE_BYTES));
            output_fifo_tlast                                                                           <= input_fifo_head_tlast;
          end

          default: begin
            // Load the payload
            output_fifo_tdata                                                                           <= input_fifo_head_tdata;
            output_fifo_tkeep                                                                           <= input_fifo_head_tkeep;
            output_fifo_tlast                                                                           <= input_fifo_head_tlast;
          end

        endcase

        // Signal to the queue
        if (axis_packet_count_for_net_packet > 0)
          write_to_output_queue <= 1;
        else
          write_to_output_queue <= 0;

        // Update the packet count
        if (~input_fifo_head_tlast)
          axis_packet_count_for_net_packet <= axis_packet_count_for_net_packet + 1;

        // Reset when his is the last AXI packet of the network packet
        if (input_fifo_head_tlast)
          axis_packet_count_for_net_packet <= 0;
      end else begin
          write_to_output_queue <= 0;
      end
    end
  end

endmodule





/*************************************************************************************************\
|* PACKET BODY PROCESSOR
|* =====================
\*************************************************************************************************/
module network_packet_body_processor
#(
  // AXI Stream Data Width
  parameter TDATA_WIDTH        = 256,
  parameter TUSER_WIDTH        = 128,

  // NETWORK PACKET HEADER SIZES
  parameter ETH_HDR_SIZE_BYTES = 14,
  parameter IP_HDR_SIZE_BYTES  = 20
)
(
  // GLOBAL PORTS
  input                                   axis_aclk,
  input                                   axis_resetn,

  // PACKET HEADERS
  // The packet headers should be present on these wires constantly while the body is being processed
  input  [(ETH_HDR_SIZE_BYTES * 8) - 1:0] unprocessed_eth_hdr,
  input  [(IP_HDR_SIZE_BYTES * 8) - 1:0]  unprocessed_ip_hdr,
  // TODO: We should add a keep wire for these headers, since they're variable length

  // The updated headers must be present on these wires while m_packet_body_axis_tvalid is set
  output [(ETH_HDR_SIZE_BYTES * 8) - 1:0] processed_eth_hdr,
  output [(IP_HDR_SIZE_BYTES * 8) - 1:0]  processed_ip_hdr,

  // PACKET BODY
  // Slave Stream Ports for the original packet body (input)
  input  [TDATA_WIDTH - 1:0]              unprocessed_body_axis_tdata,
  input  [((TDATA_WIDTH / 8)) - 1:0]      unprocessed_body_axis_tkeep,
  input  [TUSER_WIDTH-1:0]                unprocessed_body_axis_tuser,
  input                                   unprocessed_body_axis_tvalid,
  output                                  unprocessed_body_axis_tready,
  input                                   unprocessed_body_axis_tlast,

  // Master Stream Ports for the modified packet body (output)
  output [TDATA_WIDTH - 1:0]              processed_body_axis_tdata,
  output [((TDATA_WIDTH / 8)) - 1:0]      processed_body_axis_tkeep,
  output [TUSER_WIDTH-1:0]                processed_body_axis_tuser,
  output                                  processed_body_axis_tvalid,
  input                                   processed_body_axis_tready,
  output                                  processed_body_axis_tlast
);

  // HEADER
  assign processed_eth_hdr            = unprocessed_eth_hdr;
  assign processed_ip_hdr             = unprocessed_ip_hdr;

  // PACKET BODY PROCESSING
  wire   [TDATA_WIDTH-1:0] processed_body_mask;
  byte_to_bit_mask mask_creator
  (
    .byte_mask(unprocessed_body_axis_tkeep),
    .bit_mask(processed_body_mask)
  );

  assign processed_body_axis_tdata    = (~unprocessed_body_axis_tdata) & processed_body_mask; // Dummy operation

  // PACKET BODY CONTROL SIGNALS
  assign processed_body_axis_tkeep    = unprocessed_body_axis_tkeep;
  assign processed_body_axis_tuser    = unprocessed_body_axis_tuser;
  assign processed_body_axis_tvalid   = unprocessed_body_axis_tvalid;
  assign unprocessed_body_axis_tready = processed_body_axis_tready;
  assign processed_body_axis_tlast    = unprocessed_body_axis_tlast;

endmodule





/*************************************************************************************************\
|* NETWORK PACKET CONSTRUCTOR
|* ==========================
\*************************************************************************************************/
module network_packet_constructor
#(
  // AXI Stream Data Width
  parameter TDATA_WIDTH        = 256,
  parameter TUSER_WIDTH        = 128,

  // NETWORK PACKET HEADER SIZES
  parameter ETH_HDR_SIZE_BYTES = 14,
  parameter IP_HDR_SIZE_BYTES  = 20
)
(
  // GLOBAL PORTS
  input                                   axis_aclk,
  input                                   axis_resetn,

  // PACKET HEADERS
  input  [(ETH_HDR_SIZE_BYTES * 8) - 1:0] processed_eth_hdr,
  input  [(IP_HDR_SIZE_BYTES * 8) - 1:0]  processed_ip_hdr,

  // PACKET BODY
  input  [TDATA_WIDTH - 1:0]              processed_body_axis_tdata,
  input  [((TDATA_WIDTH / 8)) - 1:0]      processed_body_axis_tkeep,
  input  [TUSER_WIDTH-1:0]                processed_body_axis_tuser,
  input                                   processed_body_axis_tvalid,
  output reg                              processed_body_axis_tready,
  input                                   processed_body_axis_tlast,

  // NetFPGA AXI STREAM (output)
  output [TDATA_WIDTH - 1:0]              nf_axis_tdata,
  output [((TDATA_WIDTH / 8)) - 1:0]      nf_axis_tkeep,
  output [TUSER_WIDTH-1:0]                nf_axis_tuser,
  output                                  nf_axis_tvalid,
  input                                   nf_axis_tready,
  output                                  nf_axis_tlast
);

  /*************************************************************************************************\
  |* FSM
  \*************************************************************************************************/

  // STATES
  localparam STATE_ETH_HDR = 0;
  localparam STATE_IP_HDR  = 1;
  localparam STATE_IP_BODY = 2;

  // FSM VARIABLES
  reg [1:0] state; // The current state

  always @(posedge axis_aclk) begin
    if (~axis_resetn) state <= STATE_ETH_HDR;
  end

  /*************************************************************************************************\
  |* HEADER PROCESSING
  \*************************************************************************************************/

  // VARIABLES
  reg hdr_valid;

  always @(posedge axis_aclk) begin
    output_queue_axis_tdata <= 0;
    output_queue_axis_tkeep <= 0;
    output_queue_axis_tuser <= 0;
    output_queue_axis_tlast <= 0;
    
    if (~output_fifo_nearly_full & processed_body_axis_tvalid) begin
      case (state)

        STATE_ETH_HDR: begin
          output_queue_axis_tdata[(ETH_HDR_SIZE_BYTES * 8) - 1:0] <= processed_eth_hdr;
          output_queue_axis_tuser                                 <= processed_body_axis_tuser;
          output_queue_axis_tkeep                                 <= (1 << ETH_HDR_SIZE_BYTES) - 1;
          output_queue_axis_tlast                                 <= 0;

          hdr_valid                                               <= 1;

          state                                                   <= STATE_IP_HDR;
        end

        STATE_IP_HDR: begin
          output_queue_axis_tdata[(IP_HDR_SIZE_BYTES * 8) - 1:0] <= processed_ip_hdr;
          output_queue_axis_tuser                                <= processed_body_axis_tuser;
          output_queue_axis_tkeep                                <= (1 << IP_HDR_SIZE_BYTES) - 1;
          output_queue_axis_tlast                                <= 0;

          hdr_valid                                              <= 1;

          state                                                  <= STATE_IP_BODY;
        end

        default: begin
          hdr_valid                                              <= 0;
        end

      endcase
    end else begin
      hdr_valid <= 0;
    end
  end

  /*************************************************************************************************\
  |* PACKET BODY PROCESSING
  \*************************************************************************************************/

  // LOGIC
  always @(posedge axis_aclk) begin
    if (processed_body_axis_tvalid & ~output_fifo_nearly_full) begin
      case (state)

        STATE_IP_BODY: begin
          output_queue_axis_tdata    <= processed_body_axis_tdata;
          output_queue_axis_tuser    <= processed_body_axis_tuser;
          output_queue_axis_tkeep    <= processed_body_axis_tkeep;
          output_queue_axis_tlast    <= processed_body_axis_tlast;
          
          processed_body_axis_tready <= 1;

          if (processed_body_axis_tlast) begin
            state <= STATE_ETH_HDR;
          end else begin
            state <= STATE_IP_BODY;
          end
        end

        default: begin
          processed_body_axis_tready <= 0;
        end

      endcase
    end else begin
      processed_body_axis_tready <= 0;
    end
  end

  /*************************************************************************************************\
  |* OUTPUT QUEUE
  \*************************************************************************************************/

  // OUTPUT QUEUE VARIABLES
  reg  [TDATA_WIDTH - 1:0]         output_queue_axis_tdata;
  reg  [((TDATA_WIDTH / 8)) - 1:0] output_queue_axis_tkeep;
  reg  [TUSER_WIDTH-1:0]           output_queue_axis_tuser;
  reg                              output_queue_axis_tlast;

  wire [TDATA_WIDTH - 1:0]         uncompressed_nf_axis_tdata;
  wire [((TDATA_WIDTH / 8)) - 1:0] uncompressed_nf_axis_tkeep;
  wire [TUSER_WIDTH-1:0]           uncompressed_nf_axis_tuser;
  wire                             uncompressed_nf_axis_tvalid;
  wire                             uncompressed_nf_axis_tready;
  wire                             uncompressed_nf_axis_tlast;

  wire                             output_fifo_nearly_full;
  wire                             output_fifo_empty;

  wire                             write_to_queue;
  wire                             read_from_queue;

  // OUTPUT QUEUE MODULE
  fallthrough_small_fifo
  #(
    .WIDTH(TDATA_WIDTH+TUSER_WIDTH+TDATA_WIDTH/8+1), // Fit the whole AXIS packet
    .MAX_DEPTH_BITS(4)
  )
  input_fifo
  (
    .din         ({output_queue_axis_tdata, output_queue_axis_tuser, output_queue_axis_tkeep, output_queue_axis_tlast}),
    .wr_en       (write_to_queue),
    .rd_en       (read_from_queue), // Read enabled
    .dout        ({uncompressed_nf_axis_tdata, uncompressed_nf_axis_tuser, uncompressed_nf_axis_tkeep, uncompressed_nf_axis_tlast}), // Return TLAST, TKEEP, and TUSER directly to the next stage. Write TDATA to a wire for processing
    .full        (),
    .prog_full   (),
    .nearly_full (output_fifo_nearly_full),
    .empty       (output_fifo_empty),
    .reset       (~axis_resetn),
    .clk         (axis_aclk)
  );

  // OUTPUT QUEUE LOGIC
  assign write_to_queue = (processed_body_axis_tvalid & processed_body_axis_tready) | hdr_valid;
  assign read_from_queue = uncompressed_nf_axis_tvalid & uncompressed_nf_axis_tready;

  assign uncompressed_nf_axis_tvalid = ~output_fifo_empty;

  /*************************************************************************************************\
  |* AXI STREAM FLATTENER
  \*************************************************************************************************/

  axis_flatten flattener
  (
    .axis_aclk(axis_aclk),
    .axis_resetn(axis_resetn),

    .s_axis_tdata(uncompressed_nf_axis_tdata),
    .s_axis_tkeep(uncompressed_nf_axis_tkeep),
    .s_axis_tuser(uncompressed_nf_axis_tuser),
    .s_axis_tvalid(uncompressed_nf_axis_tvalid),
    .s_axis_tready(uncompressed_nf_axis_tready),
    .s_axis_tlast(uncompressed_nf_axis_tlast),

    .m_axis_tdata(nf_axis_tdata),
    .m_axis_tkeep(nf_axis_tkeep),
    .m_axis_tuser(nf_axis_tuser),
    .m_axis_tvalid(nf_axis_tvalid),
    .m_axis_tready(nf_axis_tready),
    .m_axis_tlast(nf_axis_tlast)
  );
  
  /*
  // Bypass the flattener
  assign nf_axis_tdata = uncompressed_nf_axis_tdata;
  assign nf_axis_tkeep = uncompressed_nf_axis_tkeep;
  assign nf_axis_tuser = uncompressed_nf_axis_tuser;
  assign nf_axis_tvalid = uncompressed_nf_axis_tvalid;
  assign uncompressed_nf_axis_tready = nf_axis_tready;
  assign nf_axis_tlast = uncompressed_nf_axis_tlast;
  */

endmodule

module byte_to_bit_mask
#(
  parameter BYTE_MASK_WIDTH = 32
)
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

module axis_flatten
#(
  // AXI Stream Data Width
  parameter TDATA_WIDTH        = 256,
  parameter TUSER_WIDTH        = 128,

  localparam TKEEP_WIDTH       = TDATA_WIDTH / 8
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
  |* ===========
  \*************************************************************************************************/

  // INPUT QUEUE VARIABLES
  wire [TDATA_WIDTH-1:0]           input_fifo_head_tdata; // Holds the TDATA of the packet at the head of the input queue
  wire [((TDATA_WIDTH / 8)) - 1:0] input_fifo_head_tkeep;
  wire [TUSER_WIDTH-1:0]           input_fifo_head_tuser;
  wire                             input_fifo_head_tlast;

  wire input_fifo_nearly_full;
  wire input_fifo_empty;

  wire receiving_packet_to_module;
  wire read_from_input_queue;
  
  // INPUT QUEUE MODULE
  fallthrough_small_fifo
  #(
    .WIDTH(TDATA_WIDTH+TUSER_WIDTH+TDATA_WIDTH/8+1), // Fit the whole AXIS packet
    .MAX_DEPTH_BITS(4)
  )
  input_fifo
  (
    .din         ({s_axis_tlast, s_axis_tuser, s_axis_tkeep, s_axis_tdata}), // Pass the packet heads as input directly to the queue
    .wr_en       (receiving_packet_to_module), // Write enable
    .rd_en       (read_from_input_queue), // Read enabled
    .dout        ({input_fifo_head_tlast, input_fifo_head_tuser, input_fifo_head_tkeep, input_fifo_head_tdata}), // Return TLAST, TKEEP, and TUSER directly to the next stage. Write TDATA to a wire for processing
    .full        (),
    .prog_full   (),
    .nearly_full (input_fifo_nearly_full),
    .empty       (input_fifo_empty),
    .reset       (~axis_resetn),
    .clk         (axis_aclk)
  );

  // QUEUE LOGIC
  assign receiving_packet_to_module = s_axis_tvalid & s_axis_tready; // A packet should be pushed to the queue

  // INPUT LOGIC
  assign s_axis_tready = ~input_fifo_nearly_full; // We're ready to receive as long as the queue has room

  /*************************************************************************************************\
  |* OUTPUT QUEUE
  |* ============
  \*************************************************************************************************/

  // OUTPUT QUEUE VARIABLES
  reg  [TDATA_WIDTH-1:0]               output_fifo_tdata; // Holds the TDATA of the packet at the head of the input queue
  reg  [((TDATA_WIDTH / 8)) - 1:0]     output_fifo_tkeep;
  reg  [TUSER_WIDTH-1:0]               output_fifo_tuser;
  reg                                  output_fifo_tlast;
  
  always @(posedge axis_aclk) begin
    if (~axis_resetn) begin
      output_fifo_tdata   <= 0;
      output_fifo_tkeep   <= 0;
      output_fifo_tuser   <= 0;
      output_fifo_tlast   <= 0;
    end
  end

  wire output_fifo_nearly_full;
  wire output_fifo_empty;

  reg  write_to_output_queue;
  wire send_from_module;
  
  // OUTPUT QUEUE MODULE
  fallthrough_small_fifo
  #(
    .WIDTH(TDATA_WIDTH+TUSER_WIDTH+TDATA_WIDTH/8+1), // Fit the whole AXIS packet and the headers
    .MAX_DEPTH_BITS(4)
  )
  output_fifo
  (
    .din         ({output_fifo_tdata, output_fifo_tuser, output_fifo_tkeep, output_fifo_tlast}), // Pass the packet heads as input directly to the queue
    .wr_en       (write_to_output_queue), // Write enable
    .rd_en       (send_from_module), // Read enabled
    .dout        ({m_axis_tdata, m_axis_tuser, m_axis_tkeep, m_axis_tlast}), // Return TLAST, TKEEP, and TUSER directly to the next stage. Write TDATA to a wire for processing
    .full        (),
    .prog_full   (),
    .nearly_full (output_fifo_nearly_full),
    .empty       (output_fifo_empty),
    .reset       (~axis_resetn),
    .clk         (axis_aclk)
  );

  // QUEUE LOGIC
  assign send_from_module = m_axis_tvalid & m_axis_tready; // A packet should be pushed to the queue

  // OUTPUT LOGIC
  assign m_axis_tvalid = ~output_fifo_empty; // We're ready to send as long as there is stuff in the queue

  /*************************************************************************************************\
  |* LOGIC
  |* =====
  \*************************************************************************************************/

  // VARIABLES
  reg  [TDATA_WIDTH - 1:0] input_data_buffer;
  reg  [TKEEP_WIDTH - 1:0] input_keep_buffer;
  reg  [TUSER_WIDTH - 1:0] input_user_buffer;
  reg                      input_last_buffer;

  wire [TDATA_WIDTH - 1:0] input_data_buffer_after_move;
  wire [TKEEP_WIDTH - 1:0] input_keep_buffer_after_move;

  reg  [TDATA_WIDTH - 1:0] output_data_buffer;
  reg  [TKEEP_WIDTH - 1:0] output_keep_buffer;

  wire [TDATA_WIDTH - 1:0] output_data_buffer_after_move;
  wire [TKEEP_WIDTH - 1:0] output_keep_buffer_after_move;

  wire                     is_input_data_buffer_empty;

  wire                     is_input_data_buffer_empty_after_move;
  wire                     is_output_fifo_tdata_full_after_move;
  
  always @(posedge axis_aclk) begin

  end
  
  // LOGIC

  // These buffers above are going to be the source of our copy. The output fifo input will be the destination.
  // For now, we're going to store the results of the move on the wires we just created, and use those values
  //  to decide how we want to manage the queue.
  copy_into_empty copy_input_buffer_into_output_fifo
  (
    .src_data_in(input_data_buffer),
    .src_keep_in(input_keep_buffer),

    .dest_data_in(output_data_buffer),
    .dest_keep_in(output_keep_buffer),

    .src_data_out(input_data_buffer_after_move),
    .src_keep_out(input_keep_buffer_after_move),

    .dest_data_out(output_data_buffer_after_move),
    .dest_keep_out(output_keep_buffer_after_move)
  );

  // Buffer capacity
  assign is_input_data_buffer_empty            = ~| input_keep_buffer;
  assign is_input_data_buffer_empty_after_move = ~| input_keep_buffer_after_move;
  assign is_output_data_buffer_full_after_move = ~|(~output_keep_buffer_after_move);

  // Buffer loading
  assign read_from_input_queue = ~input_fifo_empty & (is_input_data_buffer_empty_after_move | is_input_data_buffer_empty);

  always @(posedge axis_aclk) begin
    if (~axis_resetn) begin
      input_data_buffer  <= 0;
      input_keep_buffer  <= 0;
      input_user_buffer  <= 0;
      input_last_buffer  <= 0;
      
      output_data_buffer <= 0;
      output_keep_buffer <= 0;
    end else begin
      // We can move data on each clock cycle.
      // This operation does not depend on space being available in the output queue or items being present on the input
      input_data_buffer  <= input_data_buffer_after_move;
      input_keep_buffer  <= input_keep_buffer_after_move;
  
      output_data_buffer <= output_data_buffer_after_move;
      output_keep_buffer <= output_keep_buffer_after_move;
  
      if (read_from_input_queue) begin
        // Since the input buffer is about to be empty, and there are items in the queue, we can refill the buffer
        input_data_buffer     <= input_fifo_head_tdata;
        input_keep_buffer     <= input_fifo_head_tkeep;
        input_user_buffer     <= input_fifo_head_tuser;
        input_last_buffer     <= input_fifo_head_tlast;
      end
  
      if (~output_fifo_nearly_full & (is_output_data_buffer_full_after_move | input_last_buffer)) begin
        // Once this data is written, we should write to the queue
        write_to_output_queue <= 1;

        // We can just write the output buffer directly to the output queue
        output_fifo_tdata     <= output_data_buffer_after_move;
        output_fifo_tkeep     <= output_keep_buffer_after_move;
  
        // Forward the remaining buffers to the queue as well
        output_fifo_tuser     <= input_user_buffer;
        output_fifo_tlast     <= input_last_buffer;
  
        // Finally, zero out the output buffer for the next transfer
        output_data_buffer    <= 0;
        output_keep_buffer    <= 0;
      end else begin
        write_to_output_queue <= 0;
      end
    end

  end

endmodule

module copy_into_empty
#(
  parameter DATA_WIDTH  = 256,
  localparam KEEP_WIDTH = DATA_WIDTH / 8
)
(
  input  [DATA_WIDTH - 1:0] src_data_in,
  input  [KEEP_WIDTH - 1:0] src_keep_in,

  input  [DATA_WIDTH - 1:0] dest_data_in,
  input  [KEEP_WIDTH - 1:0] dest_keep_in,

  output [DATA_WIDTH - 1:0] src_data_out,
  output [KEEP_WIDTH - 1:0] src_keep_out,

  output [DATA_WIDTH - 1:0] dest_data_out,
  output [KEEP_WIDTH - 1:0] dest_keep_out
);

  wire    [31:0] first_non_empty_in_dest_data_out;
  wire    [31:0] first_non_empty_in_dest_keep_out;

  first_null_index first_non_empty_in_dest_keep_out_calc
  (
    .data(dest_keep_in),
    .index(first_non_empty_in_dest_keep_out)
  );
  assign first_non_empty_in_dest_data_out = first_non_empty_in_dest_keep_out * 8;

  assign dest_data_out = (src_data_in << first_non_empty_in_dest_data_out) | dest_data_in;
  assign dest_keep_out = (src_keep_in << first_non_empty_in_dest_keep_out) | dest_keep_in;

  assign src_data_out  = src_data_in >> (DATA_WIDTH - first_non_empty_in_dest_data_out);
  assign src_keep_out  = src_keep_in >> (KEEP_WIDTH - first_non_empty_in_dest_keep_out);

endmodule

module first_null_index
#(
  parameter DATA_WIDTH             = 32,
  localparam DATA_WIDTH_INDEX_SIZE = $clog2(DATA_WIDTH) + 1
)
(
  input  [DATA_WIDTH - 1:0] data,
  output integer            index
);

  integer i;
  reg     found_null_index;

  always @(*) begin
    found_null_index = 0;
    i                = DATA_WIDTH;
    
    for (i = 0; i < DATA_WIDTH; i = i + 1) begin
      if (~data[i] & ~found_null_index) begin
        index            = i;
        found_null_index = 1;
      end
    end
  end

endmodule
