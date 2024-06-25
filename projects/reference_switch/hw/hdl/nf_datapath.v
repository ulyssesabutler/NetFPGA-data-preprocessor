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

  wire [TDATA_WIDTH - 1:0]         axis_body_tdata;
  wire [((TDATA_WIDTH / 8)) - 1:0] axis_body_tkeep;
  wire [TUSER_WIDTH-1:0]           axis_body_tuser;
  wire                             axis_body_tvalid;
  wire                             axis_body_tready;
  wire                             axis_body_tlast;

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

    .axis_out_body_tdata(axis_body_tdata),
    .axis_out_body_tkeep(axis_body_tkeep),
    .axis_out_body_tuser(axis_body_tuser),
    .axis_out_body_tvalid(axis_body_tvalid),
    .axis_out_body_tready(axis_body_tready),
    .axis_out_body_tlast(axis_body_tlast)
  );

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

    .axis_in_body_tdata(axis_body_tdata),
    .axis_in_body_tkeep(axis_body_tkeep),
    .axis_in_body_tuser(axis_body_tuser),
    .axis_in_body_tvalid(axis_body_tvalid),
    .axis_in_body_tready(axis_body_tready),
    .axis_in_body_tlast(axis_body_tlast),

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
