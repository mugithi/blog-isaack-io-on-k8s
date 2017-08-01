---
author: mugithi
comments: true
date: 2013-04-24 22:24:31+00:00
layout: post
#link: https://fvtool.wordpress.com/2013/04/24/install-kvm-on-centos-6-3-installing-open-vswitch/
slug: install-kvm-on-centos-6-3-installing-open-vswitch
title: Install KVM on Centos 6.4 - Installing Open VSwitch
wordpress_id: 219
tags:
- Centos
- hypervisor
- kvm
- open
- openstack
- openvswitch
- redhat
- vswitch
---

In my [previous blog entry](https://fvtool.wordpress.com/2013/04/19/install-kvm-on-centos-6-3-configure-networking/), I had installed KVM with a bonded VLAN linux bridge interface with VLAN. Now, while using VLAN tagging with bridges worked properly and I could get the VMS to talk out, I found that dmesg had had this entries

br105: IPv6 duplicate address fe80::225:b5ff:fe10:19d detected!
bond0.105: received packet with own address as source address
bond0.100: received packet with own address as source address


From my quick search in google, I concluded that it must be because I was using a Layer 2 bridge on a bonded interface and the interfaces were in promiscuous mode. I decided to install a OpenVSwitch and see if I would still get rid this errors.

To Install OpenVSwitch

1. Install the following dependancies


    
    <code>[root@Centos63UCStemplate x86_64]# yum install -y rpm-build
    [root@Centos63UCStemplate x86_64]# yum groupinstall -y "Development Tools"
    [root@Centos63UCStemplate x86_64]# yum install -y openssl-devel</code>



2. Download the openvswitch tar ball from openvswitch.org


    
    <code>[root@Centos63UCStemplate x86_64]# cd /tmp
    [root@Centos63UCStemplate x86_64]# wget http://openvswitch.org/releases/openvswitch-1.9.0.tar.gz</code>




3. Create the default RPM directory if you are using CentOS/RHEL 6 as shown below. If you are using CentOS/RHEL 5, the path would be "/usr/src/redhat/SOURCES"


    
    <code>[root@Centos63UCStemplate x86_64]# mkdir -p $HOME/rpmbuild/SOURCES</code>



4. Move the tar ball to the default RPM directory and untag the tar ball


    
    <code>
    [root@Centos63UCStemplate x86_64]# cp /tmp/openvswitch-1.9.0.tar.gz $HOME/rpmbuild/SOURCES/
    [root@Centos63UCStemplate x86_64]# cd $HOME/rpmbuild/SOURCES
    [root@Centos63UCStemplate x86_64]# tar -xvf openvswitch-1.9.0.tar.gz
    </code>



5. Remove the requirement for kmod from the .spec file under the Requires lines. I had tried to install without this step but the rpm install generated the error "Requires: openvswitch-kmod"


    
    <code>[root@Centos63UCStemplate x86_64]# vi $HOME/rpmbuild/SOURCES/openvswitch-1.9.0/rhel/openvswitch.spec
    ……………
    
    License: ASL 2.0
    Release: 1
    Source: openvswitch-%{version}.tar.gz
    Buildroot: /tmp/openvswitch-rpm
    <font color="#FF0000">Requires: openvswitch-kmod, logrotate, python</font>
    </font></code>


to


    
    <code>[root@Centos63UCStemplate x86_64]# vi $HOME/rpmbuild/SOURCES/openvswitch-1.9.0/rhel/openvswitch.spec
    License: ASL 2.0
    Release: 1
    Source: openvswitch-%{version}.tar.gz
    Buildroot: /tmp/openvswitch-rpm
    <font color="#FF0000">Requires: logrotate, python
    </font></code>



6. Build Open vSwitch userspace


    
    <code>cd /openvswitch-1.9.0
    rpmbuild -bb -D `uname -r` rhel/openvswitch.spec</code>



7. Move into the RPMs directory and install the rpm


    
    <code>[root@Centos63UCStemplate x86_64]# cd $HOME/rpmbuild/RPMS/x86_64
    [root@Centos63UCStemplate x86_64]# ll
    total 8100
    -rw-r--r-- 1 root root 2148660 Apr 24 06:08 openvswitch-1.9.0-1.x86_64.rpm
    -rw-r--r-- 1 root root 6143728 Apr 24 06:08 openvswitch-debuginfo-1.9.0-1.x86_64.rpm
    [root@Centos63UCStemplate x86_64]# yum localinstall openvswitch-1.9.0-1.x86_64.rpm</code>



8. Start the openswitch daemon


    
    <code>[root@Centos63UCStemplate x86_64]# /etc/init.d/openvswitch start
    /etc/openvswitch/conf.db does not exist ... (warning).
    Creating empty database /etc/openvswitch/conf.db           [  OK  ]
    Starting ovsdb-server                                      [  OK  ]
    Configuring Open vSwitch system IDs                        [  OK  ]
    Inserting openvswitch module                               [  OK  ]
    Starting ovs-vswitchd                                      [  OK  ]
    Enabling gre with iptables                                 [  OK  ]
    [root@Centos63UCStemplate x86_64]#</code>
