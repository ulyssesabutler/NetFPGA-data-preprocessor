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

// The top module for Corundum project. 

`timescale 1ns / 1ps

module fpga(

    input     rst,
    input     clk_sfp_n, 
    input     clk_sfp_p,

    input     sfp0_absent,
    input     sfp0_tx_fault,
    output    sfp0_tx_disable,
    input     sfp0_rx_n,
    input     sfp0_rx_p,
    output    sfp0_tx_n,
    output    sfp0_tx_p,

    input     sfp1_absent,
    input     sfp1_tx_fault,
    output    sfp1_tx_disable,
    input     sfp1_rx_n,
    input     sfp1_rx_p,
    output    sfp1_tx_n,
    output    sfp1_tx_p,

    input     rst_pcie_n,
    input     clk_pcie_n,
    input     clk_pcie_p,

    input  [7:0] pcie_rx_p,
    input  [7:0] pcie_rx_n,
    output [7:0] pcie_tx_p,
    output [7:0] pcie_tx_n
);

wire rst_156Mhz;
wire clk_156Mhz; 

wire clk_pcie; 
wire clk_user_250Mhz; 
wire rst_user;

wire qplloutclk;
wire qplloutrefclk;
wire qplllock;
wire txusrclk;
wire txusrclk2;
wire gttxreset;
wire gtrxreset;
wire txuserrdy;
wire rxrecclk;
wire coreclk;
wire areset_datapathclk;
wire reset_counter_done;
wire resetdone;

wire [63:0] phy0_xgmii_txd;
wire [7:0]  phy0_xgmii_txc;
wire [63:0] phy0_xgmii_rxd;
wire [7:0]  phy0_xgmii_rxc;

wire [63:0] phy1_xgmii_txd;
wire [7:0]  phy1_xgmii_txc;
wire [63:0] phy1_xgmii_rxd;
wire [7:0]  phy1_xgmii_rxc;

wire [255:0]    axis_rq_tdata;
wire [7:0]      axis_rq_tkeep;
wire            axis_rq_tlast;
wire            axis_rq_tready;
wire [59:0]     axis_rq_tuser;
wire            axis_rq_tvalid;

wire [255:0]    axis_rc_tdata;
wire [7:0]      axis_rc_tkeep;
wire            axis_rc_tlast;
wire            axis_rc_tready;
wire [74:0]     axis_rc_tuser;
wire            axis_rc_tvalid;

wire [255:0]    axis_cq_tdata;
wire [7:0]      axis_cq_tkeep;
wire            axis_cq_tlast;
wire            axis_cq_tready;
wire [84:0]     axis_cq_tuser;
wire            axis_cq_tvalid;

wire [255:0]    axis_cc_tdata;
wire [7:0]      axis_cc_tkeep;
wire            axis_cc_tlast;
wire            axis_cc_tready;
wire [32:0]     axis_cc_tuser;
wire            axis_cc_tvalid;

wire [1:0]  pcie_tfc_nph_av;
wire [1:0]  pcie_tfc_npd_av;

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

pcs_pma_10g_shared phy0_pcs_pma_10g_shared_inst(

    .rst                (rst),
    .clk_sfp_n          (clk_sfp_n),
    .clk_sfp_p          (clk_sfp_p),

     // pll signals out
    .qplloutclk         (qplloutclk),
    .qplloutrefclk      (qplloutrefclk),
    .qplllock           (qplllock),
    .txusrclk           (txusrclk),
    .txusrclk2          (txusrclk2),
    .gttxreset          (gttxreset),
    .gtrxreset          (gtrxreset),
    .txuserrdy          (txuserrdy),
    .rxrecclk           (rxrecclk),
    .coreclk            (clk_156Mhz),
    .areset_datapathclk (rst_156Mhz),
    .reset_counter_done (reset_counter_done),
    .resetdone          (resetdone),

    .xgmii_txd          (phy0_xgmii_txd),
    .xgmii_txc          (phy0_xgmii_txc),
    .xgmii_rxd          (phy0_xgmii_rxd),
    .xgmii_rxc          (phy0_xgmii_rxc),

    .tx_p               (sfp0_tx_p),
    .tx_n               (sfp0_tx_n),
    .rx_p               (sfp0_rx_p),
    .rx_n               (sfp0_rx_n),

    .signal_detect      (~sfp0_absent),
    .tx_fault           (sfp0_tx_fault),
    .tx_disable         (sfp0_tx_disable)
);

pcs_pma_10g phy1_pcs_pma_10g_inst(

    .rst                (rst),

     // pll signals in
    .qplloutclk         (qplloutclk),
    .qplloutrefclk      (qplloutrefclk),
    .qplllock           (qplllock),
    .txusrclk           (txusrclk),
    .txusrclk2          (txusrclk2),
    .gttxreset          (gttxreset),
    .gtrxreset          (gtrxreset),
    .txuserrdy          (txuserrdy),
    .coreclk            (clk_156Mhz),
    .areset_coreclk     (rst_156Mhz),
    .reset_counter_done (reset_counter_done),

    .xgmii_txd          (phy1_xgmii_txd),
    .xgmii_txc          (phy1_xgmii_txc),
    .xgmii_rxd          (phy1_xgmii_rxd),
    .xgmii_rxc          (phy1_xgmii_rxc),

    .tx_p               (sfp1_tx_p),
    .tx_n               (sfp1_tx_n),
    .rx_p               (sfp1_rx_p),
    .rx_n               (sfp1_rx_n),

    .signal_detect      (~sfp1_absent),
    .tx_fault           (sfp1_tx_fault),
    .tx_disable         (sfp1_tx_disable)
);

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

    .pcie_tfc_nph_av                    (pcie_tfc_nph_av),
    .pcie_tfc_npd_av                    (pcie_tfc_npd_av),

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
    .AXIS_PCIE_DATA_WIDTH   (256),
    .AXIS_PCIE_KEEP_WIDTH   (8),
    .AXIS_PCIE_RC_USER_WIDTH(75),
    .AXIS_PCIE_RQ_USER_WIDTH(60),
    .AXIS_PCIE_CQ_USER_WIDTH(85),
    .AXIS_PCIE_CC_USER_WIDTH(33),
    .BAR0_APERTURE          (24)
) 
fpga_core_inst(

    .clk_156mhz(clk_156Mhz),
    .rst_156mhz(rst_156Mhz),
    .clk_250mhz(clk_user_250Mhz),
    .rst_250mhz(rst_user),

    .sma_led    (),
    .sma_in     (1'b0),
    .sma_out    (),
    .sma_out_en (),
    .sma_term_en(),

    .m_axis_rq_tdata    (axis_rq_tdata),
    .m_axis_rq_tkeep    (axis_rq_tkeep),
    .m_axis_rq_tlast    (axis_rq_tlast),
    .m_axis_rq_tready   (axis_rq_tready),
    .m_axis_rq_tuser    (axis_rq_tuser),
    .m_axis_rq_tvalid   (axis_rq_tvalid),

    .s_axis_rc_tdata    (axis_rc_tdata),
    .s_axis_rc_tkeep    (axis_rc_tkeep),
    .s_axis_rc_tlast    (axis_rc_tlast),
    .s_axis_rc_tready   (axis_rc_tready),
    .s_axis_rc_tuser    (axis_rc_tuser),
    .s_axis_rc_tvalid   (axis_rc_tvalid),

    .s_axis_cq_tdata    (axis_cq_tdata),
    .s_axis_cq_tkeep    (axis_cq_tkeep),
    .s_axis_cq_tlast    (axis_cq_tlast),
    .s_axis_cq_tready   (axis_cq_tready),
    .s_axis_cq_tuser    (axis_cq_tuser),
    .s_axis_cq_tvalid   (axis_cq_tvalid),

    .m_axis_cc_tdata    (axis_cc_tdata),
    .m_axis_cc_tkeep    (axis_cc_tkeep),
    .m_axis_cc_tlast    (axis_cc_tlast),
    .m_axis_cc_tready   (axis_cc_tready),
    .m_axis_cc_tuser    (axis_cc_tuser),
    .m_axis_cc_tvalid   (axis_cc_tvalid),

    .pcie_tfc_nph_av    (pcie_tfc_nph_av),
    .pcie_tfc_npd_av    (pcie_tfc_npd_av),

    .cfg_max_payload    (cfg_max_payload),
    .cfg_max_read_req   (cfg_max_read_req),

    .cfg_mgmt_addr          (cfg_mgmt_addr),
    .cfg_mgmt_write         (cfg_mgmt_write),
    .cfg_mgmt_write_data    (cfg_mgmt_write_data),
    .cfg_mgmt_byte_enable   (cfg_mgmt_byte_enable),
    .cfg_mgmt_read          (cfg_mgmt_read),
    .cfg_mgmt_read_data     (cfg_mgmt_read_data),
    .cfg_mgmt_read_write_done(cfg_mgmt_read_write_done),

    .cfg_interrupt_msi_enable                       (cfg_interrupt_msi_enable),
    .cfg_interrupt_msi_vf_enable                    (cfg_interrupt_msi_vf_enable),
    .cfg_interrupt_msi_mmenable                     (cfg_interrupt_msi_mmenable),
    .cfg_interrupt_msi_mask_update                  (cfg_interrupt_msi_mask_update),
    .cfg_interrupt_msi_data                         (cfg_interrupt_msi_data),
    .cfg_interrupt_msi_select                       (cfg_interrupt_msi_select),
    .cfg_interrupt_msi_int                          (cfg_interrupt_msi_int),
    .cfg_interrupt_msi_pending_status               (cfg_interrupt_msi_pending_status),
    // not present in pcie3 7x
    .cfg_interrupt_msi_pending_status_data_enable   (),
    .cfg_interrupt_msi_pending_status_function_num  (),
    .cfg_interrupt_msi_sent                         (cfg_interrupt_msi_sent),
    .cfg_interrupt_msi_fail                         (cfg_interrupt_msi_fail),
    .cfg_interrupt_msi_attr                         (cfg_interrupt_msi_attr),
    .cfg_interrupt_msi_tph_present                  (cfg_interrupt_msi_tph_present),
    .cfg_interrupt_msi_tph_type                     (cfg_interrupt_msi_tph_type),
    .cfg_interrupt_msi_tph_st_tag                   (cfg_interrupt_msi_tph_st_tag),
    .cfg_interrupt_msi_function_number              (cfg_interrupt_msi_function_number),

    .status_error_cor   (cfg_err_cor_in),
    .status_error_uncor (cfg_err_uncor_in),

    .sfp_1_tx_clk   (clk_156Mhz),
    .sfp_1_tx_rst   (rst_156Mhz),
    .sfp_1_txd      (phy0_xgmii_txd),
    .sfp_1_txc      (phy0_xgmii_txc),
    .sfp_1_rx_clk   (clk_156Mhz),
    .sfp_1_rx_rst   (rst_156Mhz),
    .sfp_1_rxd      (phy0_xgmii_rxd),
    .sfp_1_rxc      (phy0_xgmii_rxc),

    .sfp_2_tx_clk   (clk_156Mhz),
    .sfp_2_tx_rst   (rst_156Mhz),
    .sfp_2_txd      (phy1_xgmii_txd),
    .sfp_2_txc      (phy1_xgmii_txc),
    .sfp_2_rx_clk   (clk_156Mhz),
    .sfp_2_rx_rst   (rst_156Mhz),
    .sfp_2_rxd      (phy1_xgmii_rxd),
    .sfp_2_rxc      (phy1_xgmii_rxc),

    .sfp_i2c_scl_i  (1'b0),
    .sfp_i2c_scl_o  (),
    .sfp_i2c_scl_t  (),
    .sfp_1_i2c_sda_i(1'b0),
    .sfp_1_i2c_sda_o(),
    .sfp_1_i2c_sda_t(),
    .sfp_2_i2c_sda_i(1'b0),
    .sfp_2_i2c_sda_o(),
    .sfp_2_i2c_sda_t(),

    .eeprom_i2c_scl_i(1'b0),
    .eeprom_i2c_scl_o(),
    .eeprom_i2c_scl_t(),
    .eeprom_i2c_sda_i(1'b0),
    .eeprom_i2c_sda_o(),
    .eeprom_i2c_sda_t(),

    .flash_dq_i     (1'b0),
    .flash_dq_o     (),
    .flash_dq_oe    (),
    .flash_addr     (),
    .flash_region   (),
    .flash_region_oe(),
    .flash_ce_n     (),
    .flash_oe_n     (),
    .flash_we_n     (),
    .flash_adv_n    ()
);

endmodule
