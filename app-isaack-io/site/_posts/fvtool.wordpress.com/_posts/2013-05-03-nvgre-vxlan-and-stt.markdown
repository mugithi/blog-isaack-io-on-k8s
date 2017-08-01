---
author: mugithi
comments: true
date: 2013-05-03 02:54:42+00:00
layout: post
#link: https://fvtool.wordpress.com/2013/05/03/nvgre-vxlan-and-stt/
slug: nvgre-vxlan-and-stt
title: NVGRE VXLAN and STT
wordpress_id: 244
categories:
- OpenVSwitch
tags:
- Network Virtualization
- nvgre
- stt
- vxlan
---

Overlay networks were designed to deal with the "network problem" that was brought about by the use of cloud. The "network problem" is well documented [HERE](http://tools.ietf.org/html/draft-narten-nvo3-overlay-problem-statement-01). The problem summary is




	
  1. Clouds infrustructure is to be to be consumed by a large number of number of tenants 
	
  2. Cloud tenants require separation of networks. This separation sometimes is required at the application level and the number of networks can easily go > 4094
	
  3. The number 4094 because previously, the only way to enforce separation of networks had been to use to use virtualized LANS (vLANs) who's limit is currently at 4094



So, network overlays a the way to solve this problem by allowing you to go past the 4094 barrier that is the current VLAN limit. This works by encapsulating L2 networks in layer 3 tunnels. 

There are three popular network overlay methods that are in use today.


	
  1. [nVGRE](http://tools.ietf.org/html/draft-sridharan-virtualization-nvgre-00) Largely backed by Microsoft + HP
	
  2. [VXLAN](http://tools.ietf.org/html/draft-mahalingam-dutt-dcops-vxlan-00) Largely backed by VMware + Cisco + Broadcom. This is currently been implemented in the VMware VCloud product
	
  3. [STT ](http://tools.ietf.org/html/draft-davie-stt-01) Nicira's proposal and now VMware's because of the acquisition. I am going to do some digging and see where this has been implemented. I want to say NVP from Nicira and now NSX from VMware + the linux kernel OpenVSwitch but I need to confirm.



So the problem with overlay networks is that they encapsulate L2 over L3. This leads to larger than expected packet sizes. When you get larger than expected packet sizes, fragmentation has to take place in order for the packet to be delivered. Otherwise, the packets get dropped.

Once the fragmented packets arrive at the destination NIC, they need to be re-assembled. The reassembly process is CPU resource intensive. NIC manufacturers fixed this problem a while back by bringing to market NIC cards that supported TSO (TCP Segmentation Offload) for packets that were being transmitted using TCP protocol. The cards offload the reassembly process from the CPU down to the NIC ASIC and everything is fast again. 

Unfortunately the network overlays do not use TCP and so do cannot leverage the NICS ability to TSO. Well, at least that its true for VXLAN and nVGRE. 

STT works by encapsulating the payload with a STT FRAME header, and then encapsulating that with a "TCP like" header into a IP datagram. When they say "TCP like" this is what it means, the segment header is syntactically identical to the TCP header but also uses the ack and the sequence numbers. 


    
    <code>
                          +-----------+    +----------+     +----------+
                          | IP Header |    |IP Header |     |IP header |
       +-----------+      +-----------+    +----------+     +----------+
       |STT Frame  |      |TCP-like   |    |TCP-like  |     |TCP-like  |
       | Header    |      | header    |    | header   |     | header   |
       +-----------+      +-----------+    +----------+     +----------+
       |           | ---> | STT Frame |    |Next part | ... |Last part |
       |Payload    |      |  Header   |    |of Payload|     |of Payload|
       .           .      +-----------+    |          |     |          |
       .           .      |           |    |          |     |          |
       .           .      |  Start of |    |          |     |          |
       +-----------+      |  Payload  |    |          |     +----------+
                          +-----------+    +----------+
    </code>



Along with using less CPU cycles, there are other STT benefits such as not requiring IP multicast support which is required for VXLAN and nVGRE.

So enough of that..

I am beginning to understand where VMware is going with their Network Virtualization strategy, they are divorcing themselves from SDN (strategy taken from Davie of Nicira) and putting it all under the umbrella of Network Virtualization. I think this is a smart move. Network overlays is just one of the methods to implement Network Virtualization along with other Openflow which is what my next blog entry is going to be about.
