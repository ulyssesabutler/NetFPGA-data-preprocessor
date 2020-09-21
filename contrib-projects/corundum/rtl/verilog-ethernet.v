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

// The top module for the verilog-ethernet UDP server project. 


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
    output    sfp1_tx_p
);

wire rst_156Mhz;
wire clk_156Mhz;

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

fpga_core fpga_core_inst(

    .rst          (rst_156Mhz),
    .clk          (clk_156Mhz),

    .sfp_1_led    (),
    .sfp_2_led    (),
    .sma_led      (),

    .sfp_1_tx_rst (rst_156Mhz),
    .sfp_1_tx_clk (clk_156Mhz),
    .sfp_1_txd    (phy0_xgmii_txd),
    .sfp_1_txc    (phy0_xgmii_txc),

    .sfp_1_rx_rst (rst_156Mhz),
    .sfp_1_rx_clk (clk_156Mhz),
    .sfp_1_rxd    (phy0_xgmii_rxd),
    .sfp_1_rxc    (phy0_xgmii_rxc),

    .sfp_2_tx_rst (rst_156Mhz),
    .sfp_2_tx_clk (clk_156Mhz),
    .sfp_2_txd    (phy1_xgmii_txd),
    .sfp_2_txc    (phy1_xgmii_txc),

    .sfp_2_rx_rst (rst_156Mhz),
    .sfp_2_rx_clk (clk_156Mhz),
    .sfp_2_rxd    (phy1_xgmii_rxd),
    .sfp_2_rxc    (phy1_xgmii_rxc)
);

endmodule
