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
//////////////////////////////////////////////////////////////////////////////////
// Company:  Uni Cambridge
// Engineer: Y. Audzevich
//
// Create Date: 07/09/2015 22:21:32
// Module Name: nf_naudit_dma
// Description: PCIe DMA controller instantiation and PCIe tie-offs.
//
// Dependencies: pcie_controller
//////////////////////////////////////////////////////////////////////////////////


`timescale 1ps/1ps
`default_nettype none

module nf_naudit_dma #(
  parameter      C_USE_VIRTUALIZATION = 0,  // 0 - False, 1 - True
  parameter      C_NUMBER_IOV         = 1,  // Number of virtual devices if c_use_virtualization == TRUE
  parameter      C_NUMBER_DEVICES  = C_USE_VIRTUALIZATION ? C_NUMBER_IOV : 1
)
(
  // ============================
  // Used or produced by UAM DMA
  // ============================

  // clock and reset
  input wire                                    user_clk,
  input wire                                    user_reset,
  input wire                                    user_lnk_up,
  input wire                                    user_app_rdy,

  // Requester Interface
 /*
  output wire                                    s_axis_rq_tlast,
  output wire  [255:0]                           s_axis_rq_tdata,
  output wire  [59:0]                            s_axis_rq_tuser,
  output wire  [7:0]                             s_axis_rq_tkeep,
  input wire   [3:0]                             s_axis_rq_tready,
  output wire                                    s_axis_rq_tvalid,

  input wire  [255:0]                            m_axis_rc_tdata,
  input wire  [74:0]                             m_axis_rc_tuser,
  input wire                                     m_axis_rc_tlast,
  input wire  [7:0]                              m_axis_rc_tkeep,
  input wire                                     m_axis_rc_tvalid,
  output wire [21:0]                             m_axis_rc_tready,
  */

  output                                     s_axis_rq_tlast,
  output   [255:0]                           s_axis_rq_tdata,
  output   [59:0]                            s_axis_rq_tuser,
  output   [7:0]                             s_axis_rq_tkeep,
  input    [3:0]                             s_axis_rq_tready,
  output                                     s_axis_rq_tvalid,

  input   [255:0]                            m_axis_rc_tdata,
  input   [74:0]                             m_axis_rc_tuser,
  input                                      m_axis_rc_tlast,
  input   [7:0]                              m_axis_rc_tkeep,
  input                                      m_axis_rc_tvalid,
  output  [21:0]                             m_axis_rc_tready,


  // Completer Interface
  input wire  [255:0]                            m_axis_cq_tdata,
  input wire  [84:0]                             m_axis_cq_tuser,
  input wire                                     m_axis_cq_tlast,
  input wire  [7:0]                              m_axis_cq_tkeep,
  input wire                                     m_axis_cq_tvalid,
  output wire [21:0]                             m_axis_cq_tready,

  output wire [255:0]                            s_axis_cc_tdata,
  output wire [32:0]                             s_axis_cc_tuser,
  output wire                                    s_axis_cc_tlast,
  output wire [7:0]                              s_axis_cc_tkeep,
  output wire                                    s_axis_cc_tvalid,
  input wire  [3:0]                              s_axis_cc_tready,

  // MSI-x Interrupts
  input wire  [1:0]                              cfg_interrupt_msix_enable,
  input wire  [1:0]                              cfg_interrupt_msix_mask,
  input wire  [5:0]                              cfg_interrupt_msix_vf_enable,
  input wire  [5:0]                              cfg_interrupt_msix_vf_mask,
  output wire [31:0]                             cfg_interrupt_msix_data,
  output wire [63:0]                             cfg_interrupt_msix_address,
  output wire                                    cfg_interrupt_msix_int,
  input wire                                     cfg_interrupt_msix_sent,
  input wire                                     cfg_interrupt_msix_fail,

  // Credits
  input wire  [1:0]                              pcie_tfc_nph_av,
  input wire  [1:0]                              pcie_tfc_npd_av,

  // AXI4-Lite Master Interface
  input wire                                     m_axi_lite_aclk,
  input wire                                     m_axi_lite_aresetn,
  input wire                                     m_axi_lite_arready,
  output wire                                    m_axi_lite_arvalid,
  output wire [31:0]                             m_axi_lite_araddr,
  output wire [2:0]                              m_axi_lite_arprot,
  output wire                                    m_axi_lite_rready,
  input wire                                     m_axi_lite_rvalid,
  input wire  [31:0]                             m_axi_lite_rdata,
  input wire  [1:0]                              m_axi_lite_rresp,
  input wire                                     m_axi_lite_awready,
  output wire                                    m_axi_lite_awvalid,
  output wire [31:0]                             m_axi_lite_awaddr,
  output wire [2:0]                              m_axi_lite_awprot,
  input wire                                     m_axi_lite_wready,
  output wire                                    m_axi_lite_wvalid,
  output wire [31:0]                             m_axi_lite_wdata,
  output wire [3:0]                              m_axi_lite_wstrb,
  output wire                                    m_axi_lite_bready,
  input wire                                     m_axi_lite_bvalid,
  input wire  [1:0]                              m_axi_lite_bresp,


  // Slave AXI Ports
  input wire  [11:0]     			            s_axi_lite_awaddr,
  input wire                                  	s_axi_lite_awvalid,
  input wire  [31:0]     			            s_axi_lite_wdata,
  input wire  [3:0]   				            s_axi_lite_wstrb,
  input wire                                  	s_axi_lite_wvalid,
  input wire                                   	s_axi_lite_bready,
  input wire  [11:0]     			            s_axi_lite_araddr,
  input wire                                  	s_axi_lite_arvalid,
  input wire                                   	s_axi_lite_rready,
  output wire                                  	s_axi_lite_arready,
  output wire [31:0]     			            s_axi_lite_rdata,
  output wire [1:0]                        	    s_axi_lite_rresp,
  output wire                                 	s_axi_lite_rvalid,
  output wire                                  	s_axi_lite_wready,
  output wire [1:0]                         	s_axi_lite_bresp,
  output wire                                  	s_axi_lite_bvalid,
  output wire                                  	s_axi_lite_awready,

  // AXIS Interfaces
  output wire  [C_NUMBER_DEVICES-1:0]      	    s2c_tvalid,
  input wire  [C_NUMBER_DEVICES-1:0]     	    s2c_tready,
  output wire  [256*C_NUMBER_DEVICES-1:0]   	s2c_tdata,
  output wire  [128*C_NUMBER_DEVICES-1:0]  	    s2c_tuser,
  output wire  [C_NUMBER_DEVICES-1:0]      	    s2c_tlast,
  output wire  [32*C_NUMBER_DEVICES-1:0]    	s2c_tkeep,

  output wire  [C_NUMBER_DEVICES-1:0]      	    c2s_tready,
  input wire  [256*C_NUMBER_DEVICES-1:0]  	    c2s_tdata,
  input wire  [128*C_NUMBER_DEVICES-1:0]  	    c2s_tuser,
  input wire  [C_NUMBER_DEVICES-1:0]      	    c2s_tlast,
  input wire  [C_NUMBER_DEVICES-1:0]      	    c2s_tvalid,
  input wire  [32*C_NUMBER_DEVICES-1:0]    	    c2s_tkeep,

  // ==================================
  // Used or produced by PCIe endpoint
  // ==================================

  // Configuration (CFG) Interface                                                                                  //
  input wire  [3:0]                              pcie_rq_seq_num,
  input wire                                     pcie_rq_seq_num_vld,
  input wire  [5:0]                              pcie_rq_tag,
  input wire                                     pcie_rq_tag_vld,

  output wire                                    pcie_cq_np_req,
  input wire  [5:0]                              pcie_cq_np_req_count,

  input wire                                     cfg_phy_link_down,
  input wire  [1:0]                              cfg_phy_link_status,
  input wire  [3:0]                              cfg_negotiated_width,
  input wire  [2:0]                              cfg_current_speed,
  input wire  [2:0]                              cfg_max_payload,
  input wire  [2:0]                              cfg_max_read_req,
  input wire  [7:0]                              cfg_function_status,
  input wire  [5:0]                              cfg_function_power_state,
  input wire  [11:0]                             cfg_vf_status,
  input wire  [17:0]                             cfg_vf_power_state,
  input wire  [1:0]                              cfg_link_power_state,

  // Error Reporting Interface
  input wire                                     cfg_err_cor_out,
  input wire                                     cfg_err_nonfatal_out,
  input wire                                     cfg_err_fatal_out,

  input wire                                     cfg_ltr_enable,
  input wire  [5:0]                              cfg_ltssm_state,
  input wire  [1:0]                              cfg_rcb_status,
  input wire  [1:0]                              cfg_dpa_substate_change,
  input wire  [1:0]                              cfg_obff_enable,
  input wire                                     cfg_pl_status_change,

  input wire  [1:0]                              cfg_tph_requester_enable,
  input wire  [5:0]                              cfg_tph_st_mode,
  input wire  [5:0]                              cfg_vf_tph_requester_enable,
  input wire  [17:0]                             cfg_vf_tph_st_mode,

  // Management Interface
  output wire  [18:0]                            cfg_mgmt_addr,
  output wire                                    cfg_mgmt_write,
  output wire  [31:0]                            cfg_mgmt_write_data,
  output wire  [3:0]                             cfg_mgmt_byte_enable,
  output wire                                    cfg_mgmt_read,
  input wire  [31:0]                             cfg_mgmt_read_data,
  input wire                                     cfg_mgmt_read_write_done,
  output wire                                    cfg_mgmt_type1_cfg_reg_access,
  input wire                                     cfg_msg_received,
  input wire  [7:0]                              cfg_msg_received_data,
  input wire  [4:0]                              cfg_msg_received_type,
  output wire                                    cfg_msg_transmit,
  output wire   [2:0]                            cfg_msg_transmit_type,
  output wire   [31:0]                           cfg_msg_transmit_data,
  input wire                                     cfg_msg_transmit_done,
  input wire  [7:0]                              cfg_fc_ph,
  input wire  [11:0]                             cfg_fc_pd,
  input wire  [7:0]                              cfg_fc_nph,
  input wire  [11:0]                             cfg_fc_npd,
  input wire  [7:0]                              cfg_fc_cplh,
  input wire  [11:0]                             cfg_fc_cpld,
  output wire   [2:0]                            cfg_fc_sel,
  output wire   [2:0]                            cfg_per_func_status_control,
  input wire  [15:0]                             cfg_per_func_status_data,
  output wire   [15:0]                           cfg_subsys_vend_id,
  input wire                                     cfg_hot_reset_out,
  output wire                                    cfg_config_space_enable,
  output wire                                    cfg_req_pm_transition_l23_ready,
  output wire                                    cfg_hot_reset_in,
  output wire  [7:0]                             cfg_ds_port_number,
  output wire  [7:0]                             cfg_ds_bus_number,
  output wire  [4:0]                             cfg_ds_device_number,
  output wire  [2:0]                             cfg_ds_function_number,
  output wire  [2:0]                             cfg_per_function_number,
  output wire                                    cfg_per_function_output_request,
  input wire                                     cfg_per_function_update_done,
  output wire   [63:0]                           cfg_dsn,
  input wire                                     cfg_power_state_change_interrupt,
  output wire                                    cfg_power_state_change_ack,
  output wire                                    cfg_err_cor_in,
  output wire                                    cfg_err_uncor_in,
  input wire  [1:0]                              cfg_flr_in_process,
  output wire   [1:0]                            cfg_flr_done,
  input wire  [5:0]                              cfg_vf_flr_in_process,
  output wire   [5:0]                            cfg_vf_flr_done,
  output wire                                    cfg_link_training_enable,
  input wire                                     cfg_ext_read_received,
  input wire                                     cfg_ext_write_received,
  input wire  [9:0]                              cfg_ext_register_number,
  input wire  [7:0]                              cfg_ext_function_number,
  input wire  [31:0]                             cfg_ext_write_data,
  input wire  [3:0]                              cfg_ext_write_byte_enable,
  output wire   [31:0]                           cfg_ext_read_data,
  output wire                                    cfg_ext_read_data_valid,

  // Interrupt Interface Signals
  output wire   [3:0]                            cfg_interrupt_int,
  output wire  [1:0]                             cfg_interrupt_pending,
  input wire                                     cfg_interrupt_sent,
  input wire  [1:0]                              cfg_interrupt_msi_enable,
  input wire  [5:0]                              cfg_interrupt_msi_vf_enable,
  input wire [5:0]                               cfg_interrupt_msi_mmenable,
  input wire                                     cfg_interrupt_msi_mask_update,
  input wire [31:0]                              cfg_interrupt_msi_data,
  output wire  [3:0]                             cfg_interrupt_msi_select,
  output wire  [31:0]                            cfg_interrupt_msi_int,
  output wire  [63:0]                            cfg_interrupt_msi_pending_status,
  input wire                                     cfg_interrupt_msi_sent,
  input wire                                     cfg_interrupt_msi_fail,
  output wire   [2:0]                            cfg_interrupt_msi_attr,
  output wire                                    cfg_interrupt_msi_tph_present,
  output wire  [1:0]                             cfg_interrupt_msi_tph_type,
  output wire  [8:0]                             cfg_interrupt_msi_tph_st_tag,
  output wire  [2:0]                             cfg_interrupt_msi_function_number
);

  /////////////////////////////////////////////////////////////
  /////////////// DEBUG ONLY /////////////
  wire                                    s_axis_rq_tlast;
  wire  [255:0]                           s_axis_rq_tdata;
  wire  [59:0]                            s_axis_rq_tuser;
  wire  [7:0]                             s_axis_rq_tkeep;
  wire   [3:0]                            s_axis_rq_tready;
  wire                                    s_axis_rq_tvalid;

  wire  [255:0]                            m_axis_rc_tdata;
  wire  [74:0]                             m_axis_rc_tuser;
  wire                                     m_axis_rc_tlast;
  wire  [7:0]                              m_axis_rc_tkeep;
  wire                                     m_axis_rc_tvalid;
  wire [21:0]                              m_axis_rc_tready;
  ////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////
  //////           DMA related logic                      //////
  //////////////////////////////////////////////////////////////

  ////////////////
  // PCIe reset //
  ////////////////

  reg pcie_reset;

  always @(posedge user_clk) begin
    if (user_reset || !user_app_rdy) begin
      pcie_reset <= 1;
    end else if (user_app_rdy) begin
      pcie_reset <= 0;
    end
  end

  //////////////////////////////
  // AXI-Lite Clock and Reset //
  //////////////////////////////

  //////////////////////////////
  // PCIe ready & valid       //
  //////////////////////////////
  wire m_axis_rc_tready_bit;
  wire m_axis_cq_tready_bit;
  wire s_axis_rq_tready_bit;
  wire s_axis_cc_tready_bit;

  assign m_axis_rc_tready       = {22{m_axis_rc_tready_bit}};
  assign m_axis_cq_tready       = {22{m_axis_cq_tready_bit}};
  assign s_axis_rq_tready_bit   = s_axis_rq_tready[0];
  assign s_axis_cc_tready_bit   = s_axis_cc_tready[0];

  wire  [C_NUMBER_DEVICES-1:0]     tx_s2c_tvalid;
  wire  [C_NUMBER_DEVICES-1:0]     tx_s2c_tready;
  wire  [256*C_NUMBER_DEVICES-1:0] tx_s2c_tdata;
  wire  [C_NUMBER_DEVICES-1:0]     tx_s2c_tlast;
  wire  [32*C_NUMBER_DEVICES-1:0]  tx_s2c_tkeep;

  wire  [C_NUMBER_DEVICES-1:0]     rx_c2s_tready;
  wire  [256*C_NUMBER_DEVICES-1:0] rx_c2s_tdata;
  wire  [C_NUMBER_DEVICES-1:0]     rx_c2s_tlast;
  wire  [C_NUMBER_DEVICES-1:0]     rx_c2s_tvalid;
  wire  [32*C_NUMBER_DEVICES-1:0]  rx_c2s_tkeep;


  pcie_controller #(
    .C_USE_VIRTUALIZATION             (C_USE_VIRTUALIZATION),
    .C_NUMBER_DEVICES                 (C_NUMBER_DEVICES)
  )
  pcie_controller_i
  (
    // Clock and reset
    .pcie_clk                         (user_clk),
    .pcie_reset                       (pcie_reset),
     // Requester
    .s_axis_rq_tlast                  (s_axis_rq_tlast),
    .s_axis_rq_tdata                  (s_axis_rq_tdata),
    .s_axis_rq_tuser                  (s_axis_rq_tuser),
    .s_axis_rq_tkeep                  (s_axis_rq_tkeep),
    .s_axis_rq_tready                 (s_axis_rq_tready_bit),
    .s_axis_rq_tvalid                 (s_axis_rq_tvalid),
    .m_axis_rc_tdata                  (m_axis_rc_tdata),
    .m_axis_rc_tuser                  (m_axis_rc_tuser),
    .m_axis_rc_tlast                  (m_axis_rc_tlast),
    .m_axis_rc_tkeep                  (m_axis_rc_tkeep),
    .m_axis_rc_tvalid                 (m_axis_rc_tvalid),
    .m_axis_rc_tready                 (m_axis_rc_tready_bit),
    // Completer
    .m_axis_cq_tdata                  (m_axis_cq_tdata),
    .m_axis_cq_tuser                  (m_axis_cq_tuser),
    .m_axis_cq_tlast                  (m_axis_cq_tlast),
    .m_axis_cq_tkeep                  (m_axis_cq_tkeep),
    .m_axis_cq_tvalid                 (m_axis_cq_tvalid),
    .m_axis_cq_tready                 (m_axis_cq_tready_bit),
    .s_axis_cc_tdata                  (s_axis_cc_tdata),
    .s_axis_cc_tuser                  (s_axis_cc_tuser),
    .s_axis_cc_tlast                  (s_axis_cc_tlast),
    .s_axis_cc_tkeep                  (s_axis_cc_tkeep),
    .s_axis_cc_tvalid                 (s_axis_cc_tvalid),
    .s_axis_cc_tready                 (s_axis_cc_tready_bit),
    // MSI-X
    .cfg_interrupt_msix_enable        (cfg_interrupt_msix_enable),
    .cfg_interrupt_msix_mask          (cfg_interrupt_msix_mask),
    .cfg_interrupt_msix_vf_enable     (cfg_interrupt_msix_vf_enable),
    .cfg_interrupt_msix_vf_mask       (cfg_interrupt_msix_vf_mask),
    .cfg_interrupt_msix_data          (cfg_interrupt_msix_data),
    .cfg_interrupt_msix_address       (cfg_interrupt_msix_address),
    .cfg_interrupt_msix_int           (cfg_interrupt_msix_int),
    .cfg_interrupt_msix_sent          (cfg_interrupt_msix_sent),
    .cfg_interrupt_msix_fail          (cfg_interrupt_msix_fail),
    // Credits
    .pcie_tfc_nph_av                  (pcie_tfc_nph_av),
    .pcie_tfc_npd_av                  (pcie_tfc_npd_av),
    // AXI4-Lite interface //
    .m_axi_lite_aclk                  (m_axi_lite_aclk),
    .m_axi_lite_aresetn               (m_axi_lite_aresetn),
    .m_axi_lite_arready               (m_axi_lite_arready),
    .m_axi_lite_arvalid               (m_axi_lite_arvalid),
    .m_axi_lite_araddr                (m_axi_lite_araddr),
    .m_axi_lite_arprot                (m_axi_lite_arprot),
    .m_axi_lite_rready                (m_axi_lite_rready),
    .m_axi_lite_rvalid                (m_axi_lite_rvalid),
    .m_axi_lite_rdata                 (m_axi_lite_rdata),
    .m_axi_lite_rresp                 (m_axi_lite_rresp),
    .m_axi_lite_awready               (m_axi_lite_awready),
    .m_axi_lite_awvalid               (m_axi_lite_awvalid),
    .m_axi_lite_awaddr                (m_axi_lite_awaddr),
    .m_axi_lite_awprot                (m_axi_lite_awprot),
    .m_axi_lite_wready                (m_axi_lite_wready),
    .m_axi_lite_wvalid                (m_axi_lite_wvalid),
    .m_axi_lite_wdata                 (m_axi_lite_wdata),
    .m_axi_lite_wstrb                 (m_axi_lite_wstrb),
    .m_axi_lite_bready                (m_axi_lite_bready),
    .m_axi_lite_bvalid                (m_axi_lite_bvalid),
    .m_axi_lite_bresp                 (m_axi_lite_bresp),


    // Axi 4 stream interface //
    .s2c_tvalid                       (tx_s2c_tvalid),
    .s2c_tready                       (tx_s2c_tready),
    .s2c_tdata                        (tx_s2c_tdata),
    .s2c_tlast                        (tx_s2c_tlast),
    .s2c_tkeep                        (tx_s2c_tkeep),

    .c2s_tready                       (rx_c2s_tready),
    .c2s_tdata                        (rx_c2s_tdata),
    .c2s_tlast                        (rx_c2s_tlast),
    //.c2s_tlast                        (1'b0),
    .c2s_tvalid                       (rx_c2s_tvalid),
    .c2s_tkeep                        (rx_c2s_tkeep)
  );

  //////////////////////////////////////////////////////////////
  ///           DMA-metadata-related logic                   ///
  //////////////////////////////////////////////////////////////
  //DISCLAMER: for the moment tie # of DPATH facing AXIS interfaces (s2c & c2s) = 1.
  genvar i;
  generate for(i=0; i<C_NUMBER_DEVICES; i=i+1) begin
  	
  // == System 2 Card metadata extraction (tuser creation) 
  tx_naudit_axi #(
    .M_AXIS_TDATA_WIDTH 	      (256),
    .M_AXIS_TUSER_WIDTH 	      (128),
    .C_PREAM_VALUE 		          (16'hCAFE)
  )
  metadata_extractor
  (
    // Misc
   .CLK				              (user_clk),
   .RST				              (pcie_reset),

    // in (DMA->)
   .s_axis_tdata		          (tx_s2c_tdata[i*256 +: 256]),
   .s_axis_tkeep		          (tx_s2c_tkeep[i*32 +: 32]),
   .s_axis_tvalid		          (tx_s2c_tvalid[i*1 +: 1]),
   .s_axis_tlast		          (tx_s2c_tlast[i*1 +: 1]),
   .s_axis_tready		          (tx_s2c_tready[i*1 +: 1]),

    // out (->DPATH)
    .m_axis_tdata		          (s2c_tdata[i*256 +: 256]),
    .m_axis_tkeep		          (s2c_tkeep[i*32 +: 32]),
    .m_axis_tuser		          (s2c_tuser[i*128 +: 128]),
    .m_axis_tvalid		          (s2c_tvalid[i*1 +: 1]),
    .m_axis_tlast		          (s2c_tlast[i*1 +: 1]),
    .m_axis_tready		          (s2c_tready[i*1 +: 1])
);

  // == Card 2 System metadata creation (tuser extraction)
  rx_axi_naudit #(
    .M_AXIS_TDATA_WIDTH 	       (256),
    .M_AXIS_TUSER_WIDTH 	       (128),
    .C_PREAM_VALUE 		           (16'hCAFE)
  )
  metadata_creator
  (
   .CLK				               (user_clk),
   .RST				               (pcie_reset),

   //out (->DMA)
   .m_axis_tdata		           (rx_c2s_tdata[i*256 +: 256]),
   .m_axis_tkeep		           (rx_c2s_tkeep[i*32 +: 32]),
   .m_axis_tvalid		           (rx_c2s_tvalid[i*1 +: 1]),
   .m_axis_tlast		           (rx_c2s_tlast[i*1 +: 1]),
   .m_axis_tready		           (rx_c2s_tready[i*1 +: 1]),

    //in (DPATH->)
   .s_axis_tdata		           (c2s_tdata[i*256 +: 256]),
   .s_axis_tuser		           (c2s_tuser[i*128 +: 128]),
   .s_axis_tkeep		           (c2s_tkeep[i*32 +: 32]),
   .s_axis_tvalid		           (c2s_tvalid[i*1 +: 1]),
   .s_axis_tlast		           (c2s_tlast[i*1 +: 1]),
   .s_axis_tready		           (c2s_tready[i*1 +: 1])
);
end
endgenerate

  //////////////////////////////////////////////////////////////
  ///PCIe related logic - from Jose-Fernando's ep wrapper    ///
  //////////////////////////////////////////////////////////////

  `define PCI_EXP_EP_OUI                           24'h000A35
  `define PCI_EXP_EP_DSN_1                         {{8'h1},`PCI_EXP_EP_OUI}
  `define PCI_EXP_EP_DSN_2                         32'h00000001
  localparam TCQ=1;

  assign pcie_cq_np_req = 1'b1;                    // MUY IMPORTANTE

  //--------------------------------------------------------------------------------------------------------------------//
    // CFG_WRITE : Description : Write Configuration Space MI decode error, Disabling LFSR update from SKP. CR#
    //--------------------------------------------------------------------------------------------------------------------//
    reg         write_cfg_done_1;
    reg [18:0]  cfg_mgmt_addr_reg;
    reg [31:0]  cfg_mgmt_write_data_reg;
    reg [3:0]   cfg_mgmt_byte_enable_reg;
    reg         cfg_mgmt_write_reg;
    reg         cfg_mgmt_read_reg;

     // tie-offs
     assign cfg_mgmt_addr        = cfg_mgmt_addr_reg;
     assign cfg_mgmt_write_data  = cfg_mgmt_write_data_reg;
     assign cfg_mgmt_byte_enable = cfg_mgmt_byte_enable_reg;
     assign cfg_mgmt_write       = cfg_mgmt_write_reg;
     assign cfg_mgmt_read        = cfg_mgmt_read_reg;

    always @(posedge user_clk) begin : cfg_write_skp_nolfsr
      if (user_reset) begin
        cfg_mgmt_addr_reg        <= #TCQ 32'b0;
        cfg_mgmt_write_data_reg  <= #TCQ 32'b0;
        cfg_mgmt_byte_enable_reg <= #TCQ 4'b0;
        cfg_mgmt_write_reg       <= #TCQ 1'b0;
        cfg_mgmt_read_reg        <= #TCQ 1'b0;
        write_cfg_done_1         <= #TCQ 1'b0;
      end else begin
        if (cfg_mgmt_read_write_done == 1'b1 && write_cfg_done_1 == 1'b1) begin
          cfg_mgmt_addr_reg                 <= #TCQ 0;
          cfg_mgmt_write_data_reg           <= #TCQ 0;
          cfg_mgmt_byte_enable_reg          <= #TCQ 0;
          cfg_mgmt_write_reg                <= #TCQ 0;
          cfg_mgmt_read_reg                 <= #TCQ 0;
        end else if (cfg_mgmt_read_write_done == 1'b1 && write_cfg_done_1 == 1'b0) begin
          cfg_mgmt_addr_reg                 <= #TCQ 32'h40082;
          cfg_mgmt_write_data_reg[31:28]    <= #TCQ cfg_mgmt_read_data[31:28];
          cfg_mgmt_write_data_reg[27]       <= #TCQ 1'b1;
          cfg_mgmt_write_data_reg[26:0]     <= #TCQ cfg_mgmt_read_data[26:0];
          cfg_mgmt_byte_enable_reg          <= #TCQ 4'hF;
          cfg_mgmt_write_reg                <= #TCQ 1'b1;
          cfg_mgmt_read_reg                 <= #TCQ 1'b0;
          write_cfg_done_1                  <= #TCQ 1'b1;
        end else if (write_cfg_done_1 == 1'b0) begin
          cfg_mgmt_addr_reg                 <= #TCQ 32'h40082;
          cfg_mgmt_write_data_reg           <= #TCQ 32'b0;
          cfg_mgmt_byte_enable_reg          <= #TCQ 4'hF;
          cfg_mgmt_write_reg                <= #TCQ 1'b0;
          cfg_mgmt_read_reg                 <= #TCQ 1'b1;
        end
      end
    end

   // More tie-offs
   assign cfg_mgmt_type1_cfg_reg_access     = 1'b0;
   assign cfg_msg_transmit                  = 1'b0;
   assign cfg_msg_transmit_type             = 3'b0; //  [2:0]
   assign cfg_msg_transmit_data             = 32'b0; // [31:0]
   assign cfg_fc_sel                        = 3'b0; // [2:0]
   assign cfg_per_func_status_control       = 3'h0;
   assign cfg_subsys_vend_id                = 16'h10EE;
   assign cfg_config_space_enable           = 1'b1;
   assign cfg_req_pm_transition_l23_ready   = 1'b0;
   assign cfg_hot_reset_in                  = 1'b0;
   assign cfg_ds_port_number                = 8'h0;
   assign cfg_ds_bus_number                 = 8'h0;
   assign cfg_ds_device_number              = 5'h0;
   assign cfg_ds_function_number            = 3'h0;
   assign cfg_per_function_number           = 3'h0;                                     // Zero out function num for status req
   assign cfg_per_function_output_request   = 1'b0;                                     // Do not request configuration status update
   assign cfg_dsn                           = {`PCI_EXP_EP_DSN_2, `PCI_EXP_EP_DSN_1};   // Assign the input DSN
   assign cfg_err_cor_in                    = 1'b0;                                     // Never report Correctable Error
   assign cfg_err_uncor_in                  = 1'b0;                                     // Never report UnCorrectable Error
   assign cfg_link_training_enable          = 1'b1;                                     // Always enable LTSSM to bring up the Link
   assign cfg_ext_read_data                 = 32'h0;                                    // Do not provide cfg data externally
   assign cfg_ext_read_data_valid           = 1'b0;                                     // Disable external implemented reg cfg read


   // And the final batch
   reg trn_pending;

   wire req_compl;
   wire compl_done;

   // CHAPUZAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
   assign req_compl = 1'b0;
   assign compl_done = 1'b1;

   //  Check if completion is pending
   always @ (posedge user_clk)
   begin
     if (user_reset ) begin
       trn_pending <= #TCQ 1'b0;
     end else begin
       if (!trn_pending && req_compl)
         trn_pending <= #TCQ 1'b1;
       else if (compl_done)
         trn_pending <= #TCQ 1'b0;
     end
   end

   //  Turn-off OK if requested and no transaction is pending
   reg cfg_power_state_change_ack_reg;

   assign cfg_power_state_change_ack = cfg_power_state_change_ack_reg;

   always @ (posedge user_clk)
   begin
     if (user_reset ) begin
       cfg_power_state_change_ack_reg <= 1'b0;
     end else begin
       if ( cfg_power_state_change_interrupt  && !trn_pending)
         cfg_power_state_change_ack_reg <= 1'b1;
       else
         cfg_power_state_change_ack_reg <= 1'b0;
     end
   end

   reg [1:0] cfg_flr_done_reg0;
   reg [5:0] cfg_vf_flr_done_reg0;
   reg [1:0] cfg_flr_done_reg1;
   reg [5:0] cfg_vf_flr_done_reg1;

   always @(posedge user_clk) begin
     if (user_reset) begin
       cfg_flr_done_reg0       <= 2'b0;
       cfg_vf_flr_done_reg0    <= 6'b0;
       cfg_flr_done_reg1       <= 2'b0;
       cfg_vf_flr_done_reg1    <= 6'b0;
     end else begin
       cfg_flr_done_reg0       <= cfg_flr_in_process;
       cfg_vf_flr_done_reg0    <= cfg_vf_flr_in_process;
       cfg_flr_done_reg1       <= cfg_flr_done_reg0;
       cfg_vf_flr_done_reg1    <= cfg_vf_flr_done_reg0;
     end
   end

   assign cfg_flr_done[0]                   = ~cfg_flr_done_reg1[0] && cfg_flr_done_reg0[0];
   assign cfg_flr_done[1]                   = ~cfg_flr_done_reg1[1] && cfg_flr_done_reg0[1];
   assign cfg_vf_flr_done[0]                = ~cfg_vf_flr_done_reg1[0] && cfg_vf_flr_done_reg0[0];
   assign cfg_vf_flr_done[1]                = ~cfg_vf_flr_done_reg1[1] && cfg_vf_flr_done_reg0[1];
   assign cfg_vf_flr_done[2]                = ~cfg_vf_flr_done_reg1[2] && cfg_vf_flr_done_reg0[2];
   assign cfg_vf_flr_done[3]                = ~cfg_vf_flr_done_reg1[3] && cfg_vf_flr_done_reg0[3];
   assign cfg_vf_flr_done[4]                = ~cfg_vf_flr_done_reg1[4] && cfg_vf_flr_done_reg0[4];
   assign cfg_vf_flr_done[5]                = ~cfg_vf_flr_done_reg1[5] && cfg_vf_flr_done_reg0[5];

   // Do not request per function status

   // interrupts
   assign cfg_interrupt_int                 = 4'b0; // [3:0]
   assign cfg_interrupt_msi_int             = 32'b0; // [31:0]
   assign cfg_interrupt_pending             = 2'h0;
   assign cfg_interrupt_msi_select          = 4'h0;
   assign cfg_interrupt_msi_pending_status  = 64'h0;
   assign cfg_interrupt_msi_attr            = 3'h0;
   assign cfg_interrupt_msi_tph_present     = 1'b0;
   assign cfg_interrupt_msi_tph_type        = 2'h0;
   assign cfg_interrupt_msi_tph_st_tag      = 9'h0;
   assign cfg_interrupt_msi_function_number = 3'h0;

endmodule
