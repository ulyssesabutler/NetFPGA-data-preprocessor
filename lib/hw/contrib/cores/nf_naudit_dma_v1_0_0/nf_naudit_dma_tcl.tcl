#
# Copyright (c) 2015 University of Cambridge
# All rights reserved.
#
# This software was developed by the University of Cambridge Computer Laboratory
# under EPSRC INTERNET Project EP/H040536/1, National Science Foundation under Grant No. CNS-0855268,
# and Defense Advanced Research Projects Agency (DARPA) and Air Force Research Laboratory (AFRL),
# under contract FA8750-11-C-0249.
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

set device 		{xc7vx690tffg1761-3}
set ip_name 		{nf_naudit_dma}
set lib_name 		{NetFPGA}
set vendor_name 	{NetFPGA}
set ip_display_name 	{nf_naudit_dma}
set ip_description 	{University Autonoma Madrid DMA engine for NetFPGA SUME}
set vendor_display_name {NetFPGA}
set vendor_company_url 	{http://www.netfpga.org}
set ip_version 		{1.0}


## Other
set proj_dir 		./ip_proj
set repo_dir 		../


## parameters for all the IPs
# axi-lite protocol axis fifo
set axi_lite_fifo_name 	axis_fifo_2clk_32d_12u
set axis_fifo_params [dict create CONFIG.INTERFACE_TYPE {AXI_STREAM} \
			 	  CONFIG.Clock_Type_AXI {Independent_Clock} \
			 	  CONFIG.TDATA_NUM_BYTES {4} \
		  		  CONFIG.FIFO_Implementation_axis {Independent_Clocks_Distributed_RAM} \
			 	  CONFIG.Input_Depth_axis {16} \
	  			  CONFIG.TSTRB_WIDTH {4} \
			 	  CONFIG.TKEEP_WIDTH {4} \
				  CONFIG.TUSER_WIDTH {12} \
				  CONFIG.FIFO_Implementation_wach {Independent_Clocks_Distributed_RAM} \
	 			  CONFIG.Full_Threshold_Assert_Value_wach {15} \
				  CONFIG.Empty_Threshold_Assert_Value_wach {13} \
				  CONFIG.FIFO_Implementation_wdch {Independent_Clocks_Block_RAM} \
			 	  CONFIG.Empty_Threshold_Assert_Value_wdch {1021} \
				  CONFIG.FIFO_Implementation_wrch {Independent_Clocks_Distributed_RAM} \
				  CONFIG.Full_Threshold_Assert_Value_wrch {15} \
 				  CONFIG.Empty_Threshold_Assert_Value_wrch {13} \
	  			  CONFIG.FIFO_Implementation_rach {Independent_Clocks_Distributed_RAM} \
				  CONFIG.Full_Threshold_Assert_Value_rach {15} \
				  CONFIG.Empty_Threshold_Assert_Value_rach {13} \
				  CONFIG.FIFO_Implementation_rdch {Independent_Clocks_Block_RAM} \
				  CONFIG.Empty_Threshold_Assert_Value_rdch {1021} \
	  			  CONFIG.Full_Threshold_Assert_Value_axis {1023} \
		  		  CONFIG.Empty_Threshold_Assert_Value_axis {1021}]


# Axis - broadcaster
set axis_broadcaster_name axis_broadcaster_0
set axis_broadcaster_params [dict create CONFIG.M_TDATA_NUM_BYTES {32} \
					 CONFIG.S_TDATA_NUM_BYTES {32} \
					 CONFIG.M_TUSER_WIDTH {85} \
					 CONFIG.S_TUSER_WIDTH {85} \
					 CONFIG.HAS_TKEEP {1} \
					 CONFIG.HAS_TLAST {1} \
					 CONFIG.M00_TDATA_REMAP {tdata[255:0]} \
					 CONFIG.M01_TDATA_REMAP {tdata[255:0]} \
					 CONFIG.M00_TUSER_REMAP {tuser[84:0]} \
					 CONFIG.M01_TUSER_REMAP {tuser[84:0]}]

#AXIS - switch
set axis_switch_name axis_switch_0
set axis_switch_params [dict create CONFIG.TDATA_NUM_BYTES {32} \
					CONFIG.HAS_TKEEP {1} \
					CONFIG.HAS_TLAST {1} \
					CONFIG.TUSER_WIDTH {33} \
					CONFIG.ARB_ON_TLAST {1}]

# MSIX - block ram
set msix_bram_name blk_mem_gen_0
set msix_bram_params [dict create CONFIG.Memory_Type {True_Dual_Port_RAM} \
				CONFIG.Use_Byte_Write_Enable {true} \
				CONFIG.Byte_Size {8} \
				CONFIG.Write_Width_A {32} \
				CONFIG.Write_Depth_A {1024} \
				CONFIG.use_bram_block {Stand_Alone} \
				CONFIG.Enable_32bit_Address {false} \
				CONFIG.Read_Width_A {32} \
				CONFIG.Write_Width_B {64} \
				CONFIG.Read_Width_B {64} \
				CONFIG.Enable_B {Use_ENB_Pin} \
				CONFIG.Register_PortA_Output_of_Memory_Primitives {false} \
				CONFIG.Register_PortB_Output_of_Memory_Primitives {false} \
				CONFIG.Use_RSTA_Pin {false} \
				CONFIG.Use_RSTB_Pin {false} \
				CONFIG.Port_B_Clock {100} \
				CONFIG.Port_B_Write_Rate {50} \
				CONFIG.Port_B_Enable_Rate {100}]

## # of added files
set_param project.singleFileAddWarning.Threshold 500


### SubCore Reference
set subcore_names {\
		fifo_generator\
		fallthrough_small_fifo\
}

### Source Files List
# Here for all directory
set source_dir { \
		hdl\
}

## include all .xci files
set xci_files [list]
set xci_files [concat \
		$axi_lite_fifo_name\
		$axis_broadcaster_name\
		$axis_switch_name\
		$msix_bram_name\
	]

# get all the verilog files
set VerilogFiles [list]
set VerilogFiles [concat \
			[glob -nocomplain hdl/*]]

set rtl_dirs	[list]
set rtl_dirs	[concat \
			hdl]


# Top Module Name
set top_module_name {nf_naudit_dma}
set top_module_file ./hdl/$top_module_name.v

puts "top_file: $top_module_file \n"

# Inferred Bus Interface
set bus_interfaces [list]
set bus_interfaces [concat \
			xilinx.com:interface:axis_rtl:1.0\
			xilinx.com:interface:aximm_rtl:1.0\
]


#############################################
# Create Project
#############################################
create_project -name ${ip_name} -force -dir "./${proj_dir}" -part ${device}
set_property source_mgmt_mode All [current_project]
set_property top $top_module_name [current_fileset]

# local IP repo
set_property ip_repo_paths $repo_dir [current_fileset]
update_ip_catalog

# include dirs
foreach rtl_dir $rtl_dirs {
        set_property include_dirs $rtl_dirs [current_fileset]
}


# Add verilog sources here
# Add Verilog Files to The IP Core
foreach verilog_file $VerilogFiles {
	add_files -scan_for_includes -norecurse ${verilog_file}
}


###################################################
# Generate Xilinx AXIS-FIFO (xci) - axi-lite
create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.1 -module_name ${axi_lite_fifo_name}
foreach item [dict keys $axis_fifo_params] {
	set val [dict get $axis_fifo_params $item]
	set_property $item $val [get_ips ${axi_lite_fifo_name}]
}
#	puts "( $item , $val ) pair \n"

# Generate Xilinx AXIS-Broadcaster - pcie
create_ip -name axis_broadcaster -vendor xilinx.com -library ip -version 1.1 -module_name ${axis_broadcaster_name}
foreach item [dict keys $axis_broadcaster_params] {
	set val [dict get $axis_broadcaster_params $item]
	set_property $item $val [get_ips ${axis_broadcaster_name}]
}

# Generate Xilinx AXIS-switch - pcie
create_ip -name axis_switch -vendor xilinx.com -library ip -version 1.1 -module_name ${axis_switch_name}
foreach item [dict keys $axis_switch_params] {
	set val [dict get $axis_switch_params $item]
	set_property $item $val [get_ips ${axis_switch_name}]
}

# Generate Xilinx AXIS-BRAM - pcie
create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.3 -module_name ${msix_bram_name}
foreach item [dict keys $msix_bram_params] {
	set val [dict get $msix_bram_params $item]
	set_property $item $val [get_ips ${msix_bram_name}]
}

## add all required xci files to the codebase ##
foreach xci_file $xci_files {
	set xci_file_xci ""
	set xci_file_xci [append xci_file ".xci"]
	#set subcore_regex NAME=~*$xci_file*
	#set subcore_ipdef [get_files -filter ${subcore_regex}]
	#add_files ${subcore_ipdef}
}
####################################################


update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

ipx::package_project

# Create IP Information
set_property name 			${ip_name} [ipx::current_core]
set_property library 			${lib_name} [ipx::current_core]
set_property vendor_display_name 	${vendor_display_name} [ipx::current_core]
set_property company_url 		${vendor_company_url} [ipx::current_core]
set_property vendor 			${vendor_name} [ipx::current_core]
set_property supported_families 	{{virtex7} {Production}} [ipx::current_core]
set_property taxonomy 			{{/NetFPGA/Generic}} [ipx::current_core]
set_property version 			${ip_version} [ipx::current_core]
set_property display_name 		${ip_display_name} [ipx::current_core]
set_property description 		${ip_description} [ipx::current_core]

# Add SubCore Reference
foreach subcore ${subcore_names} {
	set subcore_regex NAME=~*$subcore*
	set subcore_ipdef [get_ipdefs -filter ${subcore_regex}]

	ipx::add_subcore ${subcore_ipdef} [ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects [ipx::current_core]]
	ipx::add_subcore ${subcore_ipdef}  [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]
	puts "Adding the following subcore: $subcore_ipdef \n"

}

# Auto Generate Parameters
ipx::remove_all_hdl_parameter [ipx::current_core]
ipx::add_model_parameters_from_hdl [ipx::current_core] -top_level_hdl_file $top_module_file -top_module_name $top_module_name
ipx::infer_user_parameters [ipx::current_core]

# Add Ports
ipx::remove_all_port [ipx::current_core]
ipx::add_ports_from_hdl [ipx::current_core] -top_level_hdl_file $top_module_file -top_module_name $top_module_name

# Auto Infer SOME Bus Interfaces (vivado is bad at auto-inferring interfaces)
foreach bus_standard ${bus_interfaces} {
	ipx::infer_bus_interfaces ${bus_standard} [ipx::current_core]
}

#################################################
#### Manually infer the other interfaces ####
#################################################

# interrupt
ipx::add_bus_interface cfg_interrupt [ipx::current_core]
set_property abstraction_type_vlnv xilinx.com:interface:pcie3_cfg_interrupt_rtl:1.0 [ipx::get_bus_interfaces cfg_interrupt -of_objects [ipx::current_core]]
set_property bus_type_vlnv xilinx.com:interface:pcie3_cfg_interrupt:1.0 [ipx::get_bus_interfaces cfg_interrupt -of_objects [ipx::current_core]]
set_property interface_mode master [ipx::get_bus_interfaces cfg_interrupt -of_objects [ipx::current_core]]

ipx::add_port_map INTx_VECTOR [ipx::get_bus_interfaces cfg_interrupt -of_objects [ipx::current_core]]
set_property physical_name cfg_interrupt_int [ipx::get_port_maps INTx_VECTOR -of_objects [ipx::get_bus_interfaces cfg_interrupt -of_objects [ipx::current_core]]]
ipx::add_port_map PENDING [ipx::get_bus_interfaces cfg_interrupt -of_objects [ipx::current_core]]
set_property physical_name cfg_interrupt_pending [ipx::get_port_maps PENDING -of_objects [ipx::get_bus_interfaces cfg_interrupt -of_objects [ipx::current_core]]]
ipx::add_port_map SENT [ipx::get_bus_interfaces cfg_interrupt -of_objects [ipx::current_core]]
set_property physical_name cfg_interrupt_sent [ipx::get_port_maps SENT -of_objects [ipx::get_bus_interfaces cfg_interrupt -of_objects [ipx::current_core]]]


# msi
ipx::add_bus_interface cfg_interrupt_msi [ipx::current_core]
set_property abstraction_type_vlnv xilinx.com:interface:pcie3_cfg_msi_rtl:1.0 [ipx::get_bus_interfaces cfg_interrupt_msi -of_objects [ipx::current_core]]
set_property bus_type_vlnv xilinx.com:interface:pcie3_cfg_msi:1.0 [ipx::get_bus_interfaces cfg_interrupt_msi -of_objects [ipx::current_core]]
set_property interface_mode master [ipx::get_bus_interfaces cfg_interrupt_msi -of_objects [ipx::current_core]]

ipx::add_port_map sent [ipx::get_bus_interfaces cfg_interrupt_msi -of_objects [ipx::current_core]]
set_property physical_name cfg_interrupt_msi_sent [ipx::get_port_maps sent -of_objects [ipx::get_bus_interfaces cfg_interrupt_msi -of_objects [ipx::current_core]]]
ipx::add_port_map tph_st_tag [ipx::get_bus_interfaces cfg_interrupt_msi -of_objects [ipx::current_core]]
set_property physical_name cfg_interrupt_msi_tph_st_tag [ipx::get_port_maps tph_st_tag -of_objects [ipx::get_bus_interfaces cfg_interrupt_msi -of_objects [ipx::current_core]]]
ipx::add_port_map mask_update [ipx::get_bus_interfaces cfg_interrupt_msi -of_objects [ipx::current_core]]
set_property physical_name cfg_interrupt_msi_mask_update [ipx::get_port_maps mask_update -of_objects [ipx::get_bus_interfaces cfg_interrupt_msi -of_objects [ipx::current_core]]]
ipx::add_port_map select [ipx::get_bus_interfaces cfg_interrupt_msi -of_objects [ipx::current_core]]
set_property physical_name cfg_interrupt_msi_select [ipx::get_port_maps select -of_objects [ipx::get_bus_interfaces cfg_interrupt_msi -of_objects [ipx::current_core]]]
ipx::add_port_map data [ipx::get_bus_interfaces cfg_interrupt_msi -of_objects [ipx::current_core]]
set_property physical_name cfg_interrupt_msi_data [ipx::get_port_maps data -of_objects [ipx::get_bus_interfaces cfg_interrupt_msi -of_objects [ipx::current_core]]]
ipx::add_port_map tph_type [ipx::get_bus_interfaces cfg_interrupt_msi -of_objects [ipx::current_core]]
set_property physical_name cfg_interrupt_msi_tph_type [ipx::get_port_maps tph_type -of_objects [ipx::get_bus_interfaces cfg_interrupt_msi -of_objects [ipx::current_core]]]
ipx::add_port_map int_vector [ipx::get_bus_interfaces cfg_interrupt_msi -of_objects [ipx::current_core]]
set_property physical_name cfg_interrupt_msi_int [ipx::get_port_maps int_vector -of_objects [ipx::get_bus_interfaces cfg_interrupt_msi -of_objects [ipx::current_core]]]
ipx::add_port_map tph_present [ipx::get_bus_interfaces cfg_interrupt_msi -of_objects [ipx::current_core]]
set_property physical_name cfg_interrupt_msi_tph_present [ipx::get_port_maps tph_present -of_objects [ipx::get_bus_interfaces cfg_interrupt_msi -of_objects [ipx::current_core]]]
ipx::add_port_map function_number [ipx::get_bus_interfaces cfg_interrupt_msi -of_objects [ipx::current_core]]
set_property physical_name cfg_interrupt_msi_function_number [ipx::get_port_maps function_number -of_objects [ipx::get_bus_interfaces cfg_interrupt_msi -of_objects [ipx::current_core]]]
ipx::add_port_map fail [ipx::get_bus_interfaces cfg_interrupt_msi -of_objects [ipx::current_core]]
set_property physical_name cfg_interrupt_msi_fail [ipx::get_port_maps fail -of_objects [ipx::get_bus_interfaces cfg_interrupt_msi -of_objects [ipx::current_core]]]
ipx::add_port_map enable [ipx::get_bus_interfaces cfg_interrupt_msi -of_objects [ipx::current_core]]
set_property physical_name cfg_interrupt_msi_enable [ipx::get_port_maps enable -of_objects [ipx::get_bus_interfaces cfg_interrupt_msi -of_objects [ipx::current_core]]]
ipx::add_port_map pending_status [ipx::get_bus_interfaces cfg_interrupt_msi -of_objects [ipx::current_core]]
set_property physical_name cfg_interrupt_msi_pending_status [ipx::get_port_maps pending_status -of_objects [ipx::get_bus_interfaces cfg_interrupt_msi -of_objects [ipx::current_core]]]
ipx::add_port_map vf_enable [ipx::get_bus_interfaces cfg_interrupt_msi -of_objects [ipx::current_core]]
set_property physical_name cfg_interrupt_msi_vf_enable [ipx::get_port_maps vf_enable -of_objects [ipx::get_bus_interfaces cfg_interrupt_msi -of_objects [ipx::current_core]]]
ipx::add_port_map attr [ipx::get_bus_interfaces cfg_interrupt_msi -of_objects [ipx::current_core]]
set_property physical_name cfg_interrupt_msi_attr [ipx::get_port_maps attr -of_objects [ipx::get_bus_interfaces cfg_interrupt_msi -of_objects [ipx::current_core]]]
ipx::add_port_map mmenable [ipx::get_bus_interfaces cfg_interrupt_msi -of_objects [ipx::current_core]]
set_property physical_name cfg_interrupt_msi_mmenable [ipx::get_port_maps mmenable -of_objects [ipx::get_bus_interfaces cfg_interrupt_msi -of_objects [ipx::current_core]]]

# msi-x
ipx::add_bus_interface cfg_interrupt_msix [ipx::current_core]
set_property abstraction_type_vlnv xilinx.com:interface:pcie3_cfg_msix_rtl:1.0 [ipx::get_bus_interfaces cfg_interrupt_msix -of_objects [ipx::current_core]]
set_property bus_type_vlnv xilinx.com:interface:pcie3_cfg_msix:1.0 [ipx::get_bus_interfaces cfg_interrupt_msix -of_objects [ipx::current_core]]
set_property interface_mode master [ipx::get_bus_interfaces cfg_interrupt_msix -of_objects [ipx::current_core]]

ipx::add_port_map sent [ipx::get_bus_interfaces cfg_interrupt_msix -of_objects [ipx::current_core]]
set_property physical_name cfg_interrupt_msix_sent [ipx::get_port_maps sent -of_objects [ipx::get_bus_interfaces cfg_interrupt_msix -of_objects [ipx::current_core]]]
ipx::add_port_map vf_mask [ipx::get_bus_interfaces cfg_interrupt_msix -of_objects [ipx::current_core]]
set_property physical_name cfg_interrupt_msix_vf_mask [ipx::get_port_maps vf_mask -of_objects [ipx::get_bus_interfaces cfg_interrupt_msix -of_objects [ipx::current_core]]]
ipx::add_port_map fail [ipx::get_bus_interfaces cfg_interrupt_msix -of_objects [ipx::current_core]]
set_property physical_name cfg_interrupt_msix_fail [ipx::get_port_maps fail -of_objects [ipx::get_bus_interfaces cfg_interrupt_msix -of_objects [ipx::current_core]]]
ipx::add_port_map address [ipx::get_bus_interfaces cfg_interrupt_msix -of_objects [ipx::current_core]]
set_property physical_name cfg_interrupt_msix_address [ipx::get_port_maps address -of_objects [ipx::get_bus_interfaces cfg_interrupt_msix -of_objects [ipx::current_core]]]
ipx::add_port_map data [ipx::get_bus_interfaces cfg_interrupt_msix -of_objects [ipx::current_core]]
set_property physical_name cfg_interrupt_msix_data [ipx::get_port_maps data -of_objects [ipx::get_bus_interfaces cfg_interrupt_msix -of_objects [ipx::current_core]]]
ipx::add_port_map enable [ipx::get_bus_interfaces cfg_interrupt_msix -of_objects [ipx::current_core]]
set_property physical_name cfg_interrupt_msix_enable [ipx::get_port_maps enable -of_objects [ipx::get_bus_interfaces cfg_interrupt_msix -of_objects [ipx::current_core]]]
ipx::add_port_map vf_enable [ipx::get_bus_interfaces cfg_interrupt_msix -of_objects [ipx::current_core]]
set_property physical_name cfg_interrupt_msix_vf_enable [ipx::get_port_maps vf_enable -of_objects [ipx::get_bus_interfaces cfg_interrupt_msix -of_objects [ipx::current_core]]]
ipx::add_port_map int_vector [ipx::get_bus_interfaces cfg_interrupt_msix -of_objects [ipx::current_core]]
set_property physical_name cfg_interrupt_msix_int [ipx::get_port_maps int_vector -of_objects [ipx::get_bus_interfaces cfg_interrupt_msix -of_objects [ipx::current_core]]]
ipx::add_port_map mask [ipx::get_bus_interfaces cfg_interrupt_msix -of_objects [ipx::current_core]]
set_property physical_name cfg_interrupt_msix_mask [ipx::get_port_maps mask -of_objects [ipx::get_bus_interfaces cfg_interrupt_msix -of_objects [ipx::current_core]]]

# cfg-ext
ipx::add_bus_interface cfg_ext [ipx::current_core]
set_property abstraction_type_vlnv xilinx.com:interface:pcie3_cfg_ext_rtl:1.0 [ipx::get_bus_interfaces cfg_ext -of_objects [ipx::current_core]]
set_property bus_type_vlnv xilinx.com:interface:pcie3_cfg_ext:1.0 [ipx::get_bus_interfaces cfg_ext -of_objects [ipx::current_core]]
set_property interface_mode master [ipx::get_bus_interfaces cfg_ext -of_objects [ipx::current_core]]
set_property interface_mode slave [ipx::get_bus_interfaces cfg_ext -of_objects [ipx::current_core]]

ipx::add_port_map read_received [ipx::get_bus_interfaces cfg_ext -of_objects [ipx::current_core]]
set_property physical_name cfg_ext_read_received [ipx::get_port_maps read_received -of_objects [ipx::get_bus_interfaces cfg_ext -of_objects [ipx::current_core]]]
ipx::add_port_map write_data [ipx::get_bus_interfaces cfg_ext -of_objects [ipx::current_core]]
set_property physical_name cfg_ext_write_data [ipx::get_port_maps write_data -of_objects [ipx::get_bus_interfaces cfg_ext -of_objects [ipx::current_core]]]
ipx::add_port_map register_number [ipx::get_bus_interfaces cfg_ext -of_objects [ipx::current_core]]
set_property physical_name cfg_ext_register_number [ipx::get_port_maps register_number -of_objects [ipx::get_bus_interfaces cfg_ext -of_objects [ipx::current_core]]]
ipx::add_port_map read_data [ipx::get_bus_interfaces cfg_ext -of_objects [ipx::current_core]]
set_property physical_name cfg_ext_read_data [ipx::get_port_maps read_data -of_objects [ipx::get_bus_interfaces cfg_ext -of_objects [ipx::current_core]]]
ipx::add_port_map read_data_valid [ipx::get_bus_interfaces cfg_ext -of_objects [ipx::current_core]]
set_property physical_name cfg_ext_read_data_valid [ipx::get_port_maps read_data_valid -of_objects [ipx::get_bus_interfaces cfg_ext -of_objects [ipx::current_core]]]
ipx::add_port_map write_received [ipx::get_bus_interfaces cfg_ext -of_objects [ipx::current_core]]
set_property physical_name cfg_ext_write_received [ipx::get_port_maps write_received -of_objects [ipx::get_bus_interfaces cfg_ext -of_objects [ipx::current_core]]]
ipx::add_port_map write_byte_enable [ipx::get_bus_interfaces cfg_ext -of_objects [ipx::current_core]]
set_property physical_name cfg_ext_write_byte_enable [ipx::get_port_maps write_byte_enable -of_objects [ipx::get_bus_interfaces cfg_ext -of_objects [ipx::current_core]]]
ipx::add_port_map function_number [ipx::get_bus_interfaces cfg_ext -of_objects [ipx::current_core]]
set_property physical_name cfg_ext_function_number [ipx::get_port_maps function_number -of_objects [ipx::get_bus_interfaces cfg_ext -of_objects [ipx::current_core]]]

# cfg-mgmt
ipx::add_bus_interface cfg_mgmt [ipx::current_core]
set_property interface_mode master [ipx::get_bus_interfaces cfg_mgmt -of_objects [ipx::current_core]]
set_property abstraction_type_vlnv xilinx.com:interface:pcie_cfg_mgmt_rtl:1.0 [ipx::get_bus_interfaces cfg_mgmt -of_objects [ipx::current_core]]
set_property bus_type_vlnv xilinx.com:interface:pcie_cfg_mgmt:1.0 [ipx::get_bus_interfaces cfg_mgmt -of_objects [ipx::current_core]]

ipx::add_port_map WRITE_DATA [ipx::get_bus_interfaces cfg_mgmt -of_objects [ipx::current_core]]
set_property physical_name cfg_mgmt_write_data [ipx::get_port_maps WRITE_DATA -of_objects [ipx::get_bus_interfaces cfg_mgmt -of_objects [ipx::current_core]]]
ipx::add_port_map READ_EN [ipx::get_bus_interfaces cfg_mgmt -of_objects [ipx::current_core]]
set_property physical_name cfg_mgmt_read [ipx::get_port_maps READ_EN -of_objects [ipx::get_bus_interfaces cfg_mgmt -of_objects [ipx::current_core]]]
ipx::add_port_map TYPE1_CFG_REG_ACCESS [ipx::get_bus_interfaces cfg_mgmt -of_objects [ipx::current_core]]
set_property physical_name cfg_mgmt_type1_cfg_reg_access [ipx::get_port_maps TYPE1_CFG_REG_ACCESS -of_objects [ipx::get_bus_interfaces cfg_mgmt -of_objects [ipx::current_core]]]
ipx::add_port_map READ_DATA [ipx::get_bus_interfaces cfg_mgmt -of_objects [ipx::current_core]]
set_property physical_name cfg_mgmt_read_data [ipx::get_port_maps READ_DATA -of_objects [ipx::get_bus_interfaces cfg_mgmt -of_objects [ipx::current_core]]]
ipx::add_port_map READ_WRITE_DONE [ipx::get_bus_interfaces cfg_mgmt -of_objects [ipx::current_core]]
set_property physical_name cfg_mgmt_read_write_done [ipx::get_port_maps READ_WRITE_DONE -of_objects [ipx::get_bus_interfaces cfg_mgmt -of_objects [ipx::current_core]]]
ipx::add_port_map BYTE_EN [ipx::get_bus_interfaces cfg_mgmt -of_objects [ipx::current_core]]
set_property physical_name cfg_mgmt_byte_enable [ipx::get_port_maps BYTE_EN -of_objects [ipx::get_bus_interfaces cfg_mgmt -of_objects [ipx::current_core]]]
ipx::add_port_map WRITE_EN [ipx::get_bus_interfaces cfg_mgmt -of_objects [ipx::current_core]]
set_property physical_name cfg_mgmt_write [ipx::get_port_maps WRITE_EN -of_objects [ipx::get_bus_interfaces cfg_mgmt -of_objects [ipx::current_core]]]
ipx::add_port_map ADDR [ipx::get_bus_interfaces cfg_mgmt -of_objects [ipx::current_core]]
set_property physical_name cfg_mgmt_addr [ipx::get_port_maps ADDR -of_objects [ipx::get_bus_interfaces cfg_mgmt -of_objects [ipx::current_core]]]

# fc
ipx::add_bus_interface cfg_fc [ipx::current_core]
set_property interface_mode slave [ipx::get_bus_interfaces cfg_fc -of_objects [ipx::current_core]]
set_property abstraction_type_vlnv xilinx.com:interface:pcie_cfg_fc_rtl:1.0 [ipx::get_bus_interfaces cfg_fc -of_objects [ipx::current_core]]
set_property bus_type_vlnv xilinx.com:interface:pcie_cfg_fc:1.0 [ipx::get_bus_interfaces cfg_fc -of_objects [ipx::current_core]]

ipx::add_port_map NPD [ipx::get_bus_interfaces cfg_fc -of_objects [ipx::current_core]]
set_property physical_name cfg_fc_npd [ipx::get_port_maps NPD -of_objects [ipx::get_bus_interfaces cfg_fc -of_objects [ipx::current_core]]]
ipx::add_port_map PD [ipx::get_bus_interfaces cfg_fc -of_objects [ipx::current_core]]
set_property physical_name cfg_fc_pd [ipx::get_port_maps PD -of_objects [ipx::get_bus_interfaces cfg_fc -of_objects [ipx::current_core]]]
ipx::add_port_map CPLH [ipx::get_bus_interfaces cfg_fc -of_objects [ipx::current_core]]
set_property physical_name cfg_fc_cplh [ipx::get_port_maps CPLH -of_objects [ipx::get_bus_interfaces cfg_fc -of_objects [ipx::current_core]]]
ipx::add_port_map NPH [ipx::get_bus_interfaces cfg_fc -of_objects [ipx::current_core]]
set_property physical_name cfg_fc_nph [ipx::get_port_maps NPH -of_objects [ipx::get_bus_interfaces cfg_fc -of_objects [ipx::current_core]]]
ipx::add_port_map PH [ipx::get_bus_interfaces cfg_fc -of_objects [ipx::current_core]]
set_property physical_name cfg_fc_ph [ipx::get_port_maps PH -of_objects [ipx::get_bus_interfaces cfg_fc -of_objects [ipx::current_core]]]
ipx::add_port_map CPLD [ipx::get_bus_interfaces cfg_fc -of_objects [ipx::current_core]]
set_property physical_name cfg_fc_cpld [ipx::get_port_maps CPLD -of_objects [ipx::get_bus_interfaces cfg_fc -of_objects [ipx::current_core]]]
ipx::add_port_map SEL [ipx::get_bus_interfaces cfg_fc -of_objects [ipx::current_core]]
set_property physical_name cfg_fc_sel [ipx::get_port_maps SEL -of_objects [ipx::get_bus_interfaces cfg_fc -of_objects [ipx::current_core]]]

# cfg-control
ipx::add_bus_interface cfg_control [ipx::current_core]
set_property abstraction_type_vlnv xilinx.com:interface:pcie3_cfg_control_rtl:1.0 [ipx::get_bus_interfaces cfg_control -of_objects [ipx::current_core]]
set_property bus_type_vlnv xilinx.com:interface:pcie3_cfg_control:1.0 [ipx::get_bus_interfaces cfg_control -of_objects [ipx::current_core]]
set_property interface_mode master [ipx::get_bus_interfaces cfg_control -of_objects [ipx::current_core]]

ipx::add_port_map per_function_output_request [ipx::get_bus_interfaces cfg_control -of_objects [ipx::current_core]]
set_property physical_name cfg_per_function_output_request [ipx::get_port_maps per_function_output_request -of_objects [ipx::get_bus_interfaces cfg_control -of_objects [ipx::current_core]]]
ipx::add_port_map hot_reset_out [ipx::get_bus_interfaces cfg_control -of_objects [ipx::current_core]]
set_property physical_name cfg_hot_reset_out [ipx::get_port_maps hot_reset_out -of_objects [ipx::get_bus_interfaces cfg_control -of_objects [ipx::current_core]]]
ipx::add_port_map config_space_enable [ipx::get_bus_interfaces cfg_control -of_objects [ipx::current_core]]
set_property physical_name cfg_config_space_enable [ipx::get_port_maps config_space_enable -of_objects [ipx::get_bus_interfaces cfg_control -of_objects [ipx::current_core]]]
ipx::add_port_map power_state_change_interrupt [ipx::get_bus_interfaces cfg_control -of_objects [ipx::current_core]]
set_property physical_name cfg_power_state_change_interrupt [ipx::get_port_maps power_state_change_interrupt -of_objects [ipx::get_bus_interfaces cfg_control -of_objects [ipx::current_core]]]
ipx::add_port_map flr_in_process [ipx::get_bus_interfaces cfg_control -of_objects [ipx::current_core]]
set_property physical_name cfg_flr_in_process [ipx::get_port_maps flr_in_process -of_objects [ipx::get_bus_interfaces cfg_control -of_objects [ipx::current_core]]]
ipx::add_port_map power_state_change_ack [ipx::get_bus_interfaces cfg_control -of_objects [ipx::current_core]]
set_property physical_name cfg_power_state_change_ack [ipx::get_port_maps power_state_change_ack -of_objects [ipx::get_bus_interfaces cfg_control -of_objects [ipx::current_core]]]
ipx::add_port_map ds_port_number [ipx::get_bus_interfaces cfg_control -of_objects [ipx::current_core]]
set_property physical_name cfg_ds_port_number [ipx::get_port_maps ds_port_number -of_objects [ipx::get_bus_interfaces cfg_control -of_objects [ipx::current_core]]]
ipx::add_port_map ds_function_number [ipx::get_bus_interfaces cfg_control -of_objects [ipx::current_core]]
set_property physical_name cfg_ds_function_number [ipx::get_port_maps ds_function_number -of_objects [ipx::get_bus_interfaces cfg_control -of_objects [ipx::current_core]]]
ipx::add_port_map vf_flr_in_process [ipx::get_bus_interfaces cfg_control -of_objects [ipx::current_core]]
set_property physical_name cfg_vf_flr_in_process [ipx::get_port_maps vf_flr_in_process -of_objects [ipx::get_bus_interfaces cfg_control -of_objects [ipx::current_core]]]
ipx::add_port_map err_uncor_in [ipx::get_bus_interfaces cfg_control -of_objects [ipx::current_core]]
set_property physical_name cfg_err_uncor_in [ipx::get_port_maps err_uncor_in -of_objects [ipx::get_bus_interfaces cfg_control -of_objects [ipx::current_core]]]
ipx::add_port_map per_function_number [ipx::get_bus_interfaces cfg_control -of_objects [ipx::current_core]]
set_property physical_name cfg_per_function_number [ipx::get_port_maps per_function_number -of_objects [ipx::get_bus_interfaces cfg_control -of_objects [ipx::current_core]]]
ipx::add_port_map err_cor_in [ipx::get_bus_interfaces cfg_control -of_objects [ipx::current_core]]
set_property physical_name cfg_err_cor_in [ipx::get_port_maps err_cor_in -of_objects [ipx::get_bus_interfaces cfg_control -of_objects [ipx::current_core]]]
ipx::add_port_map link_training_enable [ipx::get_bus_interfaces cfg_control -of_objects [ipx::current_core]]
set_property physical_name cfg_link_training_enable [ipx::get_port_maps link_training_enable -of_objects [ipx::get_bus_interfaces cfg_control -of_objects [ipx::current_core]]]
ipx::add_port_map ds_bus_number [ipx::get_bus_interfaces cfg_control -of_objects [ipx::current_core]]
set_property physical_name cfg_ds_bus_number [ipx::get_port_maps ds_bus_number -of_objects [ipx::get_bus_interfaces cfg_control -of_objects [ipx::current_core]]]
ipx::add_port_map hot_reset_in [ipx::get_bus_interfaces cfg_control -of_objects [ipx::current_core]]
set_property physical_name cfg_hot_reset_in [ipx::get_port_maps hot_reset_in -of_objects [ipx::get_bus_interfaces cfg_control -of_objects [ipx::current_core]]]
ipx::add_port_map vf_flr_done [ipx::get_bus_interfaces cfg_control -of_objects [ipx::current_core]]
set_property physical_name cfg_vf_flr_done [ipx::get_port_maps vf_flr_done -of_objects [ipx::get_bus_interfaces cfg_control -of_objects [ipx::current_core]]]
ipx::add_port_map subsys_vend_id [ipx::get_bus_interfaces cfg_control -of_objects [ipx::current_core]]
set_property physical_name cfg_subsys_vend_id [ipx::get_port_maps subsys_vend_id -of_objects [ipx::get_bus_interfaces cfg_control -of_objects [ipx::current_core]]]
ipx::add_port_map per_function_update_done [ipx::get_bus_interfaces cfg_control -of_objects [ipx::current_core]]
set_property physical_name cfg_per_function_update_done [ipx::get_port_maps per_function_update_done -of_objects [ipx::get_bus_interfaces cfg_control -of_objects [ipx::current_core]]]
ipx::add_port_map ds_device_number [ipx::get_bus_interfaces cfg_control -of_objects [ipx::current_core]]
set_property physical_name cfg_ds_device_number [ipx::get_port_maps ds_device_number -of_objects [ipx::get_bus_interfaces cfg_control -of_objects [ipx::current_core]]]
ipx::add_port_map req_pm_transition_l23_ready [ipx::get_bus_interfaces cfg_control -of_objects [ipx::current_core]]
set_property physical_name cfg_req_pm_transition_l23_ready [ipx::get_port_maps req_pm_transition_l23_ready -of_objects [ipx::get_bus_interfaces cfg_control -of_objects [ipx::current_core]]]
ipx::add_port_map dsn [ipx::get_bus_interfaces cfg_control -of_objects [ipx::current_core]]
set_property physical_name cfg_dsn [ipx::get_port_maps dsn -of_objects [ipx::get_bus_interfaces cfg_control -of_objects [ipx::current_core]]]
ipx::add_port_map flr_done [ipx::get_bus_interfaces cfg_control -of_objects [ipx::current_core]]
set_property physical_name cfg_flr_done [ipx::get_port_maps flr_done -of_objects [ipx::get_bus_interfaces cfg_control -of_objects [ipx::current_core]]]

# msg_transmit
ipx::add_bus_interface cfg_msg_transmit [ipx::current_core]
set_property interface_mode slave [ipx::get_bus_interfaces cfg_msg_transmit -of_objects [ipx::current_core]]
set_property abstraction_type_vlnv xilinx.com:interface:pcie3_cfg_mesg_tx_rtl:1.0 [ipx::get_bus_interfaces cfg_msg_transmit -of_objects [ipx::current_core]]
set_property bus_type_vlnv xilinx.com:interface:pcie3_cfg_mesg_tx:1.0 [ipx::get_bus_interfaces cfg_msg_transmit -of_objects [ipx::current_core]]

ipx::add_port_map TRANSMIT_TYPE [ipx::get_bus_interfaces cfg_msg_transmit -of_objects [ipx::current_core]]
set_property physical_name cfg_msg_transmit_type [ipx::get_port_maps TRANSMIT_TYPE -of_objects [ipx::get_bus_interfaces cfg_msg_transmit -of_objects [ipx::current_core]]]
ipx::add_port_map TRANSMIT_DATA [ipx::get_bus_interfaces cfg_msg_transmit -of_objects [ipx::current_core]]
set_property physical_name cfg_msg_transmit_data [ipx::get_port_maps TRANSMIT_DATA -of_objects [ipx::get_bus_interfaces cfg_msg_transmit -of_objects [ipx::current_core]]]
ipx::add_port_map TRANSMIT_DONE [ipx::get_bus_interfaces cfg_msg_transmit -of_objects [ipx::current_core]]
set_property physical_name cfg_msg_transmit_done [ipx::get_port_maps TRANSMIT_DONE -of_objects [ipx::get_bus_interfaces cfg_msg_transmit -of_objects [ipx::current_core]]]
ipx::add_port_map TRANSMIT [ipx::get_bus_interfaces cfg_msg_transmit -of_objects [ipx::current_core]]
set_property physical_name cfg_msg_transmit [ipx::get_port_maps TRANSMIT -of_objects [ipx::get_bus_interfaces cfg_msg_transmit -of_objects [ipx::current_core]]]

# msg_received
ipx::add_bus_interface cfg_msg_received [ipx::current_core]
set_property interface_mode slave [ipx::get_bus_interfaces cfg_msg_received -of_objects [ipx::current_core]]
set_property abstraction_type_vlnv xilinx.com:interface:pcie3_cfg_msg_received_rtl:1.0 [ipx::get_bus_interfaces cfg_msg_received -of_objects [ipx::current_core]]
set_property bus_type_vlnv xilinx.com:interface:pcie3_cfg_msg_received:1.0 [ipx::get_bus_interfaces cfg_msg_received -of_objects [ipx::current_core]]

ipx::add_port_map recd [ipx::get_bus_interfaces cfg_msg_received -of_objects [ipx::current_core]]
set_property physical_name cfg_msg_received [ipx::get_port_maps recd -of_objects [ipx::get_bus_interfaces cfg_msg_received -of_objects [ipx::current_core]]]
ipx::add_port_map recd_data [ipx::get_bus_interfaces cfg_msg_received -of_objects [ipx::current_core]]
set_property physical_name cfg_msg_received_data [ipx::get_port_maps recd_data -of_objects [ipx::get_bus_interfaces cfg_msg_received -of_objects [ipx::current_core]]]
ipx::add_port_map recd_type [ipx::get_bus_interfaces cfg_msg_received -of_objects [ipx::current_core]]
set_property physical_name cfg_msg_received_type [ipx::get_port_maps recd_type -of_objects [ipx::get_bus_interfaces cfg_msg_received -of_objects [ipx::current_core]]]

# transmit_fc
ipx::add_bus_interface transmit_fc [ipx::current_core]
set_property interface_mode slave [ipx::get_bus_interfaces transmit_fc -of_objects [ipx::current_core]]
set_property abstraction_type_vlnv xilinx.com:interface:pcie3_transmit_fc_rtl:1.0 [ipx::get_bus_interfaces transmit_fc -of_objects [ipx::current_core]]
set_property bus_type_vlnv xilinx.com:interface:pcie3_transmit_fc:1.0 [ipx::get_bus_interfaces transmit_fc -of_objects [ipx::current_core]]

ipx::add_port_map npd_av [ipx::get_bus_interfaces transmit_fc -of_objects [ipx::current_core]]
set_property physical_name pcie_tfc_npd_av [ipx::get_port_maps npd_av -of_objects [ipx::get_bus_interfaces transmit_fc -of_objects [ipx::current_core]]]
ipx::add_port_map nph_av [ipx::get_bus_interfaces transmit_fc -of_objects [ipx::current_core]]
set_property physical_name pcie_tfc_nph_av [ipx::get_port_maps nph_av -of_objects [ipx::get_bus_interfaces transmit_fc -of_objects [ipx::current_core]]]

# cfg_status
ipx::add_bus_interface cfg_status [ipx::current_core]
set_property abstraction_type_vlnv xilinx.com:interface:pcie3_cfg_status_rtl:1.0 [ipx::get_bus_interfaces cfg_status -of_objects [ipx::current_core]]
set_property bus_type_vlnv xilinx.com:interface:pcie3_cfg_status:1.0 [ipx::get_bus_interfaces cfg_status -of_objects [ipx::current_core]]
set_property interface_mode slave [ipx::get_bus_interfaces cfg_status -of_objects [ipx::current_core]]

ipx::add_port_map max_payload [ipx::get_bus_interfaces cfg_status -of_objects [ipx::current_core]]
set_property physical_name cfg_max_payload [ipx::get_port_maps max_payload -of_objects [ipx::get_bus_interfaces cfg_status -of_objects [ipx::current_core]]]
ipx::add_port_map err_nonfatal_out [ipx::get_bus_interfaces cfg_status -of_objects [ipx::current_core]]
set_property physical_name cfg_err_nonfatal_out [ipx::get_port_maps err_nonfatal_out -of_objects [ipx::get_bus_interfaces cfg_status -of_objects [ipx::current_core]]]
ipx::add_port_map ltssm_state [ipx::get_bus_interfaces cfg_status -of_objects [ipx::current_core]]
set_property physical_name cfg_ltssm_state [ipx::get_port_maps ltssm_state -of_objects [ipx::get_bus_interfaces cfg_status -of_objects [ipx::current_core]]]
ipx::add_port_map rq_seq_num [ipx::get_bus_interfaces cfg_status -of_objects [ipx::current_core]]
set_property physical_name pcie_rq_seq_num [ipx::get_port_maps rq_seq_num -of_objects [ipx::get_bus_interfaces cfg_status -of_objects [ipx::current_core]]]
ipx::add_port_map tph_st_mode [ipx::get_bus_interfaces cfg_status -of_objects [ipx::current_core]]
set_property physical_name cfg_tph_st_mode [ipx::get_port_maps tph_st_mode -of_objects [ipx::get_bus_interfaces cfg_status -of_objects [ipx::current_core]]]
ipx::add_port_map cq_np_req [ipx::get_bus_interfaces cfg_status -of_objects [ipx::current_core]]
set_property physical_name pcie_cq_np_req [ipx::get_port_maps cq_np_req -of_objects [ipx::get_bus_interfaces cfg_status -of_objects [ipx::current_core]]]
ipx::add_port_map tph_requester_enable [ipx::get_bus_interfaces cfg_status -of_objects [ipx::current_core]]
set_property physical_name cfg_tph_requester_enable [ipx::get_port_maps tph_requester_enable -of_objects [ipx::get_bus_interfaces cfg_status -of_objects [ipx::current_core]]]
ipx::add_port_map phy_link_status [ipx::get_bus_interfaces cfg_status -of_objects [ipx::current_core]]
set_property physical_name cfg_phy_link_status [ipx::get_port_maps phy_link_status -of_objects [ipx::get_bus_interfaces cfg_status -of_objects [ipx::current_core]]]
ipx::add_port_map err_fatal_out [ipx::get_bus_interfaces cfg_status -of_objects [ipx::current_core]]
set_property physical_name cfg_err_fatal_out [ipx::get_port_maps err_fatal_out -of_objects [ipx::get_bus_interfaces cfg_status -of_objects [ipx::current_core]]]
ipx::add_port_map function_status [ipx::get_bus_interfaces cfg_status -of_objects [ipx::current_core]]
set_property physical_name cfg_function_status [ipx::get_port_maps function_status -of_objects [ipx::get_bus_interfaces cfg_status -of_objects [ipx::current_core]]]
ipx::add_port_map vf_tph_requester_enable [ipx::get_bus_interfaces cfg_status -of_objects [ipx::current_core]]
set_property physical_name cfg_vf_tph_requester_enable [ipx::get_port_maps vf_tph_requester_enable -of_objects [ipx::get_bus_interfaces cfg_status -of_objects [ipx::current_core]]]
ipx::add_port_map cq_np_req_count [ipx::get_bus_interfaces cfg_status -of_objects [ipx::current_core]]
set_property physical_name pcie_cq_np_req_count [ipx::get_port_maps cq_np_req_count -of_objects [ipx::get_bus_interfaces cfg_status -of_objects [ipx::current_core]]]
ipx::add_port_map rq_seq_num_vld [ipx::get_bus_interfaces cfg_status -of_objects [ipx::current_core]]
set_property physical_name pcie_rq_seq_num_vld [ipx::get_port_maps rq_seq_num_vld -of_objects [ipx::get_bus_interfaces cfg_status -of_objects [ipx::current_core]]]
ipx::add_port_map vf_tph_st_mode [ipx::get_bus_interfaces cfg_status -of_objects [ipx::current_core]]
set_property physical_name cfg_vf_tph_st_mode [ipx::get_port_maps vf_tph_st_mode -of_objects [ipx::get_bus_interfaces cfg_status -of_objects [ipx::current_core]]]
ipx::add_port_map max_read_req [ipx::get_bus_interfaces cfg_status -of_objects [ipx::current_core]]
set_property physical_name cfg_max_read_req [ipx::get_port_maps max_read_req -of_objects [ipx::get_bus_interfaces cfg_status -of_objects [ipx::current_core]]]
ipx::add_port_map vf_power_state [ipx::get_bus_interfaces cfg_status -of_objects [ipx::current_core]]
set_property physical_name cfg_vf_power_state [ipx::get_port_maps vf_power_state -of_objects [ipx::get_bus_interfaces cfg_status -of_objects [ipx::current_core]]]
ipx::add_port_map function_power_state [ipx::get_bus_interfaces cfg_status -of_objects [ipx::current_core]]
set_property physical_name cfg_function_power_state [ipx::get_port_maps function_power_state -of_objects [ipx::get_bus_interfaces cfg_status -of_objects [ipx::current_core]]]
ipx::add_port_map negotiated_width [ipx::get_bus_interfaces cfg_status -of_objects [ipx::current_core]]
set_property physical_name cfg_negotiated_width [ipx::get_port_maps negotiated_width -of_objects [ipx::get_bus_interfaces cfg_status -of_objects [ipx::current_core]]]
ipx::add_port_map current_speed [ipx::get_bus_interfaces cfg_status -of_objects [ipx::current_core]]
set_property physical_name cfg_current_speed [ipx::get_port_maps current_speed -of_objects [ipx::get_bus_interfaces cfg_status -of_objects [ipx::current_core]]]
ipx::add_port_map vf_status [ipx::get_bus_interfaces cfg_status -of_objects [ipx::current_core]]
set_property physical_name cfg_vf_status [ipx::get_port_maps vf_status -of_objects [ipx::get_bus_interfaces cfg_status -of_objects [ipx::current_core]]]
ipx::add_port_map rq_tag_vld [ipx::get_bus_interfaces cfg_status -of_objects [ipx::current_core]]
set_property physical_name pcie_rq_tag_vld [ipx::get_port_maps rq_tag_vld -of_objects [ipx::get_bus_interfaces cfg_status -of_objects [ipx::current_core]]]
ipx::add_port_map err_cor_out [ipx::get_bus_interfaces cfg_status -of_objects [ipx::current_core]]
set_property physical_name cfg_err_cor_out [ipx::get_port_maps err_cor_out -of_objects [ipx::get_bus_interfaces cfg_status -of_objects [ipx::current_core]]]
ipx::add_port_map obff_enable [ipx::get_bus_interfaces cfg_status -of_objects [ipx::current_core]]
set_property physical_name cfg_obff_enable [ipx::get_port_maps obff_enable -of_objects [ipx::get_bus_interfaces cfg_status -of_objects [ipx::current_core]]]
ipx::add_port_map dpa_substate_change [ipx::get_bus_interfaces cfg_status -of_objects [ipx::current_core]]
set_property physical_name cfg_dpa_substate_change [ipx::get_port_maps dpa_substate_change -of_objects [ipx::get_bus_interfaces cfg_status -of_objects [ipx::current_core]]]
ipx::add_port_map link_power_state [ipx::get_bus_interfaces cfg_status -of_objects [ipx::current_core]]
set_property physical_name cfg_link_power_state [ipx::get_port_maps link_power_state -of_objects [ipx::get_bus_interfaces cfg_status -of_objects [ipx::current_core]]]
ipx::add_port_map ltr_enable [ipx::get_bus_interfaces cfg_status -of_objects [ipx::current_core]]
set_property physical_name cfg_ltr_enable [ipx::get_port_maps ltr_enable -of_objects [ipx::get_bus_interfaces cfg_status -of_objects [ipx::current_core]]]
ipx::add_port_map pl_status_change [ipx::get_bus_interfaces cfg_status -of_objects [ipx::current_core]]
set_property physical_name cfg_pl_status_change [ipx::get_port_maps pl_status_change -of_objects [ipx::get_bus_interfaces cfg_status -of_objects [ipx::current_core]]]
ipx::add_port_map phy_link_down [ipx::get_bus_interfaces cfg_status -of_objects [ipx::current_core]]
set_property physical_name cfg_phy_link_down [ipx::get_port_maps phy_link_down -of_objects [ipx::get_bus_interfaces cfg_status -of_objects [ipx::current_core]]]
ipx::add_port_map rq_tag [ipx::get_bus_interfaces cfg_status -of_objects [ipx::current_core]]
set_property physical_name pcie_rq_tag [ipx::get_port_maps rq_tag -of_objects [ipx::get_bus_interfaces cfg_status -of_objects [ipx::current_core]]]
ipx::add_port_map rcb_status [ipx::get_bus_interfaces cfg_status -of_objects [ipx::current_core]]
set_property physical_name cfg_rcb_status [ipx::get_port_maps rcb_status -of_objects [ipx::get_bus_interfaces cfg_status -of_objects [ipx::current_core]]]

# per_func_status
ipx::add_bus_interface per_func_status [ipx::current_core]
set_property abstraction_type_vlnv xilinx.com:interface:pcie3_per_func_status_rtl:1.0 [ipx::get_bus_interfaces per_func_status -of_objects [ipx::current_core]]
set_property bus_type_vlnv xilinx.com:interface:pcie3_per_func_status:1.0 [ipx::get_bus_interfaces per_func_status -of_objects [ipx::current_core]]
set_property interface_mode slave [ipx::get_bus_interfaces per_func_status -of_objects [ipx::current_core]]

ipx::add_port_map STATUS_CONTROL [ipx::get_bus_interfaces per_func_status -of_objects [ipx::current_core]]
set_property physical_name cfg_per_func_status_control [ipx::get_port_maps STATUS_CONTROL -of_objects [ipx::get_bus_interfaces per_func_status -of_objects [ipx::current_core]]]
ipx::add_port_map STATUS_DATA [ipx::get_bus_interfaces per_func_status -of_objects [ipx::current_core]]
set_property physical_name cfg_per_func_status_data [ipx::get_port_maps STATUS_DATA -of_objects [ipx::get_bus_interfaces per_func_status -of_objects [ipx::current_core]]]

update_compile_order -fileset sources_1


##############################################################
###### Fix parameters #####
ipx::add_bus_parameter FREQ_HZ [ipx::get_bus_interfaces m_axis_cq -of_objects [ipx::current_core]]
set_property description {Clock frequency (Hertz)} [ipx::get_bus_parameters FREQ_HZ -of_objects [ipx::get_bus_interfaces m_axis_cq -of_objects [ipx::current_core]]]
set_property value 250000000 [ipx::get_bus_parameters FREQ_HZ -of_objects [ipx::get_bus_interfaces m_axis_cq -of_objects [ipx::current_core]]]

ipx::add_bus_parameter FREQ_HZ [ipx::get_bus_interfaces m_axis_rc -of_objects [ipx::current_core]]
set_property description {Clock frequency (Hertz)} [ipx::get_bus_parameters FREQ_HZ -of_objects [ipx::get_bus_interfaces m_axis_rc -of_objects [ipx::current_core]]]
set_property value 250000000 [ipx::get_bus_parameters FREQ_HZ -of_objects [ipx::get_bus_interfaces m_axis_rc -of_objects [ipx::current_core]]]

ipx::add_bus_parameter FREQ_HZ [ipx::get_bus_interfaces s_axis_cc -of_objects [ipx::current_core]]
set_property description {Clock frequency (Hertz)} [ipx::get_bus_parameters FREQ_HZ -of_objects [ipx::get_bus_interfaces s_axis_cc -of_objects [ipx::current_core]]]
set_property value 250000000 [ipx::get_bus_parameters FREQ_HZ -of_objects [ipx::get_bus_interfaces s_axis_cc -of_objects [ipx::current_core]]]

ipx::add_bus_parameter FREQ_HZ [ipx::get_bus_interfaces s_axis_rq -of_objects [ipx::current_core]]
set_property description {Clock frequency (Hertz)} [ipx::get_bus_parameters FREQ_HZ -of_objects [ipx::get_bus_interfaces s_axis_rq -of_objects [ipx::current_core]]]
set_property value 250000000 [ipx::get_bus_parameters FREQ_HZ -of_objects [ipx::get_bus_interfaces s_axis_rq -of_objects [ipx::current_core]]]

ipx::add_bus_parameter FREQ_HZ [ipx::get_bus_interfaces c2s -of_objects [ipx::current_core]]
set_property description {Clock frequency (Hertz)} [ipx::get_bus_parameters FREQ_HZ -of_objects [ipx::get_bus_interfaces c2s -of_objects [ipx::current_core]]]
set_property value 250000000 [ipx::get_bus_parameters FREQ_HZ -of_objects [ipx::get_bus_interfaces c2s -of_objects [ipx::current_core]]]

ipx::add_bus_parameter FREQ_HZ [ipx::get_bus_interfaces s2c -of_objects [ipx::current_core]]
set_property description {Clock frequency (Hertz)} [ipx::get_bus_parameters FREQ_HZ -of_objects [ipx::get_bus_interfaces s2c -of_objects [ipx::current_core]]]
set_property value 250000000 [ipx::get_bus_parameters FREQ_HZ -of_objects [ipx::get_bus_interfaces s2c -of_objects [ipx::current_core]]]

# clk & rst
ipx::remove_bus_interface cfg_power_state_change_signal_interrupt [ipx::current_core]
ipx::remove_bus_interface user_signal_reset [ipx::current_core]
ipx::remove_bus_interface user_signal_clock [ipx::current_core]
ipx::remove_bus_interface m_axi_lite_signal_clock [ipx::current_core]
ipx::remove_bus_interface m_axi_lite_signal_reset [ipx::current_core]

# user_clk
ipx::add_bus_interface user_clk [ipx::current_core]
set_property abstraction_type_vlnv xilinx.com:signal:clock_rtl:1.0 [ipx::get_bus_interfaces user_clk -of_objects [ipx::current_core]]
set_property bus_type_vlnv xilinx.com:signal:clock:1.0 [ipx::get_bus_interfaces user_clk -of_objects [ipx::current_core]]
ipx::add_port_map CLK [ipx::get_bus_interfaces user_clk -of_objects [ipx::current_core]]
set_property physical_name user_clk [ipx::get_port_maps CLK -of_objects [ipx::get_bus_interfaces user_clk -of_objects [ipx::current_core]]]
ipx::add_bus_parameter ASSOCIATED_BUSIF [ipx::get_bus_interfaces user_clk -of_objects [ipx::current_core]]
ipx::add_bus_parameter ASSOCIATED_RESET [ipx::get_bus_interfaces user_clk -of_objects [ipx::current_core]]
set_property value c2s:s2c:m_axis_cq:m_axis_rc:s_axis_cc:s_axis_rq:s_axi_lite [ipx::get_bus_parameters ASSOCIATED_BUSIF -of_objects [ipx::get_bus_interfaces user_clk -of_objects [ipx::current_core]]]
set_property value user_reset [ipx::get_bus_parameters ASSOCIATED_RESET -of_objects [ipx::get_bus_interfaces user_clk -of_objects [ipx::current_core]]]

# user_rst
ipx::add_bus_interface user_rst [ipx::current_core]
set_property abstraction_type_vlnv xilinx.com:signal:reset_rtl:1.0 [ipx::get_bus_interfaces user_rst -of_objects [ipx::current_core]]
set_property bus_type_vlnv xilinx.com:signal:reset:1.0 [ipx::get_bus_interfaces user_rst -of_objects [ipx::current_core]]
ipx::add_port_map RST [ipx::get_bus_interfaces user_rst -of_objects [ipx::current_core]]
set_property physical_name user_reset [ipx::get_port_maps RST -of_objects [ipx::get_bus_interfaces user_rst -of_objects [ipx::current_core]]]
ipx::add_bus_parameter POLARITY [ipx::get_bus_interfaces user_rst -of_objects [ipx::current_core]]
set_property value ACTIVE_HIGH [ipx::get_bus_parameters POLARITY -of_objects [ipx::get_bus_interfaces user_rst -of_objects [ipx::current_core]]]

# m_axi_lite_aclk
ipx::add_bus_interface m_axi_lite_aclk [ipx::current_core]
set_property abstraction_type_vlnv xilinx.com:signal:clock_rtl:1.0 [ipx::get_bus_interfaces m_axi_lite_aclk -of_objects [ipx::current_core]]
set_property bus_type_vlnv xilinx.com:signal:clock:1.0 [ipx::get_bus_interfaces m_axi_lite_aclk -of_objects [ipx::current_core]]
ipx::add_port_map CLK [ipx::get_bus_interfaces m_axi_lite_aclk -of_objects [ipx::current_core]]
set_property physical_name m_axi_lite_aclk [ipx::get_port_maps CLK -of_objects [ipx::get_bus_interfaces m_axi_lite_aclk -of_objects [ipx::current_core]]]
ipx::add_bus_parameter ASSOCIATED_BUSIF [ipx::get_bus_interfaces m_axi_lite_aclk -of_objects [ipx::current_core]]
ipx::add_bus_parameter ASSOCIATED_RESET [ipx::get_bus_interfaces m_axi_lite_aclk -of_objects [ipx::current_core]]
set_property value m_axi_lite [ipx::get_bus_parameters ASSOCIATED_BUSIF -of_objects [ipx::get_bus_interfaces m_axi_lite_aclk -of_objects [ipx::current_core]]]
set_property value m_axi_lite_aresetn [ipx::get_bus_parameters ASSOCIATED_RESET -of_objects [ipx::get_bus_interfaces m_axi_lite_aclk -of_objects [ipx::current_core]]]
set_property value m_axi_lite_aclk [ipx::get_bus_parameters ASSOCIATED_BUSIF -of_objects [ipx::get_bus_interfaces m_axi_lite_aclk -of_objects [ipx::current_core]]]

# m_axi_lite_aresetn
ipx::add_bus_interface m_axi_lite_aresetn [ipx::current_core]
set_property abstraction_type_vlnv xilinx.com:signal:reset_rtl:1.0 [ipx::get_bus_interfaces m_axi_lite_aresetn -of_objects [ipx::current_core]]
set_property bus_type_vlnv xilinx.com:signal:reset:1.0 [ipx::get_bus_interfaces m_axi_lite_aresetn -of_objects [ipx::current_core]]
ipx::add_port_map RST [ipx::get_bus_interfaces m_axi_lite_aresetn -of_objects [ipx::current_core]]
set_property physical_name m_axi_lite_aresetn [ipx::get_port_maps RST -of_objects [ipx::get_bus_interfaces m_axi_lite_aresetn -of_objects [ipx::current_core]]]
ipx::add_bus_parameter POLARITY [ipx::get_bus_interfaces m_axi_lite_aresetn -of_objects [ipx::current_core]]
set_property value ACTIVE_LOW [ipx::get_bus_parameters POLARITY -of_objects [ipx::get_bus_interfaces m_axi_lite_aresetn -of_objects [ipx::current_core]]]


# Write IP Core xml to File system
ipx::check_integrity [ipx::current_core]
write_peripheral [ipx::current_core]

# Generate GUI Configuration Files
ipx::create_xgui_files [ipx::current_core]
ipx::update_checksums [ipx::current_core]
ipx::save_core [ipx::current_core]

update_ip_catalog -rebuild -repo_path $repo_dir

close_project
exit
