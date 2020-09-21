//
// Copyright (c) 2019-2020 Marcin Wójcik
// All rights reserved.
//
// This software was developed by the University of Cambridge Computer
// Laboratory and supported by the UK's Engineering and Physical Sciences
// Research Council (EPSRC) under the EARL: sdn EnAbled MeasuRement for alL
// project (Project Reference EP/P025374/1).
//
// @NETFPGA_LICENSE_HEADER_START@
//
// Licensed to NetFPGA C.I.C. (NetFPGA) under one or more contributor
// license agreements. See the NOTICE file distributed with this work for
// additional information regarding copyright ownership. NetFPGA licenses this
// file to you under the NetFPGA Hardware-Software License, Version 1.0 (the
// "License"); you may not use this file except in compliance with the
// License. You may obtain a copy of the License at:
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

// The wrapper module for pcie3 endpoint for Virtex-7. 

`timescale 1ns / 1ps

module pcie3_7x(

    input rst_pcie,
    input clk_pcie,

    output rst_user,
    output clk_user_250Mhz,

    input  [7:0]     pcie_rx_p,
    input  [7:0]     pcie_rx_n,
    output [7:0]     pcie_tx_p,
    output [7:0]     pcie_tx_n,

    input [255:0]    s_axis_rq_tdata,
    input [7:0]      s_axis_rq_tkeep,
    input            s_axis_rq_tlast,
    output           s_axis_rq_tready,
    input [59:0]     s_axis_rq_tuser,
    input            s_axis_rq_tvalid,

    output [255:0]   m_axis_rc_tdata,
    output [7:0]     m_axis_rc_tkeep,
    output           m_axis_rc_tlast,
    input            m_axis_rc_tready,
    output [74:0]    m_axis_rc_tuser,
    output           m_axis_rc_tvalid,

    output [255:0]   m_axis_cq_tdata,
    output [7:0]     m_axis_cq_tkeep,
    output           m_axis_cq_tlast,
    input            m_axis_cq_tready,
    output [84:0]    m_axis_cq_tuser,
    output           m_axis_cq_tvalid,

    input  [255:0]   s_axis_cc_tdata,
    input  [7:0]     s_axis_cc_tkeep,
    input            s_axis_cc_tlast,
    output           s_axis_cc_tready,
    input  [32:0]    s_axis_cc_tuser,
    input            s_axis_cc_tvalid,

    output [1:0]     pcie_tfc_nph_av,
    output [1:0]     pcie_tfc_npd_av,

    output [2:0]     cfg_max_payload,
    output [2:0]     cfg_max_read_req,

    input  [18:0]    cfg_mgmt_addr,
    input            cfg_mgmt_write,
    input  [31:0]    cfg_mgmt_write_data,
    input  [3:0]     cfg_mgmt_byte_enable,
    input            cfg_mgmt_read,
    output [31:0]    cfg_mgmt_read_data,
    output           cfg_mgmt_read_write_done,

    input            cfg_err_cor_in,
    input            cfg_err_uncor_in,

    output [3:0]     cfg_interrupt_msi_enable,
    output [7:0]     cfg_interrupt_msi_vf_enable,
    output [11:0]    cfg_interrupt_msi_mmenable,
    output           cfg_interrupt_msi_mask_update,
    output [31:0]    cfg_interrupt_msi_data,
    input  [3:0]     cfg_interrupt_msi_select,
    input  [31:0]    cfg_interrupt_msi_int,
    input  [31:0]    cfg_interrupt_msi_pending_status,
    output           cfg_interrupt_msi_sent,
    output           cfg_interrupt_msi_fail,
    input  [2:0]     cfg_interrupt_msi_attr,
    input            cfg_interrupt_msi_tph_present,
    input  [1:0]     cfg_interrupt_msi_tph_type,
    input  [8:0]     cfg_interrupt_msi_tph_st_tag,
    input  [3:0]     cfg_interrupt_msi_function_number
);

pcie3_7x_0 pcie3_7x_0_inst(

    .sys_reset                         (rst_pcie),
    .sys_clk                           (clk_pcie),

    .user_reset                        (rst_user),
    .user_clk                          (clk_user_250Mhz),

    .pci_exp_txn                       (pcie_tx_n),
    .pci_exp_txp                       (pcie_tx_p),
    .pci_exp_rxn                       (pcie_rx_n),
    .pci_exp_rxp                       (pcie_rx_p),

    .user_lnk_up                       (),
    .mmcm_lock                         (),
    .user_app_rdy                      (),

    .s_axis_rq_tdata                   (s_axis_rq_tdata),
    .s_axis_rq_tkeep                   (s_axis_rq_tkeep),
    .s_axis_rq_tlast                   (s_axis_rq_tlast),
    .s_axis_rq_tready                  (s_axis_rq_tready),
    .s_axis_rq_tuser                   (s_axis_rq_tuser),
    .s_axis_rq_tvalid                  (s_axis_rq_tvalid),

    .m_axis_rc_tdata                   (m_axis_rc_tdata),
    .m_axis_rc_tkeep                   (m_axis_rc_tkeep),
    .m_axis_rc_tlast                   (m_axis_rc_tlast),
    .m_axis_rc_tready                  (m_axis_rc_tready),
    .m_axis_rc_tuser                   (m_axis_rc_tuser),
    .m_axis_rc_tvalid                  (m_axis_rc_tvalid),

    .m_axis_cq_tdata                   (m_axis_cq_tdata),
    .m_axis_cq_tkeep                   (m_axis_cq_tkeep),
    .m_axis_cq_tlast                   (m_axis_cq_tlast),
    .m_axis_cq_tready                  (m_axis_cq_tready),
    .m_axis_cq_tuser                   (m_axis_cq_tuser),
    .m_axis_cq_tvalid                  (m_axis_cq_tvalid),

    .s_axis_cc_tdata                   (s_axis_cc_tdata),
    .s_axis_cc_tkeep                   (s_axis_cc_tkeep),
    .s_axis_cc_tlast                   (s_axis_cc_tlast),
    .s_axis_cc_tready                  (s_axis_cc_tready),
    .s_axis_cc_tuser                   (s_axis_cc_tuser),
    .s_axis_cc_tvalid                  (s_axis_cc_tvalid),

    .pcie_rq_seq_num                   (),
    .pcie_rq_seq_num_vld               (),
    .pcie_rq_tag                       (),
    .pcie_rq_tag_vld                   (),

    .pcie_tfc_nph_av                   (pcie_tfc_nph_av),
    .pcie_tfc_npd_av                   (pcie_tfc_npd_av),

    .pcie_cq_np_req                    (1'b1),
    .pcie_cq_np_req_count              (),

    .cfg_phy_link_down                 (),
    .cfg_phy_link_status               (),
    .cfg_negotiated_width              (),
    .cfg_current_speed                 (),
    .cfg_max_payload                   (cfg_max_payload),
    .cfg_max_read_req                  (cfg_max_read_req),
    .cfg_function_status               (),
    .cfg_function_power_state          (),
    .cfg_vf_status                     (),
    .cfg_vf_power_state                (),
    .cfg_link_power_state              (),

    .cfg_mgmt_addr                     (cfg_mgmt_addr),
    .cfg_mgmt_write                    (cfg_mgmt_write),
    .cfg_mgmt_write_data               (cfg_mgmt_write_data),
    .cfg_mgmt_byte_enable              (cfg_mgmt_byte_enable),
    .cfg_mgmt_read                     (cfg_mgmt_read),
    .cfg_mgmt_read_data                (cfg_mgmt_read_data),
    .cfg_mgmt_read_write_done          (cfg_mgmt_read_write_done),
    .cfg_mgmt_type1_cfg_reg_access     (1'b0),

    .cfg_err_cor_out                   (),
    .cfg_err_nonfatal_out              (),
    .cfg_err_fatal_out                 (),
    .cfg_ltr_enable                    (),
    .cfg_ltssm_state                   (),
    .cfg_rcb_status                    (),
    .cfg_dpa_substate_change           (),
    .cfg_obff_enable                   (),
    .cfg_pl_status_change              (),
    .cfg_tph_requester_enable          (),
    .cfg_tph_st_mode                   (),
    .cfg_vf_tph_requester_enable       (),
    .cfg_vf_tph_st_mode                (),

    .cfg_msg_received                  (),
    .cfg_msg_received_data             (),
    .cfg_msg_received_type             (),
    .cfg_msg_transmit                  (1'b0),
    .cfg_msg_transmit_type             (3'd0),
    .cfg_msg_transmit_data             (32'd0),
    .cfg_msg_transmit_done             (),

    .cfg_fc_ph                         (),
    .cfg_fc_pd                         (),
    .cfg_fc_nph                        (),
    .cfg_fc_npd                        (),
    .cfg_fc_cplh                       (),
    .cfg_fc_cpld                       (),
    .cfg_fc_sel                        (3'd0),

    .cfg_per_func_status_control       (3'd0),
    .cfg_per_func_status_data          (),
    .cfg_per_function_number           (4'd0),
    .cfg_per_function_output_request   (1'b0),
    .cfg_per_function_update_done      (),

    .cfg_dsn                           (64'd0),
    .cfg_power_state_change_ack        (1'b1),
    .cfg_power_state_change_interrupt  (),
    .cfg_err_cor_in                    (cfg_err_cor_in),
    .cfg_err_uncor_in                  (cfg_err_uncor_in),
    .cfg_flr_in_process                (),
    .cfg_flr_done                      (4'd0),
    .cfg_vf_flr_in_process             (),
    .cfg_vf_flr_done                   (8'd0),
    .cfg_link_training_enable          (1'b1),
    .cfg_interrupt_int                 (4'd0),
    .cfg_interrupt_pending             (4'd0),
    .cfg_interrupt_sent                (),
    .cfg_interrupt_msi_enable          (cfg_interrupt_msi_enable),
    .cfg_interrupt_msi_vf_enable       (cfg_interrupt_msi_vf_enable),
    .cfg_interrupt_msi_mmenable        (cfg_interrupt_msi_mmenable),
    .cfg_interrupt_msi_mask_update     (cfg_interrupt_msi_mask_update),
    .cfg_interrupt_msi_data            (cfg_interrupt_msi_data),
    .cfg_interrupt_msi_select          (cfg_interrupt_msi_select),
    .cfg_interrupt_msi_int             (cfg_interrupt_msi_int),
    .cfg_interrupt_msi_pending_status  (cfg_interrupt_msi_pending_status),
    .cfg_interrupt_msi_sent            (cfg_interrupt_msi_sent),
    .cfg_interrupt_msi_fail            (cfg_interrupt_msi_fail),
    .cfg_interrupt_msi_attr            (cfg_interrupt_msi_attr),
    .cfg_interrupt_msi_tph_present     (cfg_interrupt_msi_tph_present),
    .cfg_interrupt_msi_tph_type        (cfg_interrupt_msi_tph_type),
    .cfg_interrupt_msi_tph_st_tag      (cfg_interrupt_msi_tph_st_tag),
    .cfg_interrupt_msi_function_number (cfg_interrupt_msi_function_number),

    .cfg_hot_reset_out                 (),
    .cfg_config_space_enable           (1'b1),
    .cfg_req_pm_transition_l23_ready   (1'b0),
    .cfg_hot_reset_in                  (1'b0),
    .cfg_ds_port_number                (8'd0),
    .cfg_ds_bus_number                 (8'd0),
    .cfg_ds_device_number              (5'd0),
    .cfg_ds_function_number            (3'd0),
    .cfg_subsys_vend_id                (16'h1234)
);
endmodule
