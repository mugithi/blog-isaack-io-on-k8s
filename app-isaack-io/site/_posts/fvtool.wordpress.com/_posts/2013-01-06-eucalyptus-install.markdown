---
author: mugithi
comments: true
date: 2013-01-06 18:41:13+00:00
layout: post
#link: https://fvtool.wordpress.com/2013/01/06/eucalyptus-install/
slug: eucalyptus-install
title: Eucalyptus Install
wordpress_id: 177
tags:
- Eucalpytus 3.1
- eucstore-install-image
---

I recently was installing a 20 node Eucalyputus 3.1 cluster with converged Walrus, SC, NC and Cloud Controller. I found that it was much easier that I had thought. Eucalyptus had done a very good job of putting together a install and administration guide and if you follow it i doubt you will run into any problems. A few things i found during the install and configuration that might help some one out there. 

I was installing Centos 6.3 and was using KVM as my hypervisor. The install guide calls that you run load the hypervisor drivers.


    
    <code>
    modprobe kvm
    modprobe kvm_intel</code>




When i tried to start the NC services I got this message from the nodes

    
    <code>
    [root@headnode ~]# ssh nc01 service eucalyptus-nc start
    Starting Eucalyptus services: 
    Node Controller cannot be started: errors in //var/log/eucalyptus/euca_test_nc.log</code>



I checked the file /var/log/eucalyptus/euca_test_nc.log and 


    
    <code>[root@headnode ~]# ssh nc01 cat /var/log/eucalyptus/euca_test_nc.log
    This is perl, v5.10.1 (*) built for x86_64-linux-thread-multi
    Copyright 1987-2009, Larry Wall
    Perl may be copied only under the terms of either the Artistic License or the
    GNU General Public License, which may be found in the Perl 5 source kit.
    Complete documentation for Perl, including FAQ lists, should be found on
    this system using "man perl" or "perldoc perl".  If you have access to the
    Internet, point your browser at http://www.perl.org/, the Perl Home Page.
    
    looking for system utilities...
    [Fri Jan  4 11:00:23 2013][011343][EUCAINFO  ] found grub 1 stage files in /boot/grub
    ok
    
    looking for euca2ools...
    ok
    
    checking the hypervisor...
    total_memory=16457
    nr_cores=8
    libvir: RPC error : Failed to connect socket to '/var/run/libvirt/libvirt-sock': No such file or directory
    libvirt error: Failed to connect socket to '/var/run/libvirt/libvirt-sock': No such file or directory (code=38)
    error: failed to connect to hypervisor</code>



It seemed as if libvirtd was having a problem. I restarted the service and it came up fine but checking it status it reported


    
    <code>[root@headnode ~]# ssh nc01 service libvirtd status
    libvirtd dead but subsys locked
    [root@headnode ~]#</code>



A quick google search and I found [this article](https://bugzilla.redhat.com/show_bug.cgi?id=680730) that showed a bug in libvirtd that was supposed to have been fixed in Feb 2012. I pinged one of the folks at Eucalyptus and he shot back a quick email letting me know that sometimes the kernel modules do not insert properly and I should try reboot the NCs. I rebooted the 20 nodes and 10 mins later i got pure goodness.


    
    <code>
    [root@headnode ~]# ssh nc01 service eucalyptus-nc start
    Starting Eucalyptus services: 
    Ok</code>



The second problem I had involved running out of space while running eucstore-install-image. Eucalyptus provides you with OS images from EucaStore that you can install after installation. I was eager to test out the install and this is what I decided to use. To do this you issue the command. There is also examine their website to see what images they have in the [store](http://emis.eucalyptus.com)

    
    <code>[root@headnode ~]# eustore-describe-images
    0400376721 fedora      x86_64  starter        kvm               Fedora 16 x86_64 - SELinux / iptables disabled. Root disk of 4.5G. Root user enabled.
    2425352071 fedora      x86_64  starter        kvm               Fedora 17 x86_64 - SELinux / iptables disabled. Root disk of 4.5G. Root user enabled.
    1107385945 centos      x86_64  starter        xen, kvm, vmware  CentOS 5 1.3GB root, Hypervisor-Specific Kernels
    0696716400 centos      x86_64  starter        kvm               Updated - CentOS 5 1.3GB root, Hypervisor-Specific Kernel; 2.6.18-308.11.1.el5 kernel version
    3868652036 centos      x86_64  starter        kvm               CentOS 6.3 x86_64 - SELinux / iptables disabled. Root disk of 4.5G. Root user enabled.
    1347115203 opensuse    x86_64  starter        kvm               OpenSUSE 12.2 x86_64 - KVM image. SUSE Firewall off. Root disk of 2.5G. Root user enabled. Working with kexec kernel and ramdisk. OpenSUSE minimal base package set..</code>



Then select the image you want to install and issue the command 

    
    <code>[root@headnode tmp]# eustore-install-image -b centos-testbucket -i 3868652036 -k kvm
    Downloading Image :  CentOS 6.3 x86_64 - SELinux / iptables disabled. Root disk of 4.5G. Root user enabled.
    0-----1-----2-----3-----4-----5-----6-----7-----8-----9-----10
    ##############################################################
    
    Checking image bundle
    Unbundling image
    Checking image
    Compressing image
    
    gzip: stdout: No space left on device
    'gzip' returned error (1) </code>



When you install any image in Eucalyptus, it uses /tmp directory to store the temporary files. I had run out of space in my / and hence my /tmp location and so the eucstore-install-image command failed. I found this to be rather annoying that you could not specify another default temporary location to uncompress the files. To clean up I navigated to the tmp directory 


    
    <code>[root@headnode tmp]# ls /tmp/
    <font color="#FF0000">9T6XpK </font>    cloud-cert.pem  euca2-admin-27400b85-cert.pem  euca-chainmap-7eY20n  euca-clcnet-9yy688  eucalyptus.conf  hsperfdata_root  jBneY2       ks-script-N2SvKM
    admin.zip  copyscrp        euca2-admin-27400b85-pk.pem    euca-chainmap-wvqxap  euca-clcnet-Qmv5c9  eucarc           iamrc            jssecacerts</code>



eucstore-install-image creates a temporary directory in the tmp folder with a name made of 6 random characters. Mine was the folder in red. Delete that folder.

To specify the a temp folder to be used for the install, use the -d option. I had a /data/image location so I issued the command 


    
    <code>[root@headnode tmp]# eustore-install-image -b centos-testbucket -i 3868652036 -k kvm <font color="#FF0000">-d /data/images/</font></code>



and the image install worked ok.
