# NetFPGA Data Preprocessor

Currently, this preprocessor just performs a dummy operation that replaces the first two bytes of the packet body with `0xAA`.

## Building the reference switch on Cyclops

Once this package has been downloaded, and Vivado has been installed (on Cyclops, we're using the Vivado installation in `/home/uab/Xilinx/Vivado/2020.1`), build the reference switch using the instrutions found on the NetFPGA SUME Wiki, [here](https://github.com/NetFPGA/NetFPGA-SUME-public/wiki/NetFPGA-SUME-Reference-Learning-Switch).

## Testing the implementation on Ravnica

Copy the resulting `reference_switch.bit` file onto Ravnica (where the FPGA is located) and flash it to the FPGA.

Now, we can test it using the traffic generator, found in [this repository](https://github.com/ulyssesabutler/traffic-generator).

This program will create raw IP packets. We want to send these raw IP packets to a dummy IP address.
To send these IP packets, our system's networking stack will have to construct an Ethernet frame using the destination MAC address corresponding to out destination IP address in our system's APR table.
That said, since our destination is a dummy IP address, a real entry won't exist in the APR table.
We can add an entry to the APR entry using the following command
```
sudo arp -s 172.24.71.237 00:18:3E:02:0E:74 -i enp7s0f0
```
In this example, `172.24.71.237` is the destination IP address, `00:18:3E:02:0E:74` is the desired destination MAC address, and `enp7s0f0` is the interface we will be sending the packets from.

Next, to detect the packets that are returned by the switch, we can use `tcpdump`.
```
sudo tcpdump -vvvexxXX -i enp7s0f1
```
where `enp7s0f1` is the interface we plan on retrieving packets on.

Finally, we can start sending the packet using the binary produced by making the traffic generator package
```
sudo ./generator -t enp6s0f0 -r enp6s0f0 -r enp6s0f1 -s 172.24.71.241 -d 172.24.71.237 -p 1
```
Here, we specify the transmitting interface using `-t enp6s0f0`.
We can specify any number of receiving interfaces using `-r enp6s0f0 -r enp6s0f1` (though, we are using `tcpdump` instead of this program).
We specify the sourrce and destination IP addresses using `-s 172.24.71.241 -d 172.24.71.237`.
Finally, we specify the TCP port with `-p 1`.

The resulting TCP dump should look like
```
17:41:04.975265 3c:fd:fe:bd:01:a4 (oui Unknown) > 00:18:3e:02:0e:74 (oui Unknown), ethertype IPv4 (0x0800), length 60: (tos 0x0, ttl 255, id 29984, offset 0, flags [none], proto unknown (255), length 24)
    172-24-71-237.dynapool.nyu.edu > 172-24-71-237.dynapool.nyu.edu:  reserved 4
	0x0000:  0018 3e02 0e74 3cfd febd 01a4 0800 4500  ..>..t<.......E.
	0x0010:  0018 7520 0000 ffff 5dbb ac18 47ed ac18  ..u.....]...G...
	0x0020:  47ed aaaa 0009 0000 0000 0000 0000 0000  G...............
	0x0030:  0000 0000 0000 0000 0000 0000            ............
17:41:04.975280 3c:fd:fe:bd:01:a4 (oui Unknown) > 00:18:3e:02:0e:74 (oui Unknown), ethertype IPv4 (0x0800), length 60: (tos 0x0, ttl 255, id 29985, offset 0, flags [none], proto unknown (255), length 24)
    172-24-71-237.dynapool.nyu.edu > 172-24-71-237.dynapool.nyu.edu:  reserved 4
	0x0000:  0018 3e02 0e74 3cfd febd 01a4 0800 4500  ..>..t<.......E.
	0x0010:  0018 7521 0000 ffff 5dba ac18 47ed ac18  ..u!....]...G...
	0x0020:  47ed aaaa 0008 0000 0000 0000 0000 0000  G...............
	0x0030:  0000 0000 0000 0000 0000 0000            ............
17:41:04.975291 3c:fd:fe:bd:01:a4 (oui Unknown) > 00:18:3e:02:0e:74 (oui Unknown), ethertype IPv4 (0x0800), length 60: (tos 0x0, ttl 255, id 29986, offset 0, flags [none], proto unknown (255), length 24)
    172-24-71-237.dynapool.nyu.edu > 172-24-71-237.dynapool.nyu.edu:  reserved 4
	0x0000:  0018 3e02 0e74 3cfd febd 01a4 0800 4500  ..>..t<.......E.
	0x0010:  0018 7522 0000 ffff 5db9 ac18 47ed ac18  ..u"....]...G...
	0x0020:  47ed aaaa 0007 0000 0000 0000 0000 0000  G...............
	0x0030:  0000 0000 0000 0000 0000 0000            ............
```
Specifically, the IP header is `0018 3e02 0e74 3cfd febd 01a4 0800 4500 0018 7522 0000 ffff 5db9 ac18 47ed ac18 47ed`, so the packet body is just `aaaa 000N`. (where `N` is the packet number from the traffic generator). We're specifically looking to make sure the firt two types were replaced with `aaaa`.
