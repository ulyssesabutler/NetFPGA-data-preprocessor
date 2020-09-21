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

// The wrapper module for PCS_PMA Xilinx IP core with PLL input signals. 

`timescale 1ns / 1ps

module pcs_pma_10g(

    input           rst,

    input           qplloutclk,
    input           qplloutrefclk,
    input           qplllock,
    input           txusrclk,
    input           txusrclk2,
    input           gttxreset,
    input           gtrxreset,
    input           txuserrdy,
    input           coreclk,
    input           areset_coreclk,
    input           reset_counter_done,

    input  [63:0]   xgmii_txd,
    input  [7:0]    xgmii_txc,
    output [63:0]   xgmii_rxd,
    output [7:0]    xgmii_rxc,

    output          tx_p,
    output          tx_n,
    input           rx_p,
    input           rx_n,

    input           signal_detect,
    input           tx_fault,
    output          tx_disable
);

// DRP interface
wire        drp_reqgnt;
wire        drp_den;
wire        drp_dwe;
wire        drp_drdy;
wire [15:0] drp_daddr;
wire [15:0] drp_di;
wire [15:0] drp_drpdo;


ten_gig_eth_pcs_pma the_ten_gig_eth_pcs_pma(

    .areset                 (rst),

     // shared logic
    .qplloutclk             (qplloutclk),
    .qplloutrefclk          (qplloutrefclk),
    .qplllock               (qplllock),
    .txusrclk               (txusrclk),
    .txusrclk2              (txusrclk2),
    .gttxreset              (gttxreset),
    .gtrxreset              (gtrxreset),
    .txuserrdy              (txuserrdy),
    .coreclk                (coreclk),
    .areset_coreclk         (areset_coreclk),
    .reset_counter_done     (reset_counter_done),
    .rxrecclk_out           (),
    .txoutclk               (),
    .tx_resetdone           (),
    .rx_resetdone           (),

    .xgmii_txd              (xgmii_txd),
    .xgmii_txc              (xgmii_txc),
    .xgmii_rxd              (xgmii_rxd),
    .xgmii_rxc              (xgmii_rxc),

    .txp                    (tx_p),
    .txn                    (tx_n),
    .rxp                    (rx_p),
    .rxn                    (rx_n),

    .signal_detect          (signal_detect),
    .tx_fault               (tx_fault),
    .tx_disable             (tx_disable),
    .status_vector          (),
    .core_status            (),
    .configuration_vector   ('b0),
    .pma_pmd_type           (3'b111),
    .sim_speedup_control    (1'b0),

    .dclk                   (coreclk),
    .drp_req                (drp_reqgnt),
    .drp_gnt                (drp_reqgnt),
    .drp_den_o              (drp_den),
    .drp_den_i              (drp_den),
    .drp_dwe_o              (drp_dwe),
    .drp_dwe_i              (drp_dwe),
    .drp_daddr_o            (drp_daddr),
    .drp_daddr_i            (drp_daddr),
    .drp_di_o               (drp_di),
    .drp_di_i               (drp_di),
    .drp_drdy_o             (drp_drdy),
    .drp_drdy_i             (drp_drdy),
    .drp_drpdo_o            (drp_drpdo),
    .drp_drpdo_i            (drp_drpdo)
);

endmodule
