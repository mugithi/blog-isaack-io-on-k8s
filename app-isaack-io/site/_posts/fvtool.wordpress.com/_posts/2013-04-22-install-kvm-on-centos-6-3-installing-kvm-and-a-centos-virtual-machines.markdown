---
author: mugithi
comments: true
date: 2013-04-22 06:59:56+00:00
layout: post
#link: https://fvtool.wordpress.com/2013/04/22/install-kvm-on-centos-6-3-installing-kvm-and-a-centos-virtual-machines/
slug: install-kvm-on-centos-6-3-installing-kvm-and-a-centos-virtual-machines
title: Install KVM on Centos 6.4 - Installing KVM and a CentOS Virtual machines
wordpress_id: 216
categories:
- Openstack on KVM
tags:
- Install KVM
---

Once the networking is setup, installing KVM and installing the virtual machines was fairly straight forward.

The first thing that is to make sure that CPU virtualizaion is enabled in the BIOS. This can be done by checking /proc/cpuinfo for the appropriate flags. You should se something similar to this.


    
    <code>[root@Centos63UCStemplate ~]# cat /proc/cpuinfo | egrep '(<font color="#FF0000">vmx</font>|svm)' --color=always
    flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx pdpe1gb rdtscp lm constant_tsc arch_perfmon pebs bts rep_good xtopology nonstop_tsc aperfmperf pni pclmulqdq dtes64 monitor ds_cpl <font color="#FF0000">vmx</font> smx est tm2 ssse3 cx16 xtpr pdcm pcid dca sse4_1 sse4_2 popcnt aes lahf_lm ida arat dts tpr_shadow vnmi flexpriority ept vpid</code>



Next is installing the appropriate kvm & virt modules


    
    <code>[root@Centos63UCStemplate ~]# yum install virt-viewer virt-top kvm libvirt python-virtinst qemu-kvm
    Loaded plugins: fastestmirror
    Loading mirror speeds from cached hostfile</code>



Then start the libvirt daemon and verify that it is running properly


    
    <code>[root@Centos63UCStemplate ~]# /etc/init.d/libvirtd start
    Starting libvirtd daemon:
    [root@Centos63UCStemplate ~]# virsh -c qemu:///system list
     Id    Name                           State
    ----------------------------------------------------
    </code>



I wanted to use a NFS mount coming of my EMC VNX to store my virtual machine images. To do that, i needed to change the location of my images directory located in /var/lib/libvert

I first mounted the NFS export on my CentOS 6.4 host


    
    <code>[root@Centos63UCStemplate ~] mount -o nolock 172.17.105.90:/DATA/DATA /DATA
    </code>


I then removed the default images folder and #linked it to the location of my NFS mount


    
    <code>[root@Centos63UCStemplate ~] cd /var/lib/libvirt/
    [root@Centos63UCStemplate ~] rmdir images
    [root@Centos63UCStemplate ~] ln -s /DATA/ /var/lib/libvirt/images
    </code>



You are now ready to start installing virtual machines. I had download a CentOS6 iso and dropped it into my temp folder. You can start the linux install using the following command.


    
    <code>[root@Centos63UCStemplate ~]# virt-install --name=vm1.demo.com --disk path=/var/lib/libvirt/images/vm1.img,size=12 --ram=512 --os-type=linux --os-variant=rhel6 --network bridge:br100 --nographics --cdrom=/tmp/CentOS-6.3-x86_64-bin-DVD1.iso</code>



From the above command, am creating a instance with the following properties

name=vm1.demo.com, ram=512MB, disk size = 12GB, network would be connected to bridged interface br100. The traffic would pass to the VM untagged since it would be untagged on interface bond.100.

Once you hit enter, you are get the  Linux grub boot screen below.  


    
    <code>
              +----------------------------------------------------------+
              |                  Welcome to CentOS 6.3!                  |
              |----------------------------------------------------------|
              | Install or upgrade an existing system                    |
              | Install system with basic video driver                   |
              | Rescue installed system                                  |
              | Boot from local drive                                    |
              | Memory test                                              |
              |                                                          |
              |                                                          |
              |                                                          |
              |                                                          |
              |                                                          |
              |                                                          |
              |                                                          |
              +----------------------------------------------------------+
    
    > vmlinuz initrd=initrd.imgress [Tab] to edit options</code>



At this screen, DO NOT HIT ENTER instead hit TAB. You need to enable access to the serial console and you do this by adding the line vmlinuz initrd=initrd.img console=ttyS0,115200 as shown below.


    
    <code>
    
              +----------------------------------------------------------+
              |                  Welcome to CentOS 6.3!                  |
              |----------------------------------------------------------|
              | <strong>I</strong>nstall or upgrade an existing system                    |
              | Install system with <strong>b</strong>asic video driver                   |
              | <strong>R</strong>escue installed system                                  |
              | Boot from <strong>l</strong>ocal drive                                    |
              | <strong>M</strong>emory test                                              |
              |                                                          |
              |                                                          |
              |                                                          |
              |                                                          |
              |                                                          |
              |                                                          |
              |                                                          |
              +----------------------------------------------------------+
    
                              Press [Tab] to edit options
    
                            Automatic boot in 59 seconds...
    
    
    > vmlinuz initrd=initrd.img <font color="#FF0000">console=ttyS0,115200</font> </code>



You can then follow the prompts to complete the CentOS install. 

Welcome to CentOS for x86_64


    
    <code>
    
    
         ┌───────────────────────────┤ Complete ├────────────────────────────┐
         │                                                                   │
         │ Congratulations, your CentOS installation is complete.            │
         │                                                                   │
         │ Please reboot to use the installed system.  Note that updates may │
         │ be available to ensure the proper functioning of your system and  │
         │ installation of these updates is recommended after the reboot.    │
         │                                                                   │
         │                            ┌────────┐                             │
         │                            │ Reboot │                             │
         │                            └────────┘                             │
         │                                                                   │
         │                                                                   │
         └───────────────────────────────────────────────────────────────────┘
    
    
    </code>




After the install reboot you will be brought to the login prompt.

The final thing is to configure the networking on the newly installed vm. Since my bridge was configured on top of my bond0.100 interface, all the packets going into the network bridge untagged and consequently into the VM are untagged. All you have to do is to add an ip to your eth0.


    
    <code>[root@vm1.demo.com ~]# echo -e "IPADDR=172.17.100.37\nNETMASK=255.255.255.0\nGATEWAY=172.17.100.1.0" >> /etc/sysconfig/network-scripts/ifcfg-eth0
    [root@vm1.demo.com ~]# ping 172.17.100.1
    PING 172.17.100.1 (172.17.100.1) 56(84) bytes of data.
    64 bytes from 172.17.100.1: icmp_seq=1 ttl=255 time=1.36 ms</code>




Something to note, 



  1. I noticed that were messages in the dmesg that talked about there being a duplicate ipv6 ip address in the network. As I was putting together this blog post, I had not found a way to solve this. 

  2. Although the VM NIC was in VLAN 100 which has a DHCP server, I was unable to get dhcp to work on the VM, I was using static ip address so this was not such a big deal for me. I can see if you are pie booting this being a problem.


