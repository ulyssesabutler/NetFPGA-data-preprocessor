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

/*************************************************************************************************\
|* Packet Processor
|* =======================
|* The data width converter and AXI Stream flattener.
\*************************************************************************************************/

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

  // Intermediate Connections
  wire [TDATA_WIDTH - 1:0]         axis_header_tdata;
  wire [((TDATA_WIDTH / 8)) - 1:0] axis_header_tkeep;
  wire [TUSER_WIDTH-1:0]           axis_header_tuser;
  wire                             axis_header_tvalid;
  wire                             axis_header_tready;
  wire                             axis_header_tlast;

  wire [TDATA_WIDTH - 1:0]         axis_unprocessed_body_tdata;
  wire [((TDATA_WIDTH / 8)) - 1:0] axis_unprocessed_body_tkeep;
  wire [TUSER_WIDTH-1:0]           axis_unprocessed_body_tuser;
  wire                             axis_unprocessed_body_tvalid;
  wire                             axis_unprocessed_body_tready;
  wire                             axis_unprocessed_body_tlast;

  wire [TDATA_WIDTH - 1:0]         axis_processed_body_tdata;
  wire [((TDATA_WIDTH / 8)) - 1:0] axis_processed_body_tkeep;
  wire [TUSER_WIDTH-1:0]           axis_processed_body_tuser;
  wire                             axis_processed_body_tvalid;
  wire                             axis_processed_body_tready;
  wire                             axis_processed_body_tlast;

  // Splitter
  packet_splitter splitter
  (
    .axis_aclk(axis_aclk),
    .axis_resetn(axis_resetn),

    .axis_in_tdata(s_axis_tdata),
    .axis_in_tkeep(s_axis_tkeep),
    .axis_in_tuser(s_axis_tuser),
    .axis_in_tvalid(s_axis_tvalid),
    .axis_in_tready(s_axis_tready),
    .axis_in_tlast(s_axis_tlast),

    .axis_out_header_tdata(axis_header_tdata),
    .axis_out_header_tkeep(axis_header_tkeep),
    .axis_out_header_tuser(axis_header_tuser),
    .axis_out_header_tvalid(axis_header_tvalid),
    .axis_out_header_tready(axis_header_tready),
    .axis_out_header_tlast(axis_header_tlast),

    .axis_out_body_tdata(axis_unprocessed_body_tdata),
    .axis_out_body_tkeep(axis_unprocessed_body_tkeep),
    .axis_out_body_tuser(axis_unprocessed_body_tuser),
    .axis_out_body_tvalid(axis_unprocessed_body_tvalid),
    .axis_out_body_tready(axis_unprocessed_body_tready),
    .axis_out_body_tlast(axis_unprocessed_body_tlast)
  );

  // Normalize
  image_to_tensor_scaler scaler
  (
    .axis_aclk(axis_aclk),
    .axis_resetn(axis_resetn),

    .axis_image_tdata(axis_unprocessed_body_tdata),
    .axis_image_tkeep(axis_unprocessed_body_tkeep),
    .axis_image_tuser(axis_unprocessed_body_tuser),
    .axis_image_tvalid(axis_unprocessed_body_tvalid),
    .axis_image_tready(axis_unprocessed_body_tready),
    .axis_image_tlast(axis_unprocessed_body_tlast),

    .axis_tensor_tdata(axis_processed_body_tdata),
    .axis_tensor_tkeep(axis_processed_body_tkeep),
    .axis_tensor_tuser(axis_processed_body_tuser),
    .axis_tensor_tvalid(axis_processed_body_tvalid),
    .axis_tensor_tready(axis_processed_body_tready),
    .axis_tensor_tlast(axis_processed_body_tlast)
  );

  // Recombine
  packet_constructor constructor
  (
    .axis_aclk(axis_aclk),
    .axis_resetn(axis_resetn),

    .axis_in_header_tdata(axis_header_tdata),
    .axis_in_header_tkeep(axis_header_tkeep),
    .axis_in_header_tuser(axis_header_tuser),
    .axis_in_header_tvalid(axis_header_tvalid),
    .axis_in_header_tready(axis_header_tready),
    .axis_in_header_tlast(axis_header_tlast),

    .axis_in_body_tdata(axis_processed_body_tdata),
    .axis_in_body_tkeep(axis_processed_body_tkeep),
    .axis_in_body_tuser(axis_processed_body_tuser),
    .axis_in_body_tvalid(axis_processed_body_tvalid),
    .axis_in_body_tready(axis_processed_body_tready),
    .axis_in_body_tlast(axis_processed_body_tlast),

    .axis_out_tdata(m_axis_tdata),
    .axis_out_tkeep(m_axis_tkeep),
    .axis_out_tuser(m_axis_tuser),
    .axis_out_tvalid(m_axis_tvalid),
    .axis_out_tready(m_axis_tready),
    .axis_out_tlast(m_axis_tlast)
  );

endmodule

module packet_splitter
#(
  // AXI Stream Data Width
  parameter TDATA_WIDTH         = 256,
  parameter TUSER_WIDTH         = 128,
  localparam PACKET_BODY_OFFSET = 34 // TODO: Replace with input parameter
)
(
  input                              axis_aclk,
  input                              axis_resetn,

  input  [TDATA_WIDTH - 1:0]         axis_in_tdata,
  input  [((TDATA_WIDTH / 8)) - 1:0] axis_in_tkeep,
  input  [TUSER_WIDTH-1:0]           axis_in_tuser,
  input                              axis_in_tvalid,
  output                             axis_in_tready,
  input                              axis_in_tlast,

  output [TDATA_WIDTH - 1:0]         axis_out_header_tdata,
  output [((TDATA_WIDTH / 8)) - 1:0] axis_out_header_tkeep,
  output [TUSER_WIDTH-1:0]           axis_out_header_tuser,
  output                             axis_out_header_tvalid,
  input                              axis_out_header_tready,
  output                             axis_out_header_tlast,

  output [TDATA_WIDTH - 1:0]         axis_out_body_tdata,
  output [((TDATA_WIDTH / 8)) - 1:0] axis_out_body_tkeep,
  output [TUSER_WIDTH-1:0]           axis_out_body_tuser,
  output                             axis_out_body_tvalid,
  input                              axis_out_body_tready,
  output                             axis_out_body_tlast
);

  // Output Header Queue
  reg  [TDATA_WIDTH - 1:0]          output_header_queue_input_tdata;
  reg  [((TDATA_WIDTH / 8)) - 1:0]  output_header_queue_input_tkeep;
  reg  [TUSER_WIDTH-1:0]            output_header_queue_input_tuser;
  reg                               output_header_queue_input_tlast;

  reg                               write_to_output_header_queue;
  wire                              read_from_output_header_queue;

  wire                              output_header_queue_nearly_full;
  wire                              output_header_queue_empty;

  fallthrough_small_fifo
  #(
    .WIDTH(TDATA_WIDTH+TUSER_WIDTH+TDATA_WIDTH/8+1), // Fit the whole AXIS packet and the headers
    .MAX_DEPTH_BITS(4)
  )
  output_header_queue
  (
    .din         ({output_header_queue_input_tdata, output_header_queue_input_tkeep, output_header_queue_input_tuser, output_header_queue_input_tlast}),
    .wr_en       (write_to_output_header_queue),
    .rd_en       (read_from_output_header_queue),
    .dout        ({axis_out_header_tdata, axis_out_header_tkeep, axis_out_header_tuser, axis_out_header_tlast}),
    .full        (),
    .prog_full   (),
    .nearly_full (output_header_queue_nearly_full),
    .empty       (output_header_queue_empty),
    .reset       (~axis_resetn),
    .clk         (axis_aclk)
  );

  assign read_from_output_header_queue = axis_out_header_tvalid & axis_out_header_tready;
  assign axis_out_header_tvalid = ~output_header_queue_empty;

  // Output Body Queue
  reg  [TDATA_WIDTH - 1:0]          output_body_queue_input_tdata;
  reg  [((TDATA_WIDTH / 8)) - 1:0]  output_body_queue_input_tkeep;
  reg  [TUSER_WIDTH-1:0]            output_body_queue_input_tuser;
  reg                               output_body_queue_input_tlast;

  reg                               write_to_output_body_queue;
  wire                              read_from_output_body_queue;

  wire                              output_body_queue_nearly_full;
  wire                              output_body_queue_empty;

  fallthrough_small_fifo
  #(
    .WIDTH(TDATA_WIDTH+TUSER_WIDTH+TDATA_WIDTH/8+1), // Fit the whole AXIS packet and the headers
    .MAX_DEPTH_BITS(4)
  )
  output_body_queue
  (
    .din         ({output_body_queue_input_tdata, output_body_queue_input_tkeep, output_body_queue_input_tuser, output_body_queue_input_tlast}),
    .wr_en       (write_to_output_body_queue),
    .rd_en       (read_from_output_body_queue),
    .dout        ({axis_out_body_tdata, axis_out_body_tkeep, axis_out_body_tuser, axis_out_body_tlast}),
    .full        (),
    .prog_full   (),
    .nearly_full (output_body_queue_nearly_full),
    .empty       (output_body_queue_empty),
    .reset       (~axis_resetn),
    .clk         (axis_aclk)
  );

  assign read_from_output_body_queue = axis_out_body_tvalid & axis_out_body_tready;
  assign axis_out_body_tvalid = ~output_body_queue_empty;

  // AXI Packet Input
  assign axis_in_tready = ~output_header_queue_nearly_full & ~output_body_queue_nearly_full;
  wire reading_axis_packet = axis_in_tvalid & axis_in_tready;

  // Packet tracking
  reg [31:0] axis_packets_byte_reading_complete_count;
  reg [31:0] axis_packets_byte_reading_complete_count_next;

  always @(*) begin
    axis_packets_byte_reading_complete_count_next = axis_packets_byte_reading_complete_count;

    if (reading_axis_packet) begin
      if (~axis_in_tlast)
        axis_packets_byte_reading_complete_count_next = axis_packets_byte_reading_complete_count + 32;
      else
        axis_packets_byte_reading_complete_count_next = 0;
    end
  end

  always @(posedge axis_aclk) begin
    if (~axis_resetn)
      axis_packets_byte_reading_complete_count = 0;
    else
      axis_packets_byte_reading_complete_count = axis_packets_byte_reading_complete_count_next;
  end

  wire [31:0] axis_packets_byte_reading_complete_after_current_count = axis_packets_byte_reading_complete_count + (reading_axis_packet ? 32 : 0);
  wire [31:0] header_bytes_in_current_packet = PACKET_BODY_OFFSET - axis_packets_byte_reading_complete_count;

  // Packet Splitting Header
  reg  [TDATA_WIDTH - 1:0]          output_header_queue_input_tdata_next;
  reg  [((TDATA_WIDTH / 8)) - 1:0]  output_header_queue_input_tkeep_next;
  reg  [TUSER_WIDTH-1:0]            output_header_queue_input_tuser_next;
  reg                               output_header_queue_input_tlast_next;

  reg                               write_to_output_header_queue_next;

  always @(*) begin
    output_header_queue_input_tdata_next = 0;
    output_header_queue_input_tkeep_next = 0;
    output_header_queue_input_tuser_next = 0;
    output_header_queue_input_tlast_next = 0;

    write_to_output_header_queue_next = 0;

    if (reading_axis_packet) begin
      if (axis_packets_byte_reading_complete_after_current_count <= PACKET_BODY_OFFSET) begin // Read in the entire packet as the header
        output_header_queue_input_tdata_next = axis_in_tdata;
        output_header_queue_input_tkeep_next = axis_in_tkeep;
        output_header_queue_input_tuser_next = axis_in_tuser;
        output_header_queue_input_tlast_next = axis_packets_byte_reading_complete_after_current_count == PACKET_BODY_OFFSET;

        write_to_output_header_queue_next = 1;
      end else if (axis_packets_byte_reading_complete_count < PACKET_BODY_OFFSET) begin
        output_header_queue_input_tdata_next = axis_in_tdata & ((1 << (header_bytes_in_current_packet * 8)) - 1);
        output_header_queue_input_tkeep_next = axis_in_tkeep & ((1 << header_bytes_in_current_packet) - 1);
        output_header_queue_input_tuser_next = axis_in_tuser;
        output_header_queue_input_tlast_next = 1;

        write_to_output_header_queue_next = 1;
      end
    end
  end

  always @(posedge axis_aclk) begin
    output_header_queue_input_tdata = output_header_queue_input_tdata_next;
    output_header_queue_input_tkeep = output_header_queue_input_tkeep_next;
    output_header_queue_input_tuser = output_header_queue_input_tuser_next;
    output_header_queue_input_tlast = output_header_queue_input_tlast_next;

    write_to_output_header_queue = write_to_output_header_queue_next;
  end

  // Packet Splitting Body
  reg  [TDATA_WIDTH - 1:0]          output_body_queue_input_tdata_next;
  reg  [((TDATA_WIDTH / 8)) - 1:0]  output_body_queue_input_tkeep_next;
  reg  [TUSER_WIDTH-1:0]            output_body_queue_input_tuser_next;
  reg                               output_body_queue_input_tlast_next;

  reg                               write_to_output_body_queue_next;

  always @(*) begin
    output_body_queue_input_tdata_next = 0;
    output_body_queue_input_tkeep_next = 0;
    output_body_queue_input_tuser_next = 0;
    output_body_queue_input_tlast_next = 0;

    write_to_output_body_queue_next = 0;

    if (reading_axis_packet) begin
      if (axis_packets_byte_reading_complete_count > PACKET_BODY_OFFSET) begin // Read the entire packet as the body
        output_body_queue_input_tdata_next = axis_in_tdata;
        output_body_queue_input_tkeep_next = axis_in_tkeep;
        output_body_queue_input_tuser_next = axis_in_tuser;
        output_body_queue_input_tlast_next = axis_in_tlast;

        write_to_output_body_queue_next = 1;
      end else if (axis_packets_byte_reading_complete_after_current_count > PACKET_BODY_OFFSET) begin
        output_body_queue_input_tdata_next = axis_in_tdata >> (header_bytes_in_current_packet * 8);
        output_body_queue_input_tkeep_next = axis_in_tkeep >> header_bytes_in_current_packet;
        output_body_queue_input_tuser_next = axis_in_tuser;
        output_body_queue_input_tlast_next = axis_in_tlast;

        write_to_output_body_queue_next = 1;
      end
    end
  end

  always @(posedge axis_aclk) begin
    output_body_queue_input_tdata = output_body_queue_input_tdata_next;
    output_body_queue_input_tkeep = output_body_queue_input_tkeep_next;
    output_body_queue_input_tuser = output_body_queue_input_tuser_next;
    output_body_queue_input_tlast = output_body_queue_input_tlast_next;

    write_to_output_body_queue = write_to_output_body_queue_next;
  end

endmodule

module packet_constructor
#(
  // AXI Stream Data Width
  parameter TDATA_WIDTH         = 256,
  parameter TUSER_WIDTH         = 128
)
(
  input                              axis_aclk,
  input                              axis_resetn,

  input  [TDATA_WIDTH - 1:0]         axis_in_header_tdata,
  input  [((TDATA_WIDTH / 8)) - 1:0] axis_in_header_tkeep,
  input  [TUSER_WIDTH-1:0]           axis_in_header_tuser,
  input                              axis_in_header_tvalid,
  output                             axis_in_header_tready,
  input                              axis_in_header_tlast,

  input  [TDATA_WIDTH - 1:0]         axis_in_body_tdata,
  input  [((TDATA_WIDTH / 8)) - 1:0] axis_in_body_tkeep,
  input  [TUSER_WIDTH-1:0]           axis_in_body_tuser,
  input                              axis_in_body_tvalid,
  output                             axis_in_body_tready,
  input                              axis_in_body_tlast,

  output [TDATA_WIDTH - 1:0]         axis_out_tdata,
  output [((TDATA_WIDTH / 8)) - 1:0] axis_out_tkeep,
  output [TUSER_WIDTH-1:0]           axis_out_tuser,
  output                             axis_out_tvalid,
  input                              axis_out_tready,
  output                             axis_out_tlast
);

  wire [TDATA_WIDTH - 1:0]         unflattened_tdata;
  wire [((TDATA_WIDTH / 8)) - 1:0] unflattened_tkeep;
  wire [TUSER_WIDTH-1:0]           unflattened_tuser;
  wire                             unflattened_tvalid;
  wire                             unflattened_tready;
  wire                             unflattened_tlast;

  packet_combiner combiner
  (
    .axis_aclk(axis_aclk),
    .axis_resetn(axis_resetn),

    .axis_in_header_tdata(axis_in_header_tdata),
    .axis_in_header_tkeep(axis_in_header_tkeep),
    .axis_in_header_tuser(axis_in_header_tuser),
    .axis_in_header_tvalid(axis_in_header_tvalid),
    .axis_in_header_tready(axis_in_header_tready),
    .axis_in_header_tlast(axis_in_header_tlast),

    .axis_in_body_tdata(axis_in_body_tdata),
    .axis_in_body_tkeep(axis_in_body_tkeep),
    .axis_in_body_tuser(axis_in_body_tuser),
    .axis_in_body_tvalid(axis_in_body_tvalid),
    .axis_in_body_tready(axis_in_body_tready),
    .axis_in_body_tlast(axis_in_body_tlast),

    .axis_out_tdata(unflattened_tdata),
    .axis_out_tkeep(unflattened_tkeep),
    .axis_out_tuser(unflattened_tuser),
    .axis_out_tvalid(unflattened_tvalid),
    .axis_out_tready(unflattened_tready),
    .axis_out_tlast(unflattened_tlast)
  );

  axis_flattener flattener
  (
    .axis_aclk(axis_aclk),
    .axis_resetn(axis_resetn),

    .axis_original_tdata(unflattened_tdata),
    .axis_original_tkeep(unflattened_tkeep),
    .axis_original_tuser(unflattened_tuser),
    .axis_original_tvalid(unflattened_tvalid),
    .axis_original_tready(unflattened_tready),
    .axis_original_tlast(unflattened_tlast),

    .axis_flattened_tdata(axis_out_tdata),
    .axis_flattened_tkeep(axis_out_tkeep),
    .axis_flattened_tuser(axis_out_tuser),
    .axis_flattened_tvalid(axis_out_tvalid),
    .axis_flattened_tready(axis_out_tready),
    .axis_flattened_tlast(axis_out_tlast)
  );

endmodule

module packet_combiner
#(
  // AXI Stream Data Width
  parameter TDATA_WIDTH         = 256,
  parameter TUSER_WIDTH         = 128
)
(
  input                              axis_aclk,
  input                              axis_resetn,

  input  [TDATA_WIDTH - 1:0]         axis_in_header_tdata,
  input  [((TDATA_WIDTH / 8)) - 1:0] axis_in_header_tkeep,
  input  [TUSER_WIDTH-1:0]           axis_in_header_tuser,
  input                              axis_in_header_tvalid,
  output                             axis_in_header_tready,
  input                              axis_in_header_tlast,

  input  [TDATA_WIDTH - 1:0]         axis_in_body_tdata,
  input  [((TDATA_WIDTH / 8)) - 1:0] axis_in_body_tkeep,
  input  [TUSER_WIDTH-1:0]           axis_in_body_tuser,
  input                              axis_in_body_tvalid,
  output                             axis_in_body_tready,
  input                              axis_in_body_tlast,

  output [TDATA_WIDTH - 1:0]         axis_out_tdata,
  output [((TDATA_WIDTH / 8)) - 1:0] axis_out_tkeep,
  output [TUSER_WIDTH-1:0]           axis_out_tuser,
  output                             axis_out_tvalid,
  input                              axis_out_tready,
  output                             axis_out_tlast
);
  
  // Output Queue
  reg  [TDATA_WIDTH - 1:0]          output_queue_input_tdata;
  reg  [((TDATA_WIDTH / 8)) - 1:0]  output_queue_input_tkeep;
  reg  [TUSER_WIDTH-1:0]            output_queue_input_tuser;
  reg                               output_queue_input_tlast;

  reg                               write_to_output_queue;
  wire                              read_from_output_queue;

  wire                              output_queue_nearly_full;
  wire                              output_queue_empty;

  fallthrough_small_fifo
  #(
    .WIDTH(TDATA_WIDTH+TUSER_WIDTH+TDATA_WIDTH/8+1), // Fit the whole AXIS packet and the headers
    .MAX_DEPTH_BITS(4)
  )
  output_queue
  (
    .din         ({output_queue_input_tdata, output_queue_input_tkeep, output_queue_input_tuser, output_queue_input_tlast}),
    .wr_en       (write_to_output_queue),
    .rd_en       (read_from_output_queue),
    .dout        ({axis_out_tdata, axis_out_tkeep, axis_out_tuser, axis_out_tlast}),
    .full        (),
    .prog_full   (),
    .nearly_full (output_queue_nearly_full),
    .empty       (output_queue_empty),
    .reset       (~axis_resetn),
    .clk         (axis_aclk)
  );

  assign read_from_output_queue = axis_out_tvalid & axis_out_tready;
  assign axis_out_tvalid = ~output_queue_empty;

  // AXI Packet Input
  wire [TDATA_WIDTH - 1:0]         axis_in_tdata;
  wire [((TDATA_WIDTH / 8)) - 1:0] axis_in_tkeep;
  wire [TUSER_WIDTH-1:0]           axis_in_tuser;
  wire                             axis_in_tvalid;
  wire                             axis_in_tready;
  wire                             axis_in_tlast;

  wire reading_axis_packet = axis_in_tvalid & axis_in_tready;
  assign axis_in_tready = ~output_queue_nearly_full;

  // FSM
  localparam STATE_HEADER = 0;
  localparam STATE_BODY   = 1;

  reg [0:0] state;
  reg [0:0] state_next;

  assign axis_in_tdata = state == STATE_HEADER ? axis_in_header_tdata : axis_in_body_tdata;
  assign axis_in_tkeep = state == STATE_HEADER ? axis_in_header_tkeep : axis_in_body_tkeep;
  assign axis_in_tuser = state == STATE_HEADER ? axis_in_header_tuser : axis_in_body_tuser;
  assign axis_in_tlast = state == STATE_HEADER ? axis_in_header_tlast : axis_in_body_tlast;

  assign axis_in_tvalid = state == STATE_HEADER ? axis_in_header_tvalid : axis_in_body_tvalid;

  assign axis_in_header_tready = state == STATE_HEADER ? axis_in_tready : 0;
  assign axis_in_body_tready   = state == STATE_BODY   ? axis_in_tready : 0;

  always @(*) begin
    state_next = state;

    if (reading_axis_packet & axis_in_tlast) begin
      case (state)
        STATE_HEADER: state_next = STATE_BODY;
        STATE_BODY:   state_next = STATE_HEADER;
      endcase
    end
  end

  always @(posedge axis_aclk) begin
    if (~axis_resetn)
      state = STATE_HEADER;
    else
      state = state_next;
  end

  // AXI Packet Output
  reg  [TDATA_WIDTH - 1:0]          output_queue_input_tdata_next;
  reg  [((TDATA_WIDTH / 8)) - 1:0]  output_queue_input_tkeep_next;
  reg  [TUSER_WIDTH-1:0]            output_queue_input_tuser_next;
  reg                               output_queue_input_tlast_next;

  reg                               write_to_output_queue_next;

  always @(*) begin
    output_queue_input_tdata_next = axis_in_tdata;
    output_queue_input_tkeep_next = axis_in_tkeep;
    output_queue_input_tuser_next = axis_in_tuser;

    if (state == STATE_HEADER)
      output_queue_input_tlast_next = 0;
    else
      output_queue_input_tlast_next = axis_in_tlast;

    write_to_output_queue_next = 0;

    if (reading_axis_packet) write_to_output_queue_next = 1;
  end

  always @(posedge axis_aclk) begin
    output_queue_input_tdata = output_queue_input_tdata_next;
    output_queue_input_tkeep = output_queue_input_tkeep_next;
    output_queue_input_tuser = output_queue_input_tuser_next;
    output_queue_input_tlast = output_queue_input_tlast_next;

    write_to_output_queue = write_to_output_queue_next;
  end
 
endmodule

/*************************************************************************************************\
|* AXI Stream Manipulation
|* =======================
|* The data width converter and AXI Stream flattener.
\*************************************************************************************************/

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

  // Output Queue
  reg [OUT_TDATA_WIDTH - 1:0]            output_queue_tdata;
  reg [(OUT_TDATA_WIDTH / 8) - 1:0]      output_queue_tkeep;
  reg [TUSER_WIDTH - 1:0]                output_queue_tuser;
  reg                                    output_queue_tlast;
  
  reg                                    write_to_output_queue;
  wire                                   output_queue_nearly_full;
  wire                                   output_queue_empty;

  fallthrough_small_fifo
  #(
    .WIDTH(OUT_TDATA_WIDTH+TUSER_WIDTH+OUT_TDATA_WIDTH/8+1),
    .MAX_DEPTH_BITS(4)
  )
  output_fifo
  (
    .din         ({output_queue_tdata, output_queue_tkeep, output_queue_tuser, output_queue_tlast}),
    .wr_en       (write_to_output_queue),
    .rd_en       (send_from_module),
    .dout        ({axis_resize_tdata, axis_resize_tkeep, axis_resize_tuser, axis_resize_tlast}),
    .full        (),
    .prog_full   (),
    .nearly_full (output_queue_nearly_full),
    .empty       (output_queue_empty),
    .reset       (~axis_resetn),
    .clk         (axis_aclk)
  );

  assign send_from_module   = axis_resize_tvalid & axis_resize_tready;
  assign axis_resize_tvalid = ~output_queue_empty;

  // Buffer
  reg  [BUFFER_WIDTH - 1:0]       buffer_tdata;
  reg  [(BUFFER_WIDTH / 8) - 1:0] buffer_tkeep;
  reg  [TUSER_WIDTH - 1:0]        buffer_tuser;
  reg                             buffer_tlast;

  // Move from input to buffer
  wire [BUFFER_WIDTH - 1:0]       buffer_tdata_after_write;
  wire [(BUFFER_WIDTH / 8) - 1:0] buffer_tkeep_after_write;

  copy_into_empty
  #(
    .SRC_DATA_WIDTH(IN_TDATA_WIDTH),
    .DEST_DATA_WIDTH(BUFFER_WIDTH)
  )
  copy_from_input_to_buffer
  (
    .src_data_in(axis_original_tdata),
    .src_keep_in(axis_original_tkeep),

    .dest_data_in(buffer_tdata),
    .dest_keep_in(buffer_tkeep),

    .dest_data_out(buffer_tdata_after_write),
    .dest_keep_out(buffer_tkeep_after_write)
  );

  wire can_move_data_from_input_to_buffer = axis_original_tvalid & ~buffer_tkeep[OUT_TDATA_WIDTH / 8] & ~buffer_tlast;
  
  // Move from buffer to output
  wire [BUFFER_WIDTH - 1:0]          buffer_tdata_after_read;
  wire [(BUFFER_WIDTH / 8) - 1:0]    buffer_tkeep_after_read;

  wire [OUT_TDATA_WIDTH - 1:0]       output_queue_tdata_after_read;
  wire [(OUT_TDATA_WIDTH / 8) - 1:0] output_queue_tkeep_after_read;

  copy_into_empty 
  #(
    .SRC_DATA_WIDTH(BUFFER_WIDTH),
    .DEST_DATA_WIDTH(OUT_TDATA_WIDTH)
  )
  copy_from_buffer_to_output
  (
    .src_data_in(buffer_tdata),
    .src_keep_in(buffer_tkeep),

    .dest_data_in(0),
    .dest_keep_in(0),

    .src_data_out(buffer_tdata_after_read),
    .src_keep_out(buffer_tkeep_after_read),

    .dest_data_out(output_queue_tdata_after_read),
    .dest_keep_out(output_queue_tkeep_after_read)
  );

  wire will_buffer_be_empty_after_read                = ~|buffer_tkeep_after_read;
  wire will_current_network_packet_be_read_after_read = will_buffer_be_empty_after_read & buffer_tlast;
  wire can_move_data_from_buffer_to_output            = ((&output_queue_tkeep_after_read) | will_current_network_packet_be_read_after_read) & ~output_queue_nearly_full;

  // AXI Stream Input
  assign axis_original_tready = ~can_move_data_from_buffer_to_output & can_move_data_from_input_to_buffer;

  // Perform the move
  reg  [BUFFER_WIDTH - 1:0]         buffer_tdata_next;
  reg  [(BUFFER_WIDTH / 8) - 1:0]   buffer_tkeep_next;
  reg  [TUSER_WIDTH - 1:0]          buffer_tuser_next;
  reg                               buffer_tlast_next;

  reg [OUT_TDATA_WIDTH - 1:0]       output_queue_tdata_next;
  reg [(OUT_TDATA_WIDTH / 8) - 1:0] output_queue_tkeep_next;
  reg [TUSER_WIDTH - 1:0]           output_queue_tuser_next;
  reg                               output_queue_tlast_next;

  reg                               write_to_output_queue_next;

  always @(*) begin
    buffer_tdata_next = buffer_tdata;
    buffer_tkeep_next = buffer_tkeep;
    buffer_tuser_next = buffer_tuser;
    buffer_tlast_next = buffer_tlast;

    output_queue_tdata_next = 0;
    output_queue_tkeep_next = 0;
    output_queue_tuser_next = 0;
    output_queue_tlast_next = 0;

    write_to_output_queue_next = 0;

    if (can_move_data_from_buffer_to_output) begin
      buffer_tdata_next = buffer_tdata_after_read;
      buffer_tkeep_next = buffer_tkeep_after_read;
      buffer_tuser_next = will_buffer_be_empty_after_read ? 0 : buffer_tuser;
      buffer_tlast_next = will_buffer_be_empty_after_read ? 0 : buffer_tlast;

      output_queue_tdata_next = output_queue_tdata_after_read;
      output_queue_tkeep_next = output_queue_tkeep_after_read;
      output_queue_tuser_next = buffer_tuser;
      output_queue_tlast_next = will_current_network_packet_be_read_after_read;

      write_to_output_queue_next = 1;
    end else if (can_move_data_from_input_to_buffer) begin
      buffer_tdata_next = buffer_tdata_after_write;
      buffer_tkeep_next = buffer_tkeep_after_write;
      buffer_tuser_next = axis_original_tuser ? axis_original_tuser : buffer_tuser_next;
      buffer_tlast_next = axis_original_tlast;
    end
  end

  always @(posedge axis_aclk) begin
    if (~axis_resetn) begin
      buffer_tdata = 0;
      buffer_tkeep = 0;
      buffer_tuser = 0;
      buffer_tlast = 0;

      output_queue_tdata = 0;
      output_queue_tkeep = 0;
      output_queue_tuser = 0;
      output_queue_tlast = 0;

      write_to_output_queue = 0;
    end else begin
      buffer_tdata = buffer_tdata_next;
      buffer_tkeep = buffer_tkeep_next;
      buffer_tuser = buffer_tuser_next;
      buffer_tlast = buffer_tlast_next;

      output_queue_tdata = output_queue_tdata_next;
      output_queue_tkeep = output_queue_tkeep_next;
      output_queue_tuser = output_queue_tuser_next;
      output_queue_tlast = output_queue_tlast_next;

      write_to_output_queue = write_to_output_queue_next;
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

  axis_data_width_converter
  #(
    .IN_TDATA_WIDTH(TDATA_WIDTH),
    .OUT_TDATA_WIDTH(SMALL_TDATA_WIDTH),
    .TUSER_WIDTH(TUSER_WIDTH)
  )
  data_width_shrinker
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
      hex_value = struct.unpack('<I', struct.pack('>f', f))[0]
      return hex_value

    for i in range(256):
      f = i / 255.0
      hex_value = float_to_hex(f)
      print(f"float_table[{i}] = 32'h{hex_value:08x}; // {f}")
    */
    if (~axis_resetn) begin
      float_table[0]   = 32'h00000000; // 0.0
      float_table[1]   = 32'h8180803b; // 0.00392156862745098
      float_table[2]   = 32'h8180003c; // 0.00784313725490196
      float_table[3]   = 32'hc1c0403c; // 0.011764705882352941
      float_table[4]   = 32'h8180803c; // 0.01568627450980392
      float_table[5]   = 32'ha1a0a03c; // 0.0196078431372549
      float_table[6]   = 32'hc1c0c03c; // 0.023529411764705882
      float_table[7]   = 32'he1e0e03c; // 0.027450980392156862
      float_table[8]   = 32'h8180003d; // 0.03137254901960784
      float_table[9]   = 32'h9190103d; // 0.03529411764705882
      float_table[10]  = 32'ha1a0203d; // 0.0392156862745098
      float_table[11]  = 32'hb1b0303d; // 0.043137254901960784
      float_table[12]  = 32'hc1c0403d; // 0.047058823529411764
      float_table[13]  = 32'hd1d0503d; // 0.050980392156862744
      float_table[14]  = 32'he1e0603d; // 0.054901960784313725
      float_table[15]  = 32'hf1f0703d; // 0.058823529411764705
      float_table[16]  = 32'h8180803d; // 0.06274509803921569
      float_table[17]  = 32'h8988883d; // 0.06666666666666667
      float_table[18]  = 32'h9190903d; // 0.07058823529411765
      float_table[19]  = 32'h9998983d; // 0.07450980392156863
      float_table[20]  = 32'ha1a0a03d; // 0.0784313725490196
      float_table[21]  = 32'ha9a8a83d; // 0.08235294117647059
      float_table[22]  = 32'hb1b0b03d; // 0.08627450980392157
      float_table[23]  = 32'hb9b8b83d; // 0.09019607843137255
      float_table[24]  = 32'hc1c0c03d; // 0.09411764705882353
      float_table[25]  = 32'hc9c8c83d; // 0.09803921568627451
      float_table[26]  = 32'hd1d0d03d; // 0.10196078431372549
      float_table[27]  = 32'hd9d8d83d; // 0.10588235294117647
      float_table[28]  = 32'he1e0e03d; // 0.10980392156862745
      float_table[29]  = 32'he9e8e83d; // 0.11372549019607843
      float_table[30]  = 32'hf1f0f03d; // 0.11764705882352941
      float_table[31]  = 32'hf9f8f83d; // 0.12156862745098039
      float_table[32]  = 32'h8180003e; // 0.12549019607843137
      float_table[33]  = 32'h8584043e; // 0.12941176470588237
      float_table[34]  = 32'h8988083e; // 0.13333333333333333
      float_table[35]  = 32'h8d8c0c3e; // 0.13725490196078433
      float_table[36]  = 32'h9190103e; // 0.1411764705882353
      float_table[37]  = 32'h9594143e; // 0.1450980392156863
      float_table[38]  = 32'h9998183e; // 0.14901960784313725
      float_table[39]  = 32'h9d9c1c3e; // 0.15294117647058825
      float_table[40]  = 32'ha1a0203e; // 0.1568627450980392
      float_table[41]  = 32'ha5a4243e; // 0.1607843137254902
      float_table[42]  = 32'ha9a8283e; // 0.16470588235294117
      float_table[43]  = 32'hadac2c3e; // 0.16862745098039217
      float_table[44]  = 32'hb1b0303e; // 0.17254901960784313
      float_table[45]  = 32'hb5b4343e; // 0.17647058823529413
      float_table[46]  = 32'hb9b8383e; // 0.1803921568627451
      float_table[47]  = 32'hbdbc3c3e; // 0.1843137254901961
      float_table[48]  = 32'hc1c0403e; // 0.18823529411764706
      float_table[49]  = 32'hc5c4443e; // 0.19215686274509805
      float_table[50]  = 32'hc9c8483e; // 0.19607843137254902
      float_table[51]  = 32'hcdcc4c3e; // 0.2
      float_table[52]  = 32'hd1d0503e; // 0.20392156862745098
      float_table[53]  = 32'hd5d4543e; // 0.20784313725490197
      float_table[54]  = 32'hd9d8583e; // 0.21176470588235294
      float_table[55]  = 32'hdddc5c3e; // 0.21568627450980393
      float_table[56]  = 32'he1e0603e; // 0.2196078431372549
      float_table[57]  = 32'he5e4643e; // 0.2235294117647059
      float_table[58]  = 32'he9e8683e; // 0.22745098039215686
      float_table[59]  = 32'hedec6c3e; // 0.23137254901960785
      float_table[60]  = 32'hf1f0703e; // 0.23529411764705882
      float_table[61]  = 32'hf5f4743e; // 0.23921568627450981
      float_table[62]  = 32'hf9f8783e; // 0.24313725490196078
      float_table[63]  = 32'hfdfc7c3e; // 0.24705882352941178
      float_table[64]  = 32'h8180803e; // 0.25098039215686274
      float_table[65]  = 32'h8382823e; // 0.2549019607843137
      float_table[66]  = 32'h8584843e; // 0.25882352941176473
      float_table[67]  = 32'h8786863e; // 0.2627450980392157
      float_table[68]  = 32'h8988883e; // 0.26666666666666666
      float_table[69]  = 32'h8b8a8a3e; // 0.27058823529411763
      float_table[70]  = 32'h8d8c8c3e; // 0.27450980392156865
      float_table[71]  = 32'h8f8e8e3e; // 0.2784313725490196
      float_table[72]  = 32'h9190903e; // 0.2823529411764706
      float_table[73]  = 32'h9392923e; // 0.28627450980392155
      float_table[74]  = 32'h9594943e; // 0.2901960784313726
      float_table[75]  = 32'h9796963e; // 0.29411764705882354
      float_table[76]  = 32'h9998983e; // 0.2980392156862745
      float_table[77]  = 32'h9b9a9a3e; // 0.30196078431372547
      float_table[78]  = 32'h9d9c9c3e; // 0.3058823529411765
      float_table[79]  = 32'h9f9e9e3e; // 0.30980392156862746
      float_table[80]  = 32'ha1a0a03e; // 0.3137254901960784
      float_table[81]  = 32'ha3a2a23e; // 0.3176470588235294
      float_table[82]  = 32'ha5a4a43e; // 0.3215686274509804
      float_table[83]  = 32'ha7a6a63e; // 0.3254901960784314
      float_table[84]  = 32'ha9a8a83e; // 0.32941176470588235
      float_table[85]  = 32'habaaaa3e; // 0.3333333333333333
      float_table[86]  = 32'hadacac3e; // 0.33725490196078434
      float_table[87]  = 32'hafaeae3e; // 0.3411764705882353
      float_table[88]  = 32'hb1b0b03e; // 0.34509803921568627
      float_table[89]  = 32'hb3b2b23e; // 0.34901960784313724
      float_table[90]  = 32'hb5b4b43e; // 0.35294117647058826
      float_table[91]  = 32'hb7b6b63e; // 0.3568627450980392
      float_table[92]  = 32'hb9b8b83e; // 0.3607843137254902
      float_table[93]  = 32'hbbbaba3e; // 0.36470588235294116
      float_table[94]  = 32'hbdbcbc3e; // 0.3686274509803922
      float_table[95]  = 32'hbfbebe3e; // 0.37254901960784315
      float_table[96]  = 32'hc1c0c03e; // 0.3764705882352941
      float_table[97]  = 32'hc3c2c23e; // 0.3803921568627451
      float_table[98]  = 32'hc5c4c43e; // 0.3843137254901961
      float_table[99]  = 32'hc7c6c63e; // 0.38823529411764707
      float_table[100] = 32'hc9c8c83e; // 0.39215686274509803
      float_table[101] = 32'hcbcaca3e; // 0.396078431372549
      float_table[102] = 32'hcdcccc3e; // 0.4
      float_table[103] = 32'hcfcece3e; // 0.403921568627451
      float_table[104] = 32'hd1d0d03e; // 0.40784313725490196
      float_table[105] = 32'hd3d2d23e; // 0.4117647058823529
      float_table[106] = 32'hd5d4d43e; // 0.41568627450980394
      float_table[107] = 32'hd7d6d63e; // 0.4196078431372549
      float_table[108] = 32'hd9d8d83e; // 0.4235294117647059
      float_table[109] = 32'hdbdada3e; // 0.42745098039215684
      float_table[110] = 32'hdddcdc3e; // 0.43137254901960786
      float_table[111] = 32'hdfdede3e; // 0.43529411764705883
      float_table[112] = 32'he1e0e03e; // 0.4392156862745098
      float_table[113] = 32'he3e2e23e; // 0.44313725490196076
      float_table[114] = 32'he5e4e43e; // 0.4470588235294118
      float_table[115] = 32'he7e6e63e; // 0.45098039215686275
      float_table[116] = 32'he9e8e83e; // 0.4549019607843137
      float_table[117] = 32'hebeaea3e; // 0.4588235294117647
      float_table[118] = 32'hedecec3e; // 0.4627450980392157
      float_table[119] = 32'hefeeee3e; // 0.4666666666666667
      float_table[120] = 32'hf1f0f03e; // 0.47058823529411764
      float_table[121] = 32'hf3f2f23e; // 0.4745098039215686
      float_table[122] = 32'hf5f4f43e; // 0.47843137254901963
      float_table[123] = 32'hf7f6f63e; // 0.4823529411764706
      float_table[124] = 32'hf9f8f83e; // 0.48627450980392156
      float_table[125] = 32'hfbfafa3e; // 0.49019607843137253
      float_table[126] = 32'hfdfcfc3e; // 0.49411764705882355
      float_table[127] = 32'hfffefe3e; // 0.4980392156862745
      float_table[128] = 32'h8180003f; // 0.5019607843137255
      float_table[129] = 32'h8281013f; // 0.5058823529411764
      float_table[130] = 32'h8382023f; // 0.5098039215686274
      float_table[131] = 32'h8483033f; // 0.5137254901960784
      float_table[132] = 32'h8584043f; // 0.5176470588235295
      float_table[133] = 32'h8685053f; // 0.5215686274509804
      float_table[134] = 32'h8786063f; // 0.5254901960784314
      float_table[135] = 32'h8887073f; // 0.5294117647058824
      float_table[136] = 32'h8988083f; // 0.5333333333333333
      float_table[137] = 32'h8a89093f; // 0.5372549019607843
      float_table[138] = 32'h8b8a0a3f; // 0.5411764705882353
      float_table[139] = 32'h8c8b0b3f; // 0.5450980392156862
      float_table[140] = 32'h8d8c0c3f; // 0.5490196078431373
      float_table[141] = 32'h8e8d0d3f; // 0.5529411764705883
      float_table[142] = 32'h8f8e0e3f; // 0.5568627450980392
      float_table[143] = 32'h908f0f3f; // 0.5607843137254902
      float_table[144] = 32'h9190103f; // 0.5647058823529412
      float_table[145] = 32'h9291113f; // 0.5686274509803921
      float_table[146] = 32'h9392123f; // 0.5725490196078431
      float_table[147] = 32'h9493133f; // 0.5764705882352941
      float_table[148] = 32'h9594143f; // 0.5803921568627451
      float_table[149] = 32'h9695153f; // 0.5843137254901961
      float_table[150] = 32'h9796163f; // 0.5882352941176471
      float_table[151] = 32'h9897173f; // 0.592156862745098
      float_table[152] = 32'h9998183f; // 0.596078431372549
      float_table[153] = 32'h9a99193f; // 0.6
      float_table[154] = 32'h9b9a1a3f; // 0.6039215686274509
      float_table[155] = 32'h9c9b1b3f; // 0.6078431372549019
      float_table[156] = 32'h9d9c1c3f; // 0.611764705882353
      float_table[157] = 32'h9e9d1d3f; // 0.615686274509804
      float_table[158] = 32'h9f9e1e3f; // 0.6196078431372549
      float_table[159] = 32'ha09f1f3f; // 0.6235294117647059
      float_table[160] = 32'ha1a0203f; // 0.6274509803921569
      float_table[161] = 32'ha2a1213f; // 0.6313725490196078
      float_table[162] = 32'ha3a2223f; // 0.6352941176470588
      float_table[163] = 32'ha4a3233f; // 0.6392156862745098
      float_table[164] = 32'ha5a4243f; // 0.6431372549019608
      float_table[165] = 32'ha6a5253f; // 0.6470588235294118
      float_table[166] = 32'ha7a6263f; // 0.6509803921568628
      float_table[167] = 32'ha8a7273f; // 0.6549019607843137
      float_table[168] = 32'ha9a8283f; // 0.6588235294117647
      float_table[169] = 32'haaa9293f; // 0.6627450980392157
      float_table[170] = 32'habaa2a3f; // 0.6666666666666666
      float_table[171] = 32'hacab2b3f; // 0.6705882352941176
      float_table[172] = 32'hadac2c3f; // 0.6745098039215687
      float_table[173] = 32'haead2d3f; // 0.6784313725490196
      float_table[174] = 32'hafae2e3f; // 0.6823529411764706
      float_table[175] = 32'hb0af2f3f; // 0.6862745098039216
      float_table[176] = 32'hb1b0303f; // 0.6901960784313725
      float_table[177] = 32'hb2b1313f; // 0.6941176470588235
      float_table[178] = 32'hb3b2323f; // 0.6980392156862745
      float_table[179] = 32'hb4b3333f; // 0.7019607843137254
      float_table[180] = 32'hb5b4343f; // 0.7058823529411765
      float_table[181] = 32'hb6b5353f; // 0.7098039215686275
      float_table[182] = 32'hb7b6363f; // 0.7137254901960784
      float_table[183] = 32'hb8b7373f; // 0.7176470588235294
      float_table[184] = 32'hb9b8383f; // 0.7215686274509804
      float_table[185] = 32'hbab9393f; // 0.7254901960784313
      float_table[186] = 32'hbbba3a3f; // 0.7294117647058823
      float_table[187] = 32'hbcbb3b3f; // 0.7333333333333333
      float_table[188] = 32'hbdbc3c3f; // 0.7372549019607844
      float_table[189] = 32'hbebd3d3f; // 0.7411764705882353
      float_table[190] = 32'hbfbe3e3f; // 0.7450980392156863
      float_table[191] = 32'hc0bf3f3f; // 0.7490196078431373
      float_table[192] = 32'hc1c0403f; // 0.7529411764705882
      float_table[193] = 32'hc2c1413f; // 0.7568627450980392
      float_table[194] = 32'hc3c2423f; // 0.7607843137254902
      float_table[195] = 32'hc4c3433f; // 0.7647058823529411
      float_table[196] = 32'hc5c4443f; // 0.7686274509803922
      float_table[197] = 32'hc6c5453f; // 0.7725490196078432
      float_table[198] = 32'hc7c6463f; // 0.7764705882352941
      float_table[199] = 32'hc8c7473f; // 0.7803921568627451
      float_table[200] = 32'hc9c8483f; // 0.7843137254901961
      float_table[201] = 32'hcac9493f; // 0.788235294117647
      float_table[202] = 32'hcbca4a3f; // 0.792156862745098
      float_table[203] = 32'hcccb4b3f; // 0.796078431372549
      float_table[204] = 32'hcdcc4c3f; // 0.8
      float_table[205] = 32'hcecd4d3f; // 0.803921568627451
      float_table[206] = 32'hcfce4e3f; // 0.807843137254902
      float_table[207] = 32'hd0cf4f3f; // 0.8117647058823529
      float_table[208] = 32'hd1d0503f; // 0.8156862745098039
      float_table[209] = 32'hd2d1513f; // 0.8196078431372549
      float_table[210] = 32'hd3d2523f; // 0.8235294117647058
      float_table[211] = 32'hd4d3533f; // 0.8274509803921568
      float_table[212] = 32'hd5d4543f; // 0.8313725490196079
      float_table[213] = 32'hd6d5553f; // 0.8352941176470589
      float_table[214] = 32'hd7d6563f; // 0.8392156862745098
      float_table[215] = 32'hd8d7573f; // 0.8431372549019608
      float_table[216] = 32'hd9d8583f; // 0.8470588235294118
      float_table[217] = 32'hdad9593f; // 0.8509803921568627
      float_table[218] = 32'hdbda5a3f; // 0.8549019607843137
      float_table[219] = 32'hdcdb5b3f; // 0.8588235294117647
      float_table[220] = 32'hdddc5c3f; // 0.8627450980392157
      float_table[221] = 32'hdedd5d3f; // 0.8666666666666667
      float_table[222] = 32'hdfde5e3f; // 0.8705882352941177
      float_table[223] = 32'he0df5f3f; // 0.8745098039215686
      float_table[224] = 32'he1e0603f; // 0.8784313725490196
      float_table[225] = 32'he2e1613f; // 0.8823529411764706
      float_table[226] = 32'he3e2623f; // 0.8862745098039215
      float_table[227] = 32'he4e3633f; // 0.8901960784313725
      float_table[228] = 32'he5e4643f; // 0.8941176470588236
      float_table[229] = 32'he6e5653f; // 0.8980392156862745
      float_table[230] = 32'he7e6663f; // 0.9019607843137255
      float_table[231] = 32'he8e7673f; // 0.9058823529411765
      float_table[232] = 32'he9e8683f; // 0.9098039215686274
      float_table[233] = 32'heae9693f; // 0.9137254901960784
      float_table[234] = 32'hebea6a3f; // 0.9176470588235294
      float_table[235] = 32'heceb6b3f; // 0.9215686274509803
      float_table[236] = 32'hedec6c3f; // 0.9254901960784314
      float_table[237] = 32'heeed6d3f; // 0.9294117647058824
      float_table[238] = 32'hefee6e3f; // 0.9333333333333333
      float_table[239] = 32'hf0ef6f3f; // 0.9372549019607843
      float_table[240] = 32'hf1f0703f; // 0.9411764705882353
      float_table[241] = 32'hf2f1713f; // 0.9450980392156862
      float_table[242] = 32'hf3f2723f; // 0.9490196078431372
      float_table[243] = 32'hf4f3733f; // 0.9529411764705882
      float_table[244] = 32'hf5f4743f; // 0.9568627450980393
      float_table[245] = 32'hf6f5753f; // 0.9607843137254902
      float_table[246] = 32'hf7f6763f; // 0.9647058823529412
      float_table[247] = 32'hf8f7773f; // 0.9686274509803922
      float_table[248] = 32'hf9f8783f; // 0.9725490196078431
      float_table[249] = 32'hfaf9793f; // 0.9764705882352941
      float_table[250] = 32'hfbfa7a3f; // 0.9803921568627451
      float_table[251] = 32'hfcfb7b3f; // 0.984313725490196
      float_table[252] = 32'hfdfc7c3f; // 0.9882352941176471
      float_table[253] = 32'hfefd7d3f; // 0.9921568627450981
      float_table[254] = 32'hfffe7e3f; // 0.996078431372549
      float_table[255] = 32'h0000803f; // 1.0
    end
  end

endmodule