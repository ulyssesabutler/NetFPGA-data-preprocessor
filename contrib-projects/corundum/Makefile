#
# Copyright (c) 2019 Marcin Wójcik
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

SHELL := /bin/bash

prepare_ethernet:
	source script/prepare_ethernet.sh

ethernet:
	 make -C verilog-ethernet/example/NetFPGA_SUME/fpga/

prepare_pcie:
	source script/prepare_pcie.sh

pcie:
	make -C verilog-pcie/example/NetFPGA_SUME/fpga_axi/

prepare_corundum: 
	source script/prepare_corundum.sh

.PHONY: corundum clean
corundum:
	make -C corundum/fpga/mqnic/NetFPGA_SUME/fpga/

clean:
	rm -rf verilog-ethernet
	rm -rf verilog-pcie
	rm -rf corundum
