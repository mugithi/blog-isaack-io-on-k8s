---
author: mugithi
comments: true
date: 2013-04-19 08:26:55+00:00
layout: post
#link: https://fvtool.wordpress.com/2013/04/19/install-kvm-on-centos-6-3-configure-networking-b/
slug: install-kvm-on-centos-6-3-configure-networking-b
title: Install KVM on Centos 6.4 - Configure Networking.b
wordpress_id: 211
tags:
- cannot ping bond
- duplicate mac address
- setting up bonded kvm
- vlans with kvm
---

Once i configured networking, I applied static routes to the interfaces but I found not ping both bridge interfaces br100 and br105 from outside the host from the host at the same time. The interface that was able to ping was the one that came up first. I tested this by running a ping test to both br100 and 105 and reboot the blade.

Now here comes the interesting part.

The Linux kernel can be used as routers and as many routers do they can route packets from one network to the other. Reverse path filtering is a mechanism adopted by the Linux kernel, as well as most of the networking devices to check whether a receiving packet source address is routable. When a machine with reverse path filtering enabled recieves a packet, the machine will first check whether the source of the recieved packet is reachable through the interface it came in according to three settings configured in the "/etc/sysctl.conf" file

Here are the options available in sysctl.conf
Option 1. If it is routable through the interface which it came, then the machine will accept the packet
Option 2. If it is not routable through the interface, which it came, then the machine will drop that packet.
Option 3. If the recieved packet's source address is routable through any of the interfaces on the machine, the machine will accept the packet.


In my network, I was using two VLANS, 100 and 105. Interface br100 was connected to 100 and interface br105 was connected to 105. When I tried to ping ip 105, the packets got back to me ok. When I tried to ping 100, because the packets were not routable back through that interface, they got dropped because sysctl.conf cames with the [default](http://www.centos.org/modules/newbb/viewtopic.php?topic_id=40726&forum=58) value for option 1 in CentOS 6.x

I added this entry tp sysctl.conf


    
    <code># Controls source route verification
    net.ipv4.conf.default.rp_filter = 2</code>



And reloaded sysctl


    
    <code>[root@Centos63UCStemplate ~]# sysctl -p
    net.ipv4.ip_forward = 0
    <font color="#FF0000">net.ipv4.conf.default.rp_filter = 2</font>
    net.ipv4.conf.default.accept_source_route = 0
    kernel.sysrq = 0
    kernel.core_uses_pid = 1
    net.ipv4.tcp_syncookies = 1
    net.bridge.bridge-nf-call-ip6tables = 0
    net.bridge.bridge-nf-call-iptables = 0
    net.bridge.bridge-nf-call-arptables = 0
    kernel.msgmnb = 65536
    kernel.msgmax = 65536
    kernel.shmmax = 68719476736
    kernel.shmall = 4294967296
    net.ipv4.conf.all.arp_ignore = 1
    net.ipv4.conf.all.arp_announce = 2</code>



I was then able to successfully ping both interfaces.

At this point I was able to [start installing Virtual Machines](https://fvtool.wordpress.com/2013/04/22/install-kvm-on-centos-6-3-installing-kvm-and-a-centos-virtual-machines/) in the newly built KVM enviroment
