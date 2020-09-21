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

// The top module for the verilog-pcie project.

`timescale 1ns / 1ps

module fpga(

    input        rst_pcie_n,
    input        clk_pcie_n,
    input        clk_pcie_p,

    input  [7:0] pcie_rx_p,
    input  [7:0] pcie_rx_n,
    output [7:0] pcie_tx_p,
    output [7:0] pcie_tx_n
);

wire clk_pcie;
wire clk_user_250Mhz;
wire rst_user;

wire [255:0] axis_rq_tdata;
wire [7:0]   axis_rq_tkeep;
wire         axis_rq_tlast;
wire         axis_rq_tready;
wire [59:0]  axis_rq_tuser;
wire         axis_rq_tvalid;

wire [255:0] axis_rc_tdata;
wire [7:0]   axis_rc_tkeep;
wire         axis_rc_tlast;
wire         axis_rc_tready;
wire [74:0]  axis_rc_tuser;
wire         axis_rc_tvalid;

wire [255:0] axis_cq_tdata;
wire [7:0]   axis_cq_tkeep;
wire         axis_cq_tlast;
wire         axis_cq_tready;
wire [84:0]  axis_cq_tuser;
wire         axis_cq_tvalid;

wire [255:0] axis_cc_tdata;
wire [7:0]   axis_cc_tkeep;
wire         axis_cc_tlast;
wire         axis_cc_tready;
wire [32:0]  axis_cc_tuser;
wire         axis_cc_tvalid;

wire [2:0]  cfg_max_payload;
wire [2:0]  cfg_max_read_req;

wire [18:0] cfg_mgmt_addr;
wire        cfg_mgmt_write;
wire [31:0] cfg_mgmt_write_data;
wire [3:0]  cfg_mgmt_byte_enable;
wire        cfg_mgmt_read;
wire [31:0] cfg_mgmt_read_data;
wire        cfg_mgmt_read_write_done;

wire [3:0]  cfg_interrupt_msi_enable;
wire [7:0]  cfg_interrupt_msi_vf_enable;
wire [11:0] cfg_interrupt_msi_mmenable;
wire        cfg_interrupt_msi_mask_update;
wire [31:0] cfg_interrupt_msi_data;
wire [3:0]  cfg_interrupt_msi_select;
wire [31:0] cfg_interrupt_msi_int;
wire [31:0] cfg_interrupt_msi_pending_status;
wire        cfg_interrupt_msi_sent;
wire        cfg_interrupt_msi_fail;
wire [2:0]  cfg_interrupt_msi_attr;
wire        cfg_interrupt_msi_tph_present;
wire [1:0]  cfg_interrupt_msi_tph_type;
wire [8:0]  cfg_interrupt_msi_tph_st_tag;
wire [3:0]  cfg_interrupt_msi_function_number;

wire cfg_err_cor_in;
wire cfg_err_uncor_in;


IBUFDS_GTE2 IBUFDS_GTE2_inst (
    .O         (clk_pcie),
    .ODIV2     (),
    .CEB       (1'b0),
    .I         (clk_pcie_p),
    .IB        (clk_pcie_n)
);

pcie3_7x pcie3_7x_inst(

    .rst_pcie                           (~rst_pcie_n),
    .clk_pcie                           (clk_pcie),

    .rst_user                           (rst_user),
    .clk_user_250Mhz                    (clk_user_250Mhz),

    .pcie_tx_n                          (pcie_tx_n),
    .pcie_tx_p                          (pcie_tx_p),
    .pcie_rx_n                          (pcie_rx_n),
    .pcie_rx_p                          (pcie_rx_p),

    .s_axis_rq_tdata                    (axis_rq_tdata),
    .s_axis_rq_tkeep                    (axis_rq_tkeep),
    .s_axis_rq_tlast                    (axis_rq_tlast),
    .s_axis_rq_tready                   (axis_rq_tready),
    .s_axis_rq_tuser                    (axis_rq_tuser),
    .s_axis_rq_tvalid                   (axis_rq_tvalid),

    .m_axis_rc_tdata                    (axis_rc_tdata),
    .m_axis_rc_tkeep                    (axis_rc_tkeep),
    .m_axis_rc_tlast                    (axis_rc_tlast),
    .m_axis_rc_tready                   (axis_rc_tready),
    .m_axis_rc_tuser                    (axis_rc_tuser),
    .m_axis_rc_tvalid                   (axis_rc_tvalid),

    .m_axis_cq_tdata                    (axis_cq_tdata),
    .m_axis_cq_tkeep                    (axis_cq_tkeep),
    .m_axis_cq_tlast                    (axis_cq_tlast),
    .m_axis_cq_tready                   (axis_cq_tready),
    .m_axis_cq_tuser                    (axis_cq_tuser),
    .m_axis_cq_tvalid                   (axis_cq_tvalid),

    .s_axis_cc_tdata                    (axis_cc_tdata),
    .s_axis_cc_tkeep                    (axis_cc_tkeep),
    .s_axis_cc_tlast                    (axis_cc_tlast),
    .s_axis_cc_tready                   (axis_cc_tready),
    .s_axis_cc_tuser                    (axis_cc_tuser),
    .s_axis_cc_tvalid                   (axis_cc_tvalid),

    .pcie_tfc_nph_av                    (),
    .pcie_tfc_npd_av                    (),

    .cfg_max_payload                    (cfg_max_payload),
    .cfg_max_read_req                   (cfg_max_read_req),

    .cfg_mgmt_addr                      (cfg_mgmt_addr),
    .cfg_mgmt_write                     (cfg_mgmt_write),
    .cfg_mgmt_write_data                (cfg_mgmt_write_data),
    .cfg_mgmt_byte_enable               (cfg_mgmt_byte_enable),
    .cfg_mgmt_read                      (cfg_mgmt_read),
    .cfg_mgmt_read_data                 (cfg_mgmt_read_data),
    .cfg_mgmt_read_write_done           (cfg_mgmt_read_write_done),

    .cfg_err_cor_in                     (cfg_err_cor_in),
    .cfg_err_uncor_in                   (cfg_err_uncor_in),

    .cfg_interrupt_msi_enable           (cfg_interrupt_msi_enable),
    .cfg_interrupt_msi_vf_enable        (cfg_interrupt_msi_vf_enable),
    .cfg_interrupt_msi_mmenable         (cfg_interrupt_msi_mmenable),
    .cfg_interrupt_msi_mask_update      (cfg_interrupt_msi_mask_update),
    .cfg_interrupt_msi_data             (cfg_interrupt_msi_data),
    .cfg_interrupt_msi_select           (cfg_interrupt_msi_select),
    .cfg_interrupt_msi_int              (cfg_interrupt_msi_int),
    .cfg_interrupt_msi_pending_status   (cfg_interrupt_msi_pending_status),
    .cfg_interrupt_msi_sent             (cfg_interrupt_msi_sent),
    .cfg_interrupt_msi_fail             (cfg_interrupt_msi_fail),
    .cfg_interrupt_msi_attr             (cfg_interrupt_msi_attr),
    .cfg_interrupt_msi_tph_present      (cfg_interrupt_msi_tph_present),
    .cfg_interrupt_msi_tph_type         (cfg_interrupt_msi_tph_type),
    .cfg_interrupt_msi_tph_st_tag       (cfg_interrupt_msi_tph_st_tag),
    .cfg_interrupt_msi_function_number  (cfg_interrupt_msi_function_number)
);

fpga_core #(
    .AXIS_PCIE_DATA_WIDTH    (256),
    .AXIS_PCIE_KEEP_WIDTH    (8),
    .AXIS_PCIE_RC_USER_WIDTH (75),
    .AXIS_PCIE_RQ_USER_WIDTH (60),
    .AXIS_PCIE_CQ_USER_WIDTH (85),
    .AXIS_PCIE_CC_USER_WIDTH (33)
)
fpga_core_inst(

    .rst                                           (rst_user),
    .clk                                           (clk_user_250Mhz),

    .sfp_1_led                                     (),
    .sfp_2_led                                     (),
    .sma_led                                       (),

    .m_axis_rq_tdata                               (axis_rq_tdata),
    .m_axis_rq_tkeep                               (axis_rq_tkeep),
    .m_axis_rq_tlast                               (axis_rq_tlast),
    .m_axis_rq_tready                              (axis_rq_tready),
    .m_axis_rq_tuser                               (axis_rq_tuser),
    .m_axis_rq_tvalid                              (axis_rq_tvalid),

    .s_axis_rc_tdata                               (axis_rc_tdata),
    .s_axis_rc_tkeep                               (axis_rc_tkeep),
    .s_axis_rc_tlast                               (axis_rc_tlast),
    .s_axis_rc_tready                              (axis_rc_tready),
    .s_axis_rc_tuser                               (axis_rc_tuser),
    .s_axis_rc_tvalid                              (axis_rc_tvalid),

    .s_axis_cq_tdata                               (axis_cq_tdata),
    .s_axis_cq_tkeep                               (axis_cq_tkeep),
    .s_axis_cq_tlast                               (axis_cq_tlast),
    .s_axis_cq_tready                              (axis_cq_tready),
    .s_axis_cq_tuser                               (axis_cq_tuser),
    .s_axis_cq_tvalid                              (axis_cq_tvalid),

    .m_axis_cc_tdata                               (axis_cc_tdata),
    .m_axis_cc_tkeep                               (axis_cc_tkeep),
    .m_axis_cc_tlast                               (axis_cc_tlast),
    .m_axis_cc_tready                              (axis_cc_tready),
    .m_axis_cc_tuser                               (axis_cc_tuser),
    .m_axis_cc_tvalid                              (axis_cc_tvalid),

    .cfg_max_payload                               (cfg_max_payload),
    .cfg_max_read_req                              (cfg_max_read_req),

    .cfg_mgmt_addr                                 (cfg_mgmt_addr),
    .cfg_mgmt_write                                (cfg_mgmt_write),
    .cfg_mgmt_write_data                           (cfg_mgmt_write_data),
    .cfg_mgmt_byte_enable                          (cfg_mgmt_byte_enable),
    .cfg_mgmt_read                                 (cfg_mgmt_read),
    .cfg_mgmt_read_data                            (cfg_mgmt_read_data),
    .cfg_mgmt_read_write_done                      (cfg_mgmt_read_write_done),

    .cfg_interrupt_msi_enable                      (cfg_interrupt_msi_enable),
    .cfg_interrupt_msi_vf_enable                   (cfg_interrupt_msi_vf_enable),
    .cfg_interrupt_msi_mmenable                    (cfg_interrupt_msi_mmenable),
    .cfg_interrupt_msi_mask_update                 (cfg_interrupt_msi_mask_update),
    .cfg_interrupt_msi_data                        (cfg_interrupt_msi_data),
    .cfg_interrupt_msi_select                      (cfg_interrupt_msi_select),
    .cfg_interrupt_msi_int                         (cfg_interrupt_msi_int),
    .cfg_interrupt_msi_pending_status              (cfg_interrupt_msi_pending_status),
    .cfg_interrupt_msi_pending_status_data_enable  (),
    .cfg_interrupt_msi_pending_status_function_num (),
    .cfg_interrupt_msi_sent                        (cfg_interrupt_msi_sent),
    .cfg_interrupt_msi_fail                        (cfg_interrupt_msi_fail),
    .cfg_interrupt_msi_attr                        (cfg_interrupt_msi_attr),
    .cfg_interrupt_msi_tph_present                 (cfg_interrupt_msi_tph_present),
    .cfg_interrupt_msi_tph_type                    (cfg_interrupt_msi_tph_type),
    .cfg_interrupt_msi_tph_st_tag                  (cfg_interrupt_msi_tph_st_tag),
    .cfg_interrupt_msi_function_number             (cfg_interrupt_msi_function_number),

    .status_error_cor                              (cfg_err_cor_in),
    .status_error_uncor                            (cfg_err_uncor_in)
);
endmodule
