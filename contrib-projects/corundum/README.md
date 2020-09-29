# Corundum for NetFPGA SUME

## Introduction

There are 3 projects in the folder: corundum, verilog-pcie, and verilog-ethernet.
Corundum is a 2-port NIC, verilog-pcie is a small project to show how to instance
pcie endpoint and communicate with it, whereas ethernet is a small UDP server.
Those are the ports of original projects to NetFPGA SUME.

## How to build

Ensure that the Xilinx Vivado toolchain components are in PATH.
`make prepare_corundum` will prepare the project, by fetching the
source codes and apply patches. `make corundum` will sythensis the project.
Similarly `make prepare_pcie && make pcie` and `make prepare_ethernet && make
ethernet` prepare and build the pice and ethernet projects.

Run `make` to build the driver located in `contrib-projects/corundum/corundum/modules/mqnic`.

## How to test

Load the driver with `insmod mqnic.ko` (for corundum and pcie projects only).
Check `dmesg` for output from driver initialisation and send traffic via `eth0`
and `eth1` interfaces (corundum project only).
