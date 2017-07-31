---
author: mugithi
comments: true
date: 2013-04-19 01:05:42+00:00
layout: post
#link: https://fvtool.wordpress.com/2013/04/19/install-kvm-on-centos-6-3-configure-networking/
slug: install-kvm-on-centos-6-3-configure-networking
title: Install KVM on Centos 6.4 - Configure Networking
wordpress_id: 203
---

I have a customer who purchased a HP DL360s and wanted to use CentOS 6.4 and KVM as the hypervisor. I this was the configuration that we put together for him.

There are two options to allow a  KVM virtual machine running on CentOS 6 to connect to the network connectivity. 

Option 1: Connect to a virtual network running within the operating system of the host computer. 
In this configuration any virtual machines on the virtual network can see each other but access to the external network is provided by Network Address Translation port (NAT). In NATing all VMs are represented to the outside world using the Hypervisor's ip address. This is the default behavior or KVM and no additional configuration is needed other that selecting Virtual Network in the virt-manager in virtual machine wizard. This in turns creates a single virtual network represented by an interface device virbr0.

Option 2. Connect to the outside network using a network bridge in the linux kernel. 
In order for virtual guests to appear as individual and independent systems on the external network (i.e. with their own IP addresses), they must be configured to share a physical network interface on the host. This is achieved by configuring a network bridge interface on the host system to which the guests can connect. 

One of the designed recommendations that we had for him was for him to separate his NFS traffic from his Data traffic. For the separation, we used VLANs and the bridge interfaces that would be connecting to the virtual hosts would not be connected to the physical interfaces, but instead would be connected to the virtual interfaces that we would be configuring as part of the Linux VLAN configuration.


    
    <code>Physical Interface => Bonded Interface => Vlan Interface => Bridge Interface </code>




![Hypervisor Visio](http://fvtool.files.wordpress.com/2013/04/hypervisor-visio.jpg)

I found this article on the internet that talked about issues with setting up such a [configuration](https://wikis.uit.tufts.edu/confluence/display/TUSKpub/Configure+Pair+Bonding,+VLANs,+and+Bridges+for+KVM+Hypervisor) but the alternative was to configure either a flat network or a non redundant network, both of which [were not](http://blog.garraux.net/2012/07/data-center-server-access-topologies-part-1-logical-interface-config-on-servers/) good options for the customer. I decided to put together this configuration in my lab using UCS B200 blades in our LAB to make sure that this would work with KVM.

1. Setting up the "/etc/sysconfig/network". 
I found this mentioned in many blogs that for the bonding, tagged vlans and bridged interfaces to work together, it was required that you enable IPV6. 


    
    <code>[root@Centos63UCStemplate network-scripts]# cat /etc/sysconfig/network
    HOSTNAME=Centos63UCStemplate.demo.com
    NETWORKING=yes
    #IPV4
    NOZEROCONF=yes
    #IPV6
    <font color="#FF0000">NETWORKING_IPV6=yes
    IPV6INIT=yes</font></code>



2. Configure bonding in "modprobe". 
Centos 6.3 how you allow for bonding in modeprobe changed this. In previous versions of CentOS and RHEL, you had to make changes to the /etc/modprobe.conf file. This changed in Centos 6 explained really well in this [blog](http://www.justinedmands.com/?q=node/14) . In CentOS 6.3+ you put your changes in a file .conf that resides in the "/etc/modeprobe.d/"


    
    <code>[root@Centos63UCStemplate ~]# cat /etc/modprobe.d/bond0.conf
    alias bond0 bonding</code>



You can then run "modprobe bonding"


    
    <code>[root@Centos63UCStemplate ~]# modeprobe bonding</code>



3. Configure eth0 & eth1
The you then configure the physical interface ports to be slaves to bond0 as shown in the diagram. 


    
    <code>
    [root@Centos63UCStemplate ~]# cat /etc/sysconfig/network-scripts/ifcfg-eth0
    DEVICE="eth0"
    BOOTPROTO="none"
    HWADDR="00:25:B5:10:00:7E"
    NM_CONTROLLED="no"
    ONBOOT="yes"
    TYPE="Ethernet"
    UUID="3cb11394-84f3-4bfe-b792-3f47ce70e8aa"
    <font color="#FF0000">MASTER=bond0
    SLAVE=yes</font>
    NOZEROCONF=yes
    
    [root@Centos63UCStemplate ~]# cat /etc/sysconfig/network-scripts/ifcfg-eth1
    DEVICE="eth1"
    BOOTPROTO="none"
    HWADDR="00:25:B5:10:00:6E"
    NM_CONTROLLED="no"
    ONBOOT="yes"
    TYPE="Ethernet"
    UUID="969077dd-9091-4e66-bb9d-e6e05a1176d1"
    <font color="#FF0000">MASTER=bond0
    SLAVE=yes</font>
    NOZEROCONF=yes
    [root@Centos63UCStemplate ~]#</code>



4. Create bond0
You then create bond0 with the appropriate load balancing options

    
    <code>
    [root@Centos63UCStemplate ~]# cat /etc/sysconfig/network-scripts/ifcfg-bond0
    BOOTPROTO=none
    DEVICE=bond0
    IPV6INIT=no
    NM_CONTROLLED=no
    ONBOOT=yes
    BONDING_OPTS="miimon=100 mode=balance-tlb"
    USERCTL=no
    NOZEROCONF=yes
    TYPE=Unknown</code>



5. Since we are using VLANS, we now create the VLAN interfaces on top of bond0, bond0.100 and bond105 pointing to the appropriate bridge interfaces.

    
    <code>[root@Centos63UCStemplate ~]# cat /etc/sysconfig/network-scripts/ifcfg-bond0.100
    [root@Centos63UCStemplate ~]# cat /etc/sysconfig/network-scripts/ifcfg-bond0.100
    DEVICE=bond0.100
    VLAN=yes
    BOOTPROTO=static
    ONBOOT=yes
    TYPE=Unknown
    <font color="#FF0000">BRIDGE=br100</font>
    [root@Centos63UCStemplate ~]# cat /etc/sysconfig/network-scripts/ifcfg-bond0.105
    DEVICE=bond0.105
    VLAN=yes
    BOOTPROTO=static
    ONBOOT=yes
    TYPE=Unknown
    <font color="#FF0000">BRIDGE=br105</font></code>



6. Setup the bridge interface
To first setup the bridge interface you first need to install the bridging driver


    
    <code>[root@Centos63UCStemplate ~]# yum install bridge-utils
    </code>



You then configure the bridge interfaces. On this bridge interfaces, I was going to configure my IP addresses. 

    
    <code>[root@Centos63UCStemplate ~]# cat /etc/sysconfig/network-scripts/ifcfg-br100
    DEVICE=br100
    ONBOOT=yes
    SLAVE=bond0.100
    TYPE=Bridge
    VLAN=yes
    GATEWAY=172.17.100.1
    IPADDR=172.17.100.60
    NETMASK=255.255.255.0
    NM_CONTROLLED=no
    NOZEROCONF=yes
    [root@Centos63UCStemplate ~]# cat /etc/sysconfig/network-scripts/ifcfg-br105
    DEVICE=br105
    ONBOOT=yes
    SLAVE=bond0.105
    TYPE=Bridge
    VLAN=yes
    GATEWAY=172.17.105.1
    IPADDR=172.17.105.70
    NETMASK=255.255.255.0
    NM_CONTROLLED=no
    NOZEROCONF=yes</code>



You can then restart the network and if you did not have any typos or have issues loading the bonding driver, the interface should come up. 


    
    <code>[root@Centos63UCStemplate ~]# service network restart
    Shutting down interface eth0:                         [  OK  ]
    Shutting down interface eth1:                         [  OK  ]
    Shutting down loopback interface:                          [  OK  ]
    Bringing up loopback interface:                            [  OK  ]
    Bringing up interface bond0:                               [  OK  ]
    Bringing up interface bond0.100:                           [  OK  ]
    Bringing up interface bond0.105:                           [  OK  ]
    Bringing up interface br100:                               [  OK  ]
    Bringing up interface br105:                               [  OK  ]
    [root@Centos63UCStemplate ~]#</code>



You can now check the status of the bridges using this command


    
    <code>[root@Centos63UCStemplate ~]# brctl show
    bridge name	bridge id		STP enabled	interfaces
    br100		8000.0025b510007e	no		bond0.100
    br105		8000.0025b510007e	no		bond0.105
    </code>



Once I fixed a few [gotchas with routing](https://fvtool.wordpress.com/2013/04/page/4/), I was able to [install a Hypervisor](https://fvtool.wordpress.com/2013/04/page/3/),  mount an NFS export and configure an Ubuntu VM.
