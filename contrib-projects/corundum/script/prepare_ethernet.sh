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


PROJECT=verilog-ethernet
REPO=https://github.com/alexforencich/${PROJECT}.git
#latest valid commit
COMMIT=b34f294
SUME_HOME=${PROJECT}/example/NetFPGA_SUME/fpga/
EXANIC_HOME=${PROJECT}/example/ExaNIC_X10/fpga/

git clone ${REPO}
git -C $PWD/${PROJECT} checkout ${COMMIT}
mkdir -p ${SUME_HOME}/{ip,rtl}

cp -r ${EXANIC_HOME}/common ${SUME_HOME}
cp -r ${EXANIC_HOME}/fpga/ ${SUME_HOME}
cp -r ${EXANIC_HOME}/lib/ ${SUME_HOME}
cp ${EXANIC_HOME}/Makefile ${SUME_HOME}
cp ${EXANIC_HOME}/fpga/Makefile ${SUME_HOME}/fpga/
cp ${EXANIC_HOME}/rtl/fpga_core.v ${SUME_HOME}/rtl/

cp ip/ten_gig_eth_pcs_pma_shared.xci ${SUME_HOME}/ip/
cp ip/ten_gig_eth_pcs_pma.xci ${SUME_HOME}/ip/
cp rtl/pcs_pma_10g_shared.v ${SUME_HOME}/rtl/
cp rtl/pcs_pma_10g.v ${SUME_HOME}/rtl/
cp rtl/verilog-ethernet.v ${SUME_HOME}/rtl/fpga.v
cp xdc/verilog-ethernet.xdc ${SUME_HOME}/fpga.xdc
cp readme/verilog-ethernet.md ${SUME_HOME}/README.md

# patch makefile
patch -p2 -d verilog-ethernet < patch/Makefile-ethernet.patch
