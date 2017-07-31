---
author: mugithi
comments: true
date: 2013-05-08 17:35:00+00:00
layout: post
#link: https://fvtool.wordpress.com/2013/05/08/install-openstack-on-centos-6-4/
slug: install-openstack-on-centos-6-4
title: Install openstack on CentOS 6.4 using packstack
wordpress_id: 254
categories:
- Openstack
tags:
- easy openstack install
- install openstack
- install openstack in 3 steps
- packstack
---

I was looking for an easy way to quickly deploy Openstack on my CentOS environment, I found that there are many tools available to accomplish this in Ubuntu but very few for CentOS. Then I found this project [packstack](https://wiki.openstack.org/wiki/Packstack), packstack is a utility that uses Puppet modules to deploy various parts of OpenStack on multiple pre-installed servers over SSH automatically using python. I found that [Redhat](https://access.redhat.com/site/documentation/en-US/Red_Hat_OpenStack_Preview/2/html/Getting_Started_Guide/part-Deploying_OS_using_PackStack.html) has started contributing to packstack and they have some very good documentation on how to quickly get going. For example, if you are installing an all in one configuration, meaning installing all the openstack modules in one server, you only need to run three commands to get the environment up and running. As of the date of this blog, packstack is only supported on Fedora, Red Hat Enterprise Linux (RHEL) and compatible derivatives of both.

My Openstack installation consisted  of  VMware CentOS 6.4 Control node and a UCS Blade CentOS 6.4 compute node as shown below.

![Openstack Install](http://fvtool.files.wordpress.com/2013/05/openstack-install.jpg) 

The perquisites are to have sufficient memory and to turn off selinux or set it to permissive. Changes to selinux require a reboot. You also need sudo access, I ran packstack from my control node.


    
    <code>[root@hq-openstack-control ~]# cat /etc/selinux/config
    # This file controls the state of SELinux on the system.
    # SELINUX= can take one of these three values:
    #     enforcing - SELinux security policy is enforced.
    #     permissive - SELinux prints warnings instead of enforcing.
    #     disabled - No SELinux policy is loaded.
    <font color="#FF0000">SELINUX=disabled</font>
    # SELINUXTYPE= can take one of these two values:
    #     targeted - Targeted processes are protected,
    #     mls - Multi Level Security protection.
    SELINUXTYPE=targeted</code>




First add the fedora repo - [you can also install from github](https://github.com/stackforge/packstack) - and install packstack using yum


    
    <code>[root@hq-openstack-control ~]# yum install -y http://rdo.fedorapeople.org/openstack/openstack-grizzly/rdo-release-grizzly-2.noarch.rpm
    [root@hq-openstack-control ~]# yum install -y openstack-packstack
    </code>



Configure  NTP on the nodes. This is not a must but is a good to have. Install ntp and sync up with your ntp server. I used a public ntp server in my configuration.


    
    <code>[root@hq-openstack-control ~]# yum install ntp
    [root@hq-openstack-control ~]# chkconfig ntpd on
    [root@hq-openstack-control ~]# ntpdate pool.ntp.org
    [root@hq-openstack-control ~]# /etc/init.d/ntpd start</code>



Now, since I wanted to make modifications to the default packstack install, I generated a file that contained the install configuration. This file is called "answer file" and I put my configuration preferences in it. I then told packstack to use that file to do the install. This answer file is also used if you need to make changes to the openstack cluster, for example if you wanted to add a node. You would use the same process, make changes to the answer file to reflect that a new node has been added and again run packstack and point it to modified the answer file. 

I generated the answer file

    
    <code>[root@hq-openstack-control ~]# packstack --gen-answer-file=/root/grizzly_openstack.cfg
    [root@hq-openstack-control ~]# vi grizzly_openstack.cfg</code>



The answer file defaults to putting all the openstack modules in one node. 

I  made changes to ensure that my swift node was installed in my compute node running on a UCS B200 blade. I left the swift proxy node in the control node. Node 172.17.100.71 is my compute node and node 172.17.100.72 is my control node.



    
    <code># A comma separated list of IP addresses on which to install the
    # Swift Storage services, each entry should take the format
    # [/dev], for example 127.0.0.1/vdb will install /dev/vdb
    # on 127.0.0.1 as a swift storage device(packstack does not create the
    # filesystem, you must do this first), if /dev is omitted Packstack
    # will create a loopback device for a test setup
    CONFIG_SWIFT_STORAGE_HOSTS=172.17.100.71
    
    #The IP address on which to install the Swift proxy service
    CONFIG_SWIFT_PROXY_HOSTS=172.17.100.72</code>



I installed Cinder in my compute node.


    
    <code># The IP address of the server on which to install Cinder
    CONFIG_CINDER_HOST=172.17.100.71</code>



I installed nova compute in my compute node. If on a later date I wanted to add a second compute node, I would come make the changes here.


    
    <code># A comma separated list of IP addresses on which to install the Nova
    # Compute services
    CONFIG_NOVA_COMPUTE_HOSTS=172.17.100.71</code>



I also set public interface for Nova Network on the control node to be eth0  

    
    <code># Public interface on the Nova network server
    CONFIG_NOVA_NETWORK_PUBIF=eth0
    </code>



And set the private interface for Nova Network dhcp on the control nodes and private interface of the Nova 


    
    <code># Private interface for Flat DHCP on the Nova network server
    CONFIG_NOVA_NETWORK_PRIVIF=eth1
    
    # Private interface for Flat DHCP on the Nova compute servers
    CONFIG_NOVA_COMPUTE_PRIVIF=eth1
    </code>



At this point I was done and was ready to start the install. During the install, you will be prompted for the compute nodes root password.


    
    <code>[root@hq-openstack-control ~]# sudo packstack --answer-file=/root/grizzly_openstack.cfg
    Welcome to Installer setup utility
    Packstack changed given value  to required value /root/.ssh/id_rsa.pub
    Installing:
    Clean Up...                                              [ DONE ]
    Adding pre install manifest entries...                   [ DONE ]
    Setting up ssh keys...root@172.17.100.72's password:
    ..
    172.17.100.72_swift.pp :                                             [ DONE ]
    172.17.100.72_nagios.pp :                                            [ DONE ]
    172.17.100.72_nagios_nrpe.pp :                                       [ DONE ]
    Applying 172.17.100.72_postscript.pp		[ DONE ] 
    172.17.100.72_postscript.pp :                                        [ DONE ]
    </code>



A few 5-15 minutes later the install will complete.


    
    <code>[root@hq-openstack-control ~]# nova-manage service list
    Binary           Host                                 Zone             Status     State Updated_At
    nova-consoleauth hq-openstack-control                 internal         enabled    :-)   2013-05-08 16:32:10
    nova-cert        hq-openstack-control                 internal         enabled    :-)   2013-05-08 16:32:10
    nova-conductor   hq-openstack-control                 internal         enabled    :-)   2013-05-08 16:32:10
    nova-scheduler   hq-openstack-control                 internal         enabled    :-)   2013-05-08 16:32:10
    nova-network     hq-openstack-control                 internal         enabled    :-)   2013-05-07 20:56:47
    nova-compute     hq-ucs-openstack-compute-node-01            enabled    :-)   2013-05-08 16:32:19</code>



To log in, you naviage to glance on your browser from http://controler_node_ip. Username is **admin**. Password would have been auto generated for you when you created the answer file. You can get it by greping for the keystone password


    
    <code>[root@hq-openstack-control ~]# cat /root/grizzly_openstack.cfg  | grep -i CONFIG_KEYSTONE_ADMIN_PW
    CONFIG_KEYSTONE_ADMIN_PW=<font color="#FF0000">2asdaf559d32asdfasdfa234bd1</font></code>



You can also grep the keystonerc_admin file generated in the install directory


    
    <code>[root@hq-openstack-control ~(keystone_admin)]# cat keystonerc_admin
    export OS_USERNAME=admin
    export OS_TENANT_NAME=admin
    export OS_PASSWORD=<font color="#FF0000">2asdaf559d32asdfasdfa234bd1</font>
    export OS_AUTH_URL=http://172.17.100.72:35357/v2.0/
    export PS1='[\u@\h \W(keystone_admin)]\$ '</code>



You are now ready to [deploy](http://openstack.redhat.com/Running_an_instance) instances.

In my next post, I will describe how to convert from nova networking to using Quantum networking services.
