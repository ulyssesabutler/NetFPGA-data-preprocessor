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

```
iperf3 -c 10.10.10.2
Connecting to host 10.10.10.2, port 5201
[  5] local 10.10.10.1 port 48490 connected to 10.10.10.2 port 5201
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  5]   0.00-1.00   sec  1.09 GBytes  9.38 Gbits/sec    0    800 KBytes       
[  5]   1.00-2.00   sec  1.09 GBytes  9.41 Gbits/sec    0    894 KBytes       
[  5]   2.00-3.00   sec  1.09 GBytes  9.37 Gbits/sec    0    991 KBytes       
[  5]   3.00-4.00   sec  1.09 GBytes  9.41 Gbits/sec    0    991 KBytes       
[  5]   4.00-5.00   sec  1.09 GBytes  9.41 Gbits/sec    0    991 KBytes       
[  5]   5.00-6.00   sec  1.09 GBytes  9.40 Gbits/sec    0   1.02 MBytes       
[  5]   6.00-7.00   sec  1.10 GBytes  9.41 Gbits/sec    0   1.02 MBytes       
[  5]   7.00-8.00   sec  1.09 GBytes  9.41 Gbits/sec    0   1.02 MBytes       
[  5]   8.00-9.00   sec  1.09 GBytes  9.40 Gbits/sec    0   1.08 MBytes       
[  5]   9.00-10.00  sec  1.09 GBytes  9.40 Gbits/sec    0   1.08 MBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-10.00  sec  10.9 GBytes  9.40 Gbits/sec    0             sender
[  5]   0.00-10.00  sec  10.9 GBytes  9.40 Gbits/sec                  receiver

iperf Done.

iperf3 -c 10.10.10.2 -R
Connecting to host 10.10.10.2, port 5201
Reverse mode, remote host 10.10.10.2 is sending
[  5] local 10.10.10.1 port 48494 connected to 10.10.10.2 port 5201
[ ID] Interval           Transfer     Bitrate
[  5]   0.00-1.00   sec  1.08 GBytes  9.25 Gbits/sec                  
[  5]   1.00-2.00   sec  1.09 GBytes  9.33 Gbits/sec                  
[  5]   2.00-3.00   sec  1.09 GBytes  9.33 Gbits/sec                  
[  5]   3.00-4.00   sec  1.09 GBytes  9.32 Gbits/sec                  
[  5]   4.00-5.00   sec  1.09 GBytes  9.33 Gbits/sec                  
[  5]   5.00-6.00   sec  1.09 GBytes  9.33 Gbits/sec                  
[  5]   6.00-7.00   sec  1.09 GBytes  9.33 Gbits/sec                  
[  5]   7.00-8.00   sec  1.09 GBytes  9.33 Gbits/sec                  
[  5]   8.00-9.00   sec  1.09 GBytes  9.33 Gbits/sec                  
[  5]   9.00-10.00  sec  1.09 GBytes  9.33 Gbits/sec                  
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-10.00  sec  10.9 GBytes  9.32 Gbits/sec    1             sender
[  5]   0.00-10.00  sec  10.9 GBytes  9.32 Gbits/sec                  receiver

iperf Done.
```
