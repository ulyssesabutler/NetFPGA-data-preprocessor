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

# Set variables

# CORE CONFIG parameters
set sharedLogic          "FALSE"
set tdataWidth           256

set convWidth [expr $tdataWidth/8]

if { $sharedLogic eq "True" || $sharedLogic eq "TRUE" || $sharedLogic eq "true" } {
   set supportLevel 1
} else {
   set supportLevel 0
}

create_ip -name axi_10g_ethernet -vendor xilinx.com -library ip -version 3.1 -module_name axi_10g_ethernet_nonshared
set_property -dict [list CONFIG.Management_Interface {false}] [get_ips axi_10g_ethernet_nonshared]
set_property -dict [list CONFIG.base_kr {BASE-R}] [get_ips axi_10g_ethernet_nonshared]
set_property -dict [list CONFIG.SupportLevel $supportLevel] [get_ips axi_10g_ethernet_nonshared]
set_property -dict [list CONFIG.autonegotiation {0}] [get_ips axi_10g_ethernet_nonshared]
set_property -dict [list CONFIG.fec {0}] [get_ips axi_10g_ethernet_nonshared]
set_property -dict [list CONFIG.Statistics_Gathering {0}] [get_ips axi_10g_ethernet_nonshared]

create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.1 -module_name fifo_generator_status
set_property -dict [list CONFIG.Fifo_Implementation {Independent_Clocks_Block_RAM}] [get_ips fifo_generator_status]
set_property -dict [list CONFIG.Performance_Options {First_Word_Fall_Through}] [get_ips fifo_generator_status]
set_property -dict [list CONFIG.Input_Data_Width {458} CONFIG.Input_Depth {16}] [get_ips fifo_generator_status]
set_property -dict [list CONFIG.Reset_Pin {false}] [get_ips fifo_generator_status]
set_property -dict [list CONFIG.Output_Data_Width {458} CONFIG.Output_Depth {16}] [get_ips fifo_generator_status]
set_property -dict [list CONFIG.Full_Flags_Reset_Value {0}] [get_ips fifo_generator_status]
set_property -dict [list CONFIG.Use_Dout_Reset {false}] [get_ips fifo_generator_status]
set_property -dict [list CONFIG.Data_Count_Width {4}] [get_ips fifo_generator_status]
set_property -dict [list CONFIG.Write_Data_Count_Width {4}] [get_ips fifo_generator_status]
set_property -dict [list CONFIG.Read_Data_Count_Width {4}] [get_ips fifo_generator_status]
set_property -dict [list CONFIG.Full_Threshold_Assert_Value {15}] [get_ips fifo_generator_status]
set_property -dict [list CONFIG.Full_Threshold_Negate_Value {14}] [get_ips fifo_generator_status]
set_property -dict [list CONFIG.Empty_Threshold_Assert_Value {4}] [get_ips fifo_generator_status]
set_property -dict [list CONFIG.Empty_Threshold_Negate_Value {5}] [get_ips fifo_generator_status]

create_ip -name util_vector_logic -vendor xilinx.com -library ip -version 2.0 -module_name inverter_0
set_property -dict [list CONFIG.C_SIZE {1}] [get_ips inverter_0]
set_property -dict [list CONFIG.C_OPERATION {not}] [get_ips inverter_0]

#PORTED version
create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.1 -module_name fifo_generator_1_9
set_property -dict [list CONFIG.Fifo_Implementation {Independent_Clocks_Block_RAM} CONFIG.Performance_Options {First_Word_Fall_Through} CONFIG.Input_Data_Width {1} CONFIG.Input_Depth {16} CONFIG.Output_Data_Width {1} CONFIG.Output_Depth {16} CONFIG.Data_Count_Width {4} CONFIG.Write_Data_Count_Width {4} CONFIG.Read_Data_Count_Width {4} CONFIG.Full_Threshold_Assert_Value {13} CONFIG.Full_Threshold_Negate_Value {12}] [get_ips fifo_generator_1_9]

## gen DMA FIFOs out of context
create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.1 -module_name user_fifo
set_property -dict [list CONFIG.INTERFACE_TYPE {AXI_STREAM} CONFIG.TDATA_NUM_BYTES {32} CONFIG.TUSER_WIDTH {0} CONFIG.Enable_TLAST {true} CONFIG.HAS_TKEEP {true} CONFIG.TSTRB_WIDTH {32} CONFIG.TKEEP_WIDTH {32} CONFIG.FIFO_Implementation_wach {Common_Clock_Distributed_RAM} CONFIG.Full_Threshold_Assert_Value_wach {15} CONFIG.Empty_Threshold_Assert_Value_wach {14} CONFIG.FIFO_Implementation_wrch {Common_Clock_Distributed_RAM} CONFIG.Full_Threshold_Assert_Value_wrch {15} CONFIG.Empty_Threshold_Assert_Value_wrch {14} CONFIG.FIFO_Implementation_rach {Common_Clock_Distributed_RAM} CONFIG.Full_Threshold_Assert_Value_rach {15} CONFIG.Empty_Threshold_Assert_Value_rach {14}] [get_ips user_fifo]

create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.1 -module_name tag_fifo
set_property -dict [list CONFIG.INTERFACE_TYPE {AXI_STREAM} CONFIG.Clock_Type_AXI {Common_Clock} CONFIG.TDATA_NUM_BYTES {32} CONFIG.TUSER_WIDTH {0} CONFIG.HAS_TKEEP {true} CONFIG.TSTRB_WIDTH {32} CONFIG.TKEEP_WIDTH {32} CONFIG.FIFO_Implementation_wach {Common_Clock_Distributed_RAM} CONFIG.Full_Threshold_Assert_Value_wach {15} CONFIG.Empty_Threshold_Assert_Value_wach {14} CONFIG.FIFO_Implementation_wdch {Common_Clock_Block_RAM} CONFIG.Empty_Threshold_Assert_Value_wdch {1022} CONFIG.FIFO_Implementation_wrch {Common_Clock_Distributed_RAM} CONFIG.Full_Threshold_Assert_Value_wrch {15} CONFIG.Empty_Threshold_Assert_Value_wrch {14} CONFIG.FIFO_Implementation_rach {Common_Clock_Distributed_RAM} CONFIG.Full_Threshold_Assert_Value_rach {15} CONFIG.Empty_Threshold_Assert_Value_rach {14} CONFIG.FIFO_Implementation_rdch {Common_Clock_Block_RAM} CONFIG.Empty_Threshold_Assert_Value_rdch {1022} CONFIG.FIFO_Implementation_axis {Common_Clock_Block_RAM} CONFIG.Empty_Threshold_Assert_Value_axis {1022}] [get_ips tag_fifo]

create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.1 -module_name stream_fifo
set_property -dict [list CONFIG.INTERFACE_TYPE {AXI_STREAM} CONFIG.TDATA_NUM_BYTES {32} CONFIG.TUSER_WIDTH {0} CONFIG.Enable_TLAST {true} CONFIG.HAS_TKEEP {true} CONFIG.Input_Depth_axis {256} CONFIG.TSTRB_WIDTH {32} CONFIG.TKEEP_WIDTH {32} CONFIG.FIFO_Implementation_wach {Common_Clock_Distributed_RAM} CONFIG.Full_Threshold_Assert_Value_wach {15} CONFIG.Empty_Threshold_Assert_Value_wach {14} CONFIG.FIFO_Implementation_wrch {Common_Clock_Distributed_RAM} CONFIG.Full_Threshold_Assert_Value_wrch {15} CONFIG.Empty_Threshold_Assert_Value_wrch {14} CONFIG.FIFO_Implementation_rach {Common_Clock_Distributed_RAM} CONFIG.Full_Threshold_Assert_Value_rach {15} CONFIG.Empty_Threshold_Assert_Value_rach {14} CONFIG.Full_Threshold_Assert_Value_axis {255} CONFIG.Empty_Threshold_Assert_Value_axis {254}] [get_ips stream_fifo]

create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.3 -module_name blk_mem_descriptor
#set_property -dict [list CONFIG.Memory_Type {Simple_Dual_Port_RAM} CONFIG.Use_Byte_Write_Enable {true} CONFIG.Byte_Size {8} CONFIG.Write_Width_A {64} CONFIG.Write_Depth_A {1024} CONFIG.Operating_Mode_A {WRITE_FIRST} CONFIG.Read_Width_A {64} CONFIG.Write_Width_B {64} CONFIG.Read_Width_B {64} CONFIG.Enable_B {Use_ENB_Pin} CONFIG.Register_PortA_Output_of_Memory_Primitives {false} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Enable_Rate {100}] [get_ips blk_mem_descriptor]
set_property -dict [list CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Use_Byte_Write_Enable {true} CONFIG.Byte_Size {8} CONFIG.Write_Width_A {64} CONFIG.Write_Depth_A {1024} CONFIG.Operating_Mode_A {WRITE_FIRST} CONFIG.Read_Width_A {64} CONFIG.Write_Width_B {64} CONFIG.Read_Width_B {64} CONFIG.Enable_B {Use_ENB_Pin} CONFIG.Register_PortA_Output_of_Memory_Primitives {false} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Enable_Rate {100}] [get_ips blk_mem_descriptor]
 



