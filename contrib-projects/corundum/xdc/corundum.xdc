#
# Copyright (c) 2019-2020 Marcin Wójcik 
# All rights reserved.
#
# This software was developed by the University of Cambridge Computer 
# Laboratory and supported by the UK's Engineering and Physical Sciences 
# Research Council (EPSRC) under the EARL: sdn EnAbled MeasuRement for alL 
# project (Project Reference EP/P025374/1).
#
# @NETFPGA_LICENSE_HEADER_START@
#
# Licensed to NetFPGA C.I.C. (NetFPGA) under one or more contributor
# license agreements. See the NOTICE file distributed with this work for
# additional information regarding copyright ownership. NetFPGA licenses this
# file to you under the NetFPGA Hardware-Software License, Version 1.0 (the
# "License"); you may not use this file except in compliance with the
# License. You may obtain a copy of the License at:
#
#   http://www.netfpga-cic.org
#
# Unless required by applicable law or agreed to in writing, Work distributed
# under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
# CONDITIONS OF ANY KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations under the License.
#
# @NETFPGA_LICENSE_HEADER_END@
#

set_property CFGBVS GND         [current_design]
set_property CONFIG_VOLTAGE 1.8 [current_design]

set_property PACKAGE_PIN AR13      [get_ports rst]
set_property IOSTANDARD LVCMOS15   [get_ports rst]

set_property PACKAGE_PIN E10 [get_ports clk_sfp_p]
set_property PACKAGE_PIN E9  [get_ports clk_sfp_n]

# SFP0
set_property PACKAGE_PIN M18        [get_ports sfp0_tx_disable]
set_property IOSTANDARD LVCMOS15    [get_ports sfp0_tx_disable]
set_property PACKAGE_PIN M19        [get_ports sfp0_tx_fault]
set_property IOSTANDARD LVCMOS15    [get_ports sfp0_tx_fault]
set_property PACKAGE_PIN N18        [get_ports sfp0_absent]
set_property IOSTANDARD LVCMOS15    [get_ports sfp0_absent]

set_property LOC GTHE2_CHANNEL_X1Y39 [get_cells -hier -filter name=~*phy0*gthe2_i]

# SFP1 
set_property PACKAGE_PIN B31        [get_ports sfp1_tx_disable]
set_property IOSTANDARD LVCMOS15    [get_ports sfp1_tx_disable]
set_property PACKAGE_PIN C26        [get_ports sfp1_tx_fault]
set_property IOSTANDARD LVCMOS15    [get_ports sfp1_tx_fault]
set_property PACKAGE_PIN L19        [get_ports sfp1_absent]
set_property IOSTANDARD LVCMOS15    [get_ports sfp1_absent]

set_property LOC GTHE2_CHANNEL_X1Y38 [get_cells -hier -filter name=~*phy1*gthe2_i]

set_false_path -from [get_ports rst]

set_property PACKAGE_PIN AB8    [get_ports clk_pcie_p]
set_property PACKAGE_PIN AB7    [get_ports clk_pcie_n]

set_property LOC IBUFDS_GTE2_X1Y11 [get_cells -hier -filter name=~*IBUFDS_GTE2*]
create_clock -period 10.000 -name clk_pcie [get_pins -hier -filter name=~*IBUFDS_GTE2*/O]

set_property PACKAGE_PIN AY35       [get_ports rst_pcie_n]
set_property IOSTANDARD LVCMOS18    [get_ports rst_pcie_n]
set_property PULLUP true            [get_ports rst_pcie_n]

set_false_path -from [get_ports rst_pcie_n]