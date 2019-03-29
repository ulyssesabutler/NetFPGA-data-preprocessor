#
# Copyright (c) 2015 University of Cambridge
# All rights reserved.
#
# This software was developed by Stanford University and the University of Cambridge Computer Laboratory 
# under National Science Foundation under Grant No. CNS-0855268,
# the University of Cambridge Computer Laboratory under EPSRC INTERNET Project EP/H040536/1 and
# by the University of Cambridge Computer Laboratory under DARPA/AFRL contract FA8750-11-C-0249 ("MRC2"), 
# as part of the DARPA MRC research programme.
#
# @NETFPGA_LICENSE_HEADER_START@
#
# Licensed to NetFPGA C.I.C. (NetFPGA) under one or more contributor
# license agreements.  See the NOTICE file distributed with this work for
# additional information regarding copyright ownership.  NetFPGA licenses this
# file to you under the NetFPGA Hardware-Software License, Version 1.0 (the
# "License"); you may not use this file except in compliance with the
# License.  You may obtain a copy of the License at:
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

# Hierachical cell : SUME 10g interface block design
proc create_hier_cell_nf_sume_naudit_dma_engine { parentCell coreName } {

   # Check argument
   if { $parentCell eq "" || $coreName eq "" } {
      puts "ERROR: Empty argument(s)!"
      return
   }

   # Get object for parentCell
   set parentObj [get_bd_cells $parentCell]
   if { $parentCell == "" } {
      puts "ERROR: Unable to find parent cell <$parentCell>!"
      return
   }

   # parentObj should be hier block
   set parentType [get_property TYPE $parentObj]
   if { $parentType ne "hier"} {
      puts "ERROR: Parent <$parentObj> has TYPE = <$parentType>."
   }

   # Save current instance; Restore later
   set oldCurInst [current_bd_instance .]

   # Set parent object as current
   current_bd_instance $parentObj

   # Create cell and set as current instance
   set hier_obj [create_bd_cell -type hier $coreName]
   current_bd_instance $hier_obj

   # Create bd external ports
   create_bd_pin -dir I -type clk pcie_sys_clkp
   create_bd_pin -dir I -type clk pcie_sys_clkn

   create_bd_pin -dir I pcie_sys_reset

   create_bd_pin -dir I -from 0 -to 7 pcie_7x_mgt_rxn
   create_bd_pin -dir I -from 0 -to 7 pcie_7x_mgt_rxp
   create_bd_pin -dir O -from 0 -to 7 pcie_7x_mgt_txn
   create_bd_pin -dir O -from 0 -to 7 pcie_7x_mgt_txp

   create_bd_pin -dir I -type clk axis_aclk
   create_bd_pin -dir I axis_aresetn

   create_bd_pin -dir I -type clk m_axi_aclk
   create_bd_pin -dir I m_axi_aresetn

   create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi_lite
   create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_lite
   create_bd_pin -dir O -type clk pcie_user_clk 

   create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s_axis
   create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 m_axis

   # pcie endpoint input clock buffer.
   create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf:2.1 util_ds_buf_0
   set_property -dict [list CONFIG.C_BUF_TYPE {IBUFDSGTE}] [get_bd_cells util_ds_buf_0]

   # Main pcie reset is active low, but pcie endpoint needs active high reset.
   create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 pcie_inverter_0
   set_property -dict [list CONFIG.C_SIZE {1}] [get_bd_cells pcie_inverter_0]
   set_property -dict [list CONFIG.C_OPERATION {not}] [get_bd_cells pcie_inverter_0]
   
   # pcie user clock reset inverter.
   create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 user_pcie_inverter_0
   set_property -dict [list CONFIG.C_SIZE {1}] [get_bd_cells user_pcie_inverter_0]
   set_property -dict [list CONFIG.C_OPERATION {not}] [get_bd_cells user_pcie_inverter_0]

   # load pcie endpoint.
   create_bd_cell -type ip -vlnv xilinx.com:ip:pcie3_7x:4.2 pcie3_7x_1
   set_property -dict [list CONFIG.xlnx_ref_board {None}] [get_bd_cells pcie3_7x_1] 
   set_property -dict [list CONFIG.pcie_blk_locn {X0Y1}] [get_bd_cells pcie3_7x_1] 
   set_property -dict [list CONFIG.PL_LINK_CAP_MAX_LINK_WIDTH {X8}] [get_bd_cells pcie3_7x_1] 
   set_property -dict [list CONFIG.PL_LINK_CAP_MAX_LINK_SPEED {8.0_GT/s}] [get_bd_cells pcie3_7x_1] 
   set_property -dict [list CONFIG.axisten_if_enable_client_tag {false}] [get_bd_cells pcie3_7x_1] 
   set_property -dict [list CONFIG.pf0_bar0_64bit {true}] [get_bd_cells pcie3_7x_1] 
   set_property -dict [list CONFIG.pf0_bar0_scale {Megabytes}] [get_bd_cells pcie3_7x_1] 
   set_property -dict [list CONFIG.pf0_bar0_size {4}] [get_bd_cells pcie3_7x_1] 
   set_property -dict [list CONFIG.pf0_bar2_enabled {true}] [get_bd_cells pcie3_7x_1] 
   set_property -dict [list CONFIG.pf0_bar2_64bit {true}] [get_bd_cells pcie3_7x_1] 
   set_property -dict [list CONFIG.pf0_bar2_scale {Megabytes}] [get_bd_cells pcie3_7x_1] 
   set_property -dict [list CONFIG.pf0_bar2_size {4}] [get_bd_cells pcie3_7x_1] 
   set_property -dict [list CONFIG.pf0_bar4_enabled {true}] [get_bd_cells pcie3_7x_1] 
   set_property -dict [list CONFIG.pf0_bar4_64bit {true}] [get_bd_cells pcie3_7x_1] 
   set_property -dict [list CONFIG.pf0_bar4_scale {Megabytes}] [get_bd_cells pcie3_7x_1] 
   set_property -dict [list CONFIG.pf0_bar4_size {4}] [get_bd_cells pcie3_7x_1] 
   set_property -dict [list CONFIG.pf0_msix_enabled {true}] [get_bd_cells pcie3_7x_1] 
   set_property -dict [list CONFIG.PF0_MSIX_CAP_TABLE_SIZE {040}] [get_bd_cells pcie3_7x_1]
   set_property -dict [list CONFIG.mode_selection {Advanced}] [get_bd_cells pcie3_7x_1]
   set_property -dict [list CONFIG.gen_x0y0 {false}] [get_bd_cells pcie3_7x_1]
   set_property -dict [list CONFIG.gen_x0y1 {true}] [get_bd_cells pcie3_7x_1]
   set_property -dict [list CONFIG.axisten_if_width {256_bit}] [get_bd_cells pcie3_7x_1]
   set_property -dict [list CONFIG.AXISTEN_IF_RC_STRADDLE {true}] [get_bd_cells pcie3_7x_1]
   set_property -dict [list CONFIG.PF0_DEVICE_ID {7038}] [get_bd_cells pcie3_7x_1]
   set_property -dict [list CONFIG.PF1_DEVICE_ID {7011}] [get_bd_cells pcie3_7x_1]
   set_property -dict [list CONFIG.pf0_bar2_type {Memory}] [get_bd_cells pcie3_7x_1]
   set_property -dict [list CONFIG.pf0_bar4_type {Memory}] [get_bd_cells pcie3_7x_1]
   set_property -dict [list CONFIG.PF0_MSIX_CAP_TABLE_OFFSET {00000000}] [get_bd_cells pcie3_7x_1]
   set_property -dict [list CONFIG.PF0_MSIX_CAP_TABLE_BIR {BAR_1:0}] [get_bd_cells pcie3_7x_1]
   set_property -dict [list CONFIG.PF0_MSIX_CAP_PBA_OFFSET {00000100}] [get_bd_cells pcie3_7x_1]
   set_property -dict [list CONFIG.PF0_MSIX_CAP_PBA_BIR {BAR_1:0}] [get_bd_cells pcie3_7x_1]
   set_property -dict [list CONFIG.axisten_freq {250}] [get_bd_cells pcie3_7x_1]
   set_property -dict [list CONFIG.en_ext_clk {false}] [get_bd_cells pcie3_7x_1]
### new config
   set_property -dict [list CONFIG.AXISTEN_IF_RC_STRADDLE {false}] [get_bd_cells pcie3_7x_1]
   set_property -dict [list CONFIG.SRIOV_CAP_ENABLE {true}] [get_bd_cells pcie3_7x_1]
   set_property -dict [list CONFIG.PF0_SRIOV_CAP_INITIAL_VF {1}] [get_bd_cells pcie3_7x_1] 
   set_property -dict [list CONFIG.PF0_SRIOV_FIRST_VF_OFFSET {64}] [get_bd_cells pcie3_7x_1] 
   set_property -dict [list CONFIG.VF0_MSIX_CAP_TABLE_SIZE {001}] [get_bd_cells pcie3_7x_1]
   set_property -dict [list CONFIG.VF0_MSIX_CAP_TABLE_OFFSET {00000040}] [get_bd_cells pcie3_7x_1] 
   set_property -dict [list CONFIG.VF0_MSIX_CAP_TABLE_BIR {BAR_1:0}] [get_bd_cells pcie3_7x_1] 
   set_property -dict [list CONFIG.VF0_MSIX_CAP_PBA_OFFSET {00000050}] [get_bd_cells pcie3_7x_1] 
   set_property -dict [list CONFIG.VF0_MSIX_CAP_PBA_BIR {BAR_1:0}] [get_bd_cells pcie3_7x_1] 
   set_property -dict [list CONFIG.pf0_ari_enabled {true}] [get_bd_cells pcie3_7x_1] 
   set_property -dict [list CONFIG.SRIOV_CAP_ENABLE_EXT {true}] [get_bd_cells pcie3_7x_1]  
   set_property -dict [list CONFIG.pf0_sriov_cap_ver {1}] [get_bd_cells pcie3_7x_1] 
   set_property -dict [list CONFIG.PF0_SRIOV_CAP_INITIAL_VF {2}] [get_bd_cells pcie3_7x_1] 
   set_property -dict [list CONFIG.PF0_SRIOV_VF_DEVICE_ID {7028}] [get_bd_cells pcie3_7x_1] 
   set_property -dict [list CONFIG.VF1_MSIX_CAP_TABLE_SIZE {001}] [get_bd_cells pcie3_7x_1] 
   set_property -dict [list CONFIG.VF1_MSIX_CAP_TABLE_OFFSET {00000040}] [get_bd_cells pcie3_7x_1] 
   set_property -dict [list CONFIG.VF1_MSIX_CAP_TABLE_BIR {BAR_1:0}] [get_bd_cells pcie3_7x_1] 
   set_property -dict [list CONFIG.VF1_MSIX_CAP_PBA_OFFSET {00000050}] [get_bd_cells pcie3_7x_1] 
   set_property -dict [list CONFIG.VF1_MSIX_CAP_PBA_BIR {BAR_1:0}] [get_bd_cells pcie3_7x_1]  
   set_property -dict [list CONFIG.pf0_sriov_bar0_scale {Megabytes}]  [get_bd_cells pcie3_7x_1] 
   set_property -dict [list CONFIG.VF0_MSIX_CAP_TABLE_SIZE {000}] [get_bd_cells pcie3_7x_1] 
   set_property -dict [list CONFIG.VF0_MSIX_CAP_TABLE_OFFSET {00000000}] [get_bd_cells pcie3_7x_1] 
   set_property -dict [list CONFIG.VF0_MSIX_CAP_PBA_OFFSET {00000000}] [get_bd_cells pcie3_7x_1]  
   set_property -dict [list CONFIG.VF1_MSIX_CAP_TABLE_SIZE {000}] [get_bd_cells pcie3_7x_1]  
   set_property -dict [list CONFIG.VF1_MSIX_CAP_TABLE_OFFSET {00000000}] [get_bd_cells pcie3_7x_1]  
   set_property -dict [list CONFIG.VF1_MSIX_CAP_PBA_OFFSET {00000000}] [get_bd_cells pcie3_7x_1] 
   set_property -dict [list CONFIG.en_msi_per_vec_masking {true}] [get_bd_cells pcie3_7x_1]
   set_property -dict [list CONFIG.PF0_INTERRUPT_PIN {NONE}] [get_bd_cells pcie3_7x_1]

  
   # load dma.
   create_bd_cell -type ip -vlnv NetFPGA:NetFPGA:nf_naudit_dma:1.0 nf_naudit_dma_0	

   # This async fifo is connected to dma tx and rx.
   create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:1.1 axis_data_fifo_0
   set_property -dict [list CONFIG.TDATA_NUM_BYTES {32}] [get_bd_cells axis_data_fifo_0]
   set_property -dict [list CONFIG.TUSER_WIDTH {128}] [get_bd_cells axis_data_fifo_0]
   set_property -dict [list CONFIG.IS_ACLK_ASYNC {1}] [get_bd_cells axis_data_fifo_0]
   set_property -dict [list CONFIG.FIFO_DEPTH {32}] [get_bd_cells axis_data_fifo_0]
   
   create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:1.1 axis_data_fifo_1
   set_property -dict [list CONFIG.TDATA_NUM_BYTES {32}] [get_bd_cells axis_data_fifo_1]
   set_property -dict [list CONFIG.TUSER_WIDTH {128}] [get_bd_cells axis_data_fifo_1]
   set_property -dict [list CONFIG.IS_ACLK_ASYNC {1}] [get_bd_cells axis_data_fifo_1]
   set_property -dict [list CONFIG.FIFO_DEPTH {32}] [get_bd_cells axis_data_fifo_1]
 
   # External port connections
   connect_bd_net [get_bd_pins pcie_sys_clkp] [get_bd_pins util_ds_buf_0/IBUF_DS_P]
   connect_bd_net [get_bd_pins pcie_sys_clkn] [get_bd_pins util_ds_buf_0/IBUF_DS_N]
   
   connect_bd_net [get_bd_pins pcie_sys_reset] [get_bd_pins pcie_inverter_0/Op1]
   
   connect_bd_net [get_bd_pins pcie_7x_mgt_rxn] [get_bd_pins pcie3_7x_1/pci_exp_rxn]	
   connect_bd_net [get_bd_pins pcie_7x_mgt_rxp] [get_bd_pins pcie3_7x_1/pci_exp_rxp]
   connect_bd_net [get_bd_pins pcie_7x_mgt_txn] [get_bd_pins pcie3_7x_1/pci_exp_txn]
   connect_bd_net [get_bd_pins pcie_7x_mgt_txp] [get_bd_pins pcie3_7x_1/pci_exp_txp]
   
   connect_bd_net [get_bd_pins axis_aclk] [get_bd_pins axis_data_fifo_0/m_axis_aclk]
   connect_bd_net [get_bd_pins axis_aclk] [get_bd_pins axis_data_fifo_1/s_axis_aclk]
   
   connect_bd_net [get_bd_pins axis_aresetn] [get_bd_pins axis_data_fifo_0/m_axis_aresetn]
   connect_bd_net [get_bd_pins axis_aresetn] [get_bd_pins axis_data_fifo_1/s_axis_aresetn]

   connect_bd_net [get_bd_pins m_axi_aresetn] [get_bd_pins nf_naudit_dma_0/m_axi_lite_aresetn]
   connect_bd_net [get_bd_pins m_axi_aclk] [get_bd_pins nf_naudit_dma_0/m_axi_lite_aclk] 
      
   # Internal connection
   connect_bd_net [get_bd_pins util_ds_buf_0/IBUF_OUT] [get_bd_pins pcie3_7x_1/sys_clk]
   connect_bd_net [get_bd_pins pcie_inverter_0/Res] [get_bd_pins pcie3_7x_1/sys_reset]
   
   connect_bd_net [get_bd_pins pcie3_7x_1/user_clk] [get_bd_pins nf_naudit_dma_0/user_clk]
   connect_bd_net [get_bd_pins pcie3_7x_1/user_reset] [get_bd_pins nf_naudit_dma_0/user_reset]
   connect_bd_net [get_bd_pins pcie3_7x_1/user_reset] [get_bd_pins user_pcie_inverter_0/Op1]
   connect_bd_net [get_bd_pins pcie3_7x_1/user_lnk_up] [get_bd_pins nf_naudit_dma_0/user_lnk_up]
   connect_bd_net [get_bd_pins pcie3_7x_1/user_app_rdy] [get_bd_pins nf_naudit_dma_0/user_app_rdy]
   
   connect_bd_intf_net [get_bd_intf_pins pcie3_7x_1/m_axis_cq] [get_bd_intf_pins nf_naudit_dma_0/m_axis_cq]
   connect_bd_intf_net [get_bd_intf_pins pcie3_7x_1/m_axis_rc] [get_bd_intf_pins nf_naudit_dma_0/m_axis_rc]
   connect_bd_intf_net [get_bd_intf_pins pcie3_7x_1/s_axis_rq] [get_bd_intf_pins nf_naudit_dma_0/s_axis_rq]
   connect_bd_intf_net [get_bd_intf_pins pcie3_7x_1/s_axis_cc] [get_bd_intf_pins nf_naudit_dma_0/s_axis_cc]
    
   connect_bd_intf_net [get_bd_intf_pins pcie3_7x_1/pcie3_cfg_control] [get_bd_intf_pins nf_naudit_dma_0/cfg_control]
   connect_bd_intf_net [get_bd_intf_pins pcie3_7x_1/pcie3_cfg_ext] [get_bd_intf_pins nf_naudit_dma_0/cfg_ext]
   connect_bd_intf_net [get_bd_intf_pins pcie3_7x_1/pcie3_cfg_mesg_tx] [get_bd_intf_pins nf_naudit_dma_0/cfg_msg_transmit]	 
   connect_bd_intf_net [get_bd_intf_pins pcie3_7x_1/pcie3_cfg_mesg_rcvd] [get_bd_intf_pins nf_naudit_dma_0/cfg_msg_received]
   connect_bd_intf_net [get_bd_intf_pins pcie3_7x_1/pcie3_cfg_status] [get_bd_intf_pins nf_naudit_dma_0/cfg_status]
   connect_bd_intf_net [get_bd_intf_pins pcie3_7x_1/pcie3_per_func_status] [get_bd_intf_pins nf_naudit_dma_0/per_func_status]
   connect_bd_intf_net [get_bd_intf_pins pcie3_7x_1/pcie3_transmit_fc] [get_bd_intf_pins nf_naudit_dma_0/transmit_fc]
   connect_bd_intf_net [get_bd_intf_pins pcie3_7x_1/pcie_cfg_fc] [get_bd_intf_pins nf_naudit_dma_0/cfg_fc]
   connect_bd_intf_net [get_bd_intf_pins pcie3_7x_1/pcie_cfg_mgmt] [get_bd_intf_pins nf_naudit_dma_0/cfg_mgmt]
   connect_bd_intf_net [get_bd_intf_pins pcie3_7x_1/pcie3_cfg_msi] [get_bd_intf_pins nf_naudit_dma_0/cfg_interrupt_msi]
   connect_bd_intf_net [get_bd_intf_pins pcie3_7x_1/pcie3_cfg_msix] [get_bd_intf_pins nf_naudit_dma_0/cfg_interrupt_msix]
   connect_bd_intf_net [get_bd_intf_pins pcie3_7x_1/pcie3_cfg_interrupt] [get_bd_intf_pins nf_naudit_dma_0/cfg_interrupt]
    

   connect_bd_intf_net [get_bd_intf_pins nf_naudit_dma_0/s2c] [get_bd_intf_pins axis_data_fifo_0/S_AXIS]
   connect_bd_intf_net [get_bd_intf_pins axis_data_fifo_1/M_AXIS] [get_bd_intf_pins nf_naudit_dma_0/c2s]
   
   connect_bd_net [get_bd_pins pcie3_7x_1/user_clk] [get_bd_pins axis_data_fifo_0/s_axis_aclk]
   connect_bd_net [get_bd_pins pcie3_7x_1/user_clk] [get_bd_pins axis_data_fifo_1/m_axis_aclk]
   
   connect_bd_net [get_bd_pins user_pcie_inverter_0/Res] [get_bd_pins axis_data_fifo_0/s_axis_aresetn]
   connect_bd_net [get_bd_pins user_pcie_inverter_0/Res] [get_bd_pins axis_data_fifo_1/m_axis_aresetn]
   
   connect_bd_intf_net [get_bd_intf_pins axis_data_fifo_0/M_AXIS] [get_bd_intf_pin m_axis]
   connect_bd_intf_net [get_bd_intf_pins axis_data_fifo_1/S_AXIS] [get_bd_intf_pin s_axis]
 
   connect_bd_intf_net [get_bd_intf_pins m_axi_lite] [get_bd_intf_pins nf_naudit_dma_0/m_axi_lite] 
   connect_bd_intf_net [get_bd_intf_pins s_axi_lite] [get_bd_intf_pins nf_naudit_dma_0/s_axi_lite]
   connect_bd_net [get_bd_pins pcie_user_clk] [get_bd_pins pcie3_7x_1/user_clk]
   
   
   # Restore current instance
   current_bd_instance $oldCurInst
}
