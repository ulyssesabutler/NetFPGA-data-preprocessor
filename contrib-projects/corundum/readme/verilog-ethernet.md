# Verilog Ethernet NetFPGA SUME Example Design

## Introduction

This example design targets the NetFPGA SUME board.

The design by default listens to UDP port 1234 at IP address 192.168.1.128 and
will echo back any packets received.  The design will also respond correctly
to ARP requests.  

FPGA: xc7vx690t-3-ffg1761
PHY: 10G Ethernet PCS/PMA Xilinx IP core

## How to build

Run make to build.  Ensure that the Xilinx Vivado toolchain components are
in PATH.  

## How to test

Run make program to program the NetFPGA SUME board with Vivado.  Then run
netcat -u 192.168.1.128 1234 to open a UDP connection to port 1234.  Any text
entered into netcat will be echoed back after pressing enter.  
