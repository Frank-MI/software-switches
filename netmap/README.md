# netmap experiments
* Installation instructions are detailed in https://github.com/luigirizzo/netmap. 
* Bind concerning physical ports to netmap's ixgbe device driver.
* Enable promiscuous mode for each physical port.

## p2p test
### Steps:
* Start netmap and configure rules cross-connect rules between two physical ports using VALE switch:
    * sudo vale-ctl -b vale0:if0
    * sudo vale-ctl -b vale0:if1
    Current configuration designates the two ports with PCI address 0b:00.0 and 0b:00.1, modify it to your respective PCI addresses for reproduction.
* Instantiate MoonGen to TX/RX the performance for throughput (unidirectional/bidirectional) and latency:
    * Go to the MoonGen repo directory
    * For unidirectional test: sudo ./unidirectional-test.sh  -r [packet rate (Mpps)] -s [packet size (Bytes)]
    * For bidirectional test: sudo ./bidirectional-test.sh  -r [packet rate (Mpps)] -s [packet size (Bytes)]
    * For latency test: sudo ./latency-test.sh -r [packet rate (Mpps)] -s [packet size (Bytes)]
    
## p2v test
### Steps:
* Start netmap, bind a physical port and a ptnet port to it, configure forwarding rules between them, 
and instantiate virtual machine using QEMU/KVM and attach one virtual interface: ./p2v.sh
* For unidirectional test:
    * Inside the VM, start an pkt-gen instance to receive packets from the host
      * pkt-gen -i vif0 -f rx # vif0 is the name assigned to the ptnet virtual interface, it may vary depending on systems.
    * On the host side, go to MoonGen repo directory and start its unidirectional test script on NUMA node 1: sudo ./unidirectional-test.sh  -r [packet rate (Mpps)] -s [packet size (Bytes)]
* For bidirectional test:
    * Inside the VM, create a VALE interface: vale-ctl -n v0
    * attach both vif0 and v0:
      * vale-ctl -a vale1:vif0 # vif0 is the name assigned to the ptnet virtual interface, it may vary depending on systems.
      * vale-ctl -a vale1:v0
    * Then instantiate a pair of pkt-gen TX/RX thread: 
      * pkt-gen -i vale1:v0 -f tx
      * pkt-gen -i vale1:v0 -f rx
    * On the host side, run MoonGen bidirectional test scripts on NUMA node 1: sudo ./bidirectional-test.sh  -r [packet rate (Mpps)] -s [packet size (Bytes)]

## v2v test
### Steps:
* Start netmap and configure rules cross-connect rules between two virtual ports using VALE switch, and start two QEMU/KVM 
virtual machines: 
    * ./v2v1.sh    # start VM1 which transmits packets to VM2
    * ./v2v.sh     # start VM2 which receives packet from VM1 and measures the throughput under unidirectional test
* On VM1 (which can also be logged in from the host machine using: ssh root@localhost -p 10020), we start MoonGen using the following commands:
    * For unidirectional test, start a pkt-gen TX thread to inject packets towards the other VM: pkt-gen -i vif0 -f tx
    * For bidirectional test, create a VALE interface: vale-ctl -n v0
    * attach both vif0 and v0:
      * vale-ctl -a vale1:vif0 # vif0 is the name assigned to the ptnet virtual interface, it may vary depending on systems.
      * vale-ctl -a vale1:v0
    * Then instantiate a pair of pkt-gen TX/RX thread: 
      * pkt-gen -i vale1:v0 -f tx
      * pkt-gen -i vale1:v0 -f rx
* On VM2 (which can also be logged in from the host machine using: ssh root@localhost -p 10030):
    * For unidirectional test, start a pkt-gen RX thread to monitor traffic from the first VM: pkt-gen -i vif0 -f rx
    * For bidirectional test, follow exactly the same configuration steps as the first VM.
  
## Loopback
### 1-VNF experiment:
  1. start netmap and configure multiple instances of VALE switch to realize the loopback forwarding workflow:
      * ./loopback.sh
  2. inside the VM, bind the two virtual interfaces to another VALE instance:
      * vale-ctl -a vale0:vif0
      * vale-ctl -a vale0:vif1
      * run MoonGen scripts on the host machine from NUMA node 1:
           * Go to MoonGen directory of our repo.
           * unidirectional test: sudo ./unidirectional-test.sh 
           * bidirectional test: sudo ./bidirectional-test.sh
     
### Multi-VNF experiments:
Depending on the number of VNFs, our experiments use different scripts. We demonstrate only 2-VNF experiment as an example:
* start netmap 2-VNF configuration script: ./loopback-2-vm.sh
* open a new terminal and launch the first VM: ./loopback-2-vm1.sh
* Inside both VMs, use VALE switch to bridge each pair of virtual interfaces just like other test scenarios.
* Launch MoonGen for different measurement:
      * Go to MoonGen directory of our repo.
      * unidirectional test: sudo ./unidirectional-test.sh 
      * bidirectional test: sudo ./bidirectional-test.sh
      * For latency test: sudo ./latency-test.sh -r [packet rate (Mpps)] -s [packet size (Bytes)]

## Detach all the physical/virtual ports from any VALE instance upon finishing, so as to avoid potential race conditions:
* ./detach.sh
