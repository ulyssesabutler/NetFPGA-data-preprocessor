#
# Copyright (c) 2014 Hwanju Kim
# All rights reserved.
#
# This software was developed by
# Stanford University and the University of Cambridge Computer Laboratory
# under National Science Foundation under Grant No. CNS-0855268,
# the University of Cambridge Computer Laboratory under EPSRC INTERNET Project EP/H040536/1 and
# by the University of Cambridge Computer Laboratory under DARPA/AFRL contract FA8750-11-C-0249 ("MRC2"),
# as part of the DARPA MRC research programme.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#

KERNEL_VER	?= $(shell uname -r)
KERNEL_DIR	?= /lib/modules/$(KERNEL_VER)/build

obj-m += sume_uam.o
sume_uam-objs += sume_uam_main.o
sume_uam-objs += sume_uam_ethtool.o
sume_uam-objs += sume_uam_debug.o

ifeq ($(DEBUG),y)
ccflags-y += -g -DDEBUG
endif

ifeq ($(OSNT),y)
CONFIG_TIMESTAMP := y
ccflags-y += -DCONFIG_OSNT
endif

ccflags-$(CONFIG_PROFILE) += -DCONFIG_PROFILE
ccflags-$(CONFIG_TIMESTAMP) += -DCONFIG_TIMESTAMP
ifeq ($(CONFIG_NR_PORTS),)
	CONFIG_NR_PORTS := 4
endif
ccflags-y += -DCONFIG_NR_PORTS=$(CONFIG_NR_PORTS)

all: modules

.PHONY: modules
modules:
	make -C $(KERNEL_DIR) M=$(PWD) modules

.PHONY: lib
lib:
	make -C lib all

.PHONY: modules_install
modules_install: modules
	install -o root -g root -m 0755 -d $(INSTALL_DIR)
	install -o root -g root -m 0755 sume_uam.ko $(INSTALL_DIR)
	depmod -a $(KERNEL_VER)

.PHONY: lib_install
lib_install: lib
	make -C lib install

.PHONY: install
install: modules_install lib_install

.PHONY: clean
clean:
	make -C $(KERNEL_DIR) M=$(PWD) clean
