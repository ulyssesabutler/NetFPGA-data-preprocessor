#!/bin/bash
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


PROJECT=verilog-pcie
REPO=https://github.com/alexforencich/${PROJECT}.git
#latest valid commit
COMMIT=4fcea4e8
SUME_HOME=${PROJECT}/example/NetFPGA_SUME/fpga_axi/
EXANIC_HOME=${PROJECT}/example/ExaNIC_X10/fpga_axi/

git clone ${REPO}
git -C $PWD/${PROJECT} checkout ${COMMIT}
mkdir -p ${SUME_HOME}/{ip,rtl}

cp -r ${EXANIC_HOME}/common ${SUME_HOME}
cp -r ${EXANIC_HOME}/fpga/ ${SUME_HOME}
cp -r ${EXANIC_HOME}/lib/ ${SUME_HOME}
cp -r ${EXANIC_HOME}/driver/ ${SUME_HOME}
cp ${EXANIC_HOME}/Makefile ${SUME_HOME}
cp ${EXANIC_HOME}/fpga/Makefile ${SUME_HOME}/fpga/
cp ${EXANIC_HOME}/rtl/fpga_core.v ${SUME_HOME}/rtl/
cp ${EXANIC_HOME}/rtl/axi_ram.v ${SUME_HOME}/rtl/
cp ${EXANIC_HOME}/rtl/axis_register.v ${SUME_HOME}/rtl/

cp ip/pcie3_7x_0.xci ${SUME_HOME}/ip/
cp rtl/verilog-pcie.v ${SUME_HOME}/rtl/fpga.v
cp rtl/pcie3_7x.v ${SUME_HOME}/rtl/
cp xdc/verilog-pcie.xdc ${SUME_HOME}/fpga.xdc
cp readme/verilog-pcie.md ${SUME_HOME}/README.md

# patch makefile
patch -p2 -d verilog-pcie < patch/Makefile-pcie.patch
# patch driver 
patch -p2 -d verilog-pcie < patch/example_driver-verilog-pcie.patch
