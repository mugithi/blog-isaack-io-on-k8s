---
author: mugithi
comments: true
date: 2013-04-29 05:56:50+00:00
layout: post
#link: https://fvtool.wordpress.com/2013/04/29/install-kvm-on-centos-6-4-configuring-openswitch-with-kvm-and-libvirtd/
slug: install-kvm-on-centos-6-4-configuring-openswitch-with-kvm-and-libvirtd
title: Install KVM on Centos 6.4 - Configuring OpenSwitch with KVM and libvirtd
wordpress_id: 230
tags:
- centos 6.4
- kvm
- openstack
- openvswitch
- ovs-vsctl
- ucs
- virsh
- virt-install
---

So I needed to configure UCS blade B200 blade with OpenVSwitch and KVM as the hypvervisor. I was using one VLAN for Management and VM traffic and a separate VLAN for the NFS mount point as shown below. In my [previous blog entry](https://fvtool.wordpress.com/2013/04/24/install-kvm-on-centos-6-3-installing-open-vswitch/), you can see how to install OpenVswitch

![Hypervisor Visio v 6](http://fvtool.files.wordpress.com/2013/04/hypervisor-visio-v-61.jpg)

I configured  bridge br0 and connected it to the physical port eth0


    
    <code>[root@CentOS6-UCS-OVS ~]# ovs-vsctl add-br br0
    [root@CentOS6-UCS-OVS ~]# ovs-vsctl add-port br0 eth0</code>



To create a management interface for the hypervisor I created a internal port infaace on bridge br0


    
    <code>[root@CentOS6-UCS-OVS ~]# ovs-vsctl add-port br0 mgmt0 tag=100 -- set Interface mgmt0 type=internal
    [root@CentOS6-UCS-OVS ~]# ifconfig mgmt0  172.17.100.71 netmask 255.255.255.0
    [root@CentOS6-UCS-OVS ~]# route add default gw 172.17.100.1 dev mgmt0
    [root@CentOS6-UCS-OVS ~]# ovs-vsctl show
    0ce098af-ac7e-4d6c-a6e6-bac3ea1c99b7
        Bridge "br0"
            Port "br0"
                Interface "br0"
                    type: internal
            Port "eth0"
                Interface "eth0"
            Port "mgmt0"
                tag: 100
                Interface "mgmt0"
                    type: internal
        ovs_version: "1.9.0"
    </code>



At this point, my management interface was supposed to work, but I could not ping out of the interface to my gateway sitting in my network. I had initially thought that my vlans had been misconfigured from the blade. To make sure that this was not the problem. I deleted the bridge br0 and created a eth0.100 clan interface


    
    <code>
    [root@CentOS6-UCS-OVS ~]# ovs-vsctl del-br br0
    [root@CentOS6-UCS-OVS ~]# vconfig add eth0 100
    [root@CentOS6-UCS-OVS ~]# ifconfig eth0.100 172.17.100.71/24
    [root@CentOS6-UCS-OVS ~]# route add default gw 172.17.100.1 dev eth0.100</code>



After creating this sub-interface eth0.100, I was able to ping outside my gateway! Now, I was sure there was something wrong my openvswitch vlan configuration or its interaction with the kernel. I put back my original configuration and did a tcpdump on mgmt0. I noticed that I could get L2 traffic through network but nothing L3. 

I found this [FAQ ](http://openvswitch.org/cgi-bin/gitweb.cgi?p=openvswitch;a=blob_plain;f=FAQ;hb=HEAD)on openvswitch.org website. Under the VLANS section, one of the items they listed as being a problem with NIC drivers working with openvswitch. To work around this problem, it was required that you turn on vlan-splinters.  The FAQ referenced the [man pages](http://manpages.ubuntu.com/manpages/precise/man5/ovs-vswitchd.conf.db.5.html#contenttoc0) for Open_vSwitch database that had more information regarding vlan-splinting. Vlan-splinting is an intermediary fix that the folks at openvswitch.org have, turning it on consumes more memory and cpu cycles from the hypervisor. The man pages also state that this feature will be depreciated. My plan is install the RHEL MK8 NIC drivers for UCS B200 blade on a later date in a separate post.

You can get also get to the man pages by issuing the command


    
    <code>[root@CentOS6-UCS-OVS ~]# man ovs-vswitchd.conf.db</code>



I put back my original configuration back, added my NFS interface (nfs0), a fake OVS bridge for VM traffic and enabled vlan-splinters. 

The fake OVS bridge is a very good solution to allowing VMs interact with VLANS. Using fake OVS bridges that act and feel just like real bridges is better solution than using tagged ports (which act just like cisco access ports). If you use tagged ports, you would have to create one for each VM. With fake OVS bridge that is tied to a particular VLAN, one fake bridge can be shared among several VMs. 


    
    <code>[root@CentOS6-UCS-OVS ~]# ovs-vsctl add-br br0
    [root@CentOS6-UCS-OVS ~]# ovs-vsctl add-port br0 eth0
    [root@CentOS6-UCS-OVS ~]# ovs-vsctl add-port br0 mgmt0 tag=100 -- set Interface mgmt0 type=internal
    [root@CentOS6-UCS-OVS ~]# ovs-vsctl add-port br0 nfs0 tag=105 -- set Interface nfs0 type=internal
    [root@CentOS6-UCS-OVS ~]# ovs-vsctl add-br prodbr br0 100 <font color="#FF0000"><-- Create fake bridge with name prodbr</font>
    [root@CentOS6-UCS-OVS ~]# ifconfig mgmt0  172.17.100.71 netmask 255.255.255.0
    [root@CentOS6-UCS-OVS ~]# ifconfig nfs0  172.17.105.62 netmask 255.255.255.0
    [root@CentOS6-UCS-OVS ~]# <font color="#FF0000">ovs-vsctl set interface eth0 other-config:enable-vlan-splinters=true</font>
    [root@CentOS6-UCS-OVS ~]# ovs-vsctl show
    0ce098af-ac7e-4d6c-a6e6-bac3ea1c99b7
        Bridge "br0"
            Port "br0"
                Interface "br0"
                    type: internal
            Port prodbr
                tag: 100
                Interface prodbr
                    type: internal
            Port "eth0"
                Interface "eth0"
            Port "mgmt0"
                tag: 100
                Interface "mgmt0"
                    type: internal
            Port "nfs0"
                tag: 105
                Interface "nfs0"
                    type: internal
        ovs_version: "1.9.0"</code>



I also added a default route through interface mgmt0.


    
    <code>
    [root@CentOS6-UCS-OVS ~]# route add default gw 172.17.100.1 dev mgmt0</code>



To get both the mgmt0 and nfs0 subnets you might need to configure route-filter as [documented HERE](https://fvtool.wordpress.com/2013/04/19/install-kvm-on-centos-6-3-configure-networking-b/) or add multiple routes.

I then installed a VM (vm1.demo.com) using the default KVM network. You need to specify a network that you can modify once the installation is complete and point it to the fake bridge tagged to vlan 100.


    
    <code>[root@CentOS6-UCS-OVS ~]# virt-install --name=vm1.demo.com --disk path=/var/lib/libvirt/images/vm1.img,size=12 --ram=512 --os-type=linux --os-variant=rhel6 --network network=default --nographics --cdrom=/tmp/CentOS-6.3-x86_64-minimal.iso</code>



I followed the instructions [ HERE to install the OS](https://fvtool.wordpress.com/2013/04/22/install-kvm-on-centos-6-3-installing-kvm-and-a-centos-virtual-machines/) with the default network. 

Once I installed the VM, you need to edit the libvirt VM networking and point it to the **OVS fake bridge** and configure it as a **virtualport type openvswitch**


    
    <code>[root@CentOS6-UCS-OVS ~]# virsh
    Welcome to virsh, the virtualization interactive terminal.
    
    Type:  'help' for help with commands
           'quit' to quit
    
    virsh #
    [virsh # list --all
     Id    Name                           State
    ----------------------------------------------------
     13    vm1.demo.com                   running
    virsh # shutdown vm1.demo.com
    Domain vm1.demo.com is being shutdown
    virsh # edit vm1.demo.com</code>



Using the virsh edit command to edit vm1.demo.com's xml gave me a vi like editor and I edited the interfaces section. 




    
    <code><interface type='network'>
    	<mac address='52:54:00:d6:9f:d5'/>
    	<source network='default'/>
    	<model type='virtio'/>
    	<address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x0'/>
    </interface></code>




I made the following changes to point it to the OVS fake bridge



    
    <code><interface type='<font color="#FF0000">bridge</font>'>
    		< mac address='52:54:00:d6:9f:d5'/>
    		< source bridge='<font color="#FF0000">prodbr</font>'/>
    		< <font color="#FF0000">virtualport</font> type='<font color="#FF0000">openvswitch</font>'/>
    		< ltaddress type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x0'/>
    < /interface></code>




I then started the VM connected to the VM console and was able to pick up a DHCP ip from my network


    
    <code>[root@CentOS6-UCS-OVS ~]# virsh start vm1.demo.com
    [root@CentOS6-UCS-OVS ~]# virsh console vm1.demo.com
    Connected to domain vm1.demo.com
    Escape character is ^]
    
    CentOS release 6.3 (Final)
    Kernel 2.6.32-279.el6.x86_64 on an x86_64
    localhost.localdomain login: root
    Password:
    Last login: Sun Apr 28 17:38:25 on ttyS0
    [root@localhost ~]# cat /etc/sysconfig/network-scripts/ifcfg-eth0
    DEVICE="eth0"
    BOOTPROTO="dhcp"
    HWADDR="52:54:00:D6:9F:D5"
    NM_CONTROLLED="yes"
    ONBOOT="yes"
    TYPE="Ethernet"
    UUID="b8ba7f9d-1507-4228-9b70-af37e986463f"
    [root@localhost ~]# ip a l
    1: lo: &ltLOOPBACK,UP,LOWER_UP&gt mtu 16436 qdisc noqueue state UNKNOWN
        #link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
        inet 127.0.0.1/8 scope host lo
        inet6 ::1/128 scope host
           valid_lft forever preferred_lft forever
    2: eth0: &ltBROADCAST,MULTICAST,UP,LOWER_UP&gt mtu 1500 qdisc pfifo_fast state UP qlen 1000
        #link/ether 52:54:00:d6:9f:d5 brd ff:ff:ff:ff:ff:ff
        inet 172.17.100.95/24 brd 172.17.100.255 scope global eth0
        inet6 fe80::5054:ff:fed6:9fd5/64 scope #link
           valid_lft forever preferred_lft forever</code>



I hope this helps someone out there
