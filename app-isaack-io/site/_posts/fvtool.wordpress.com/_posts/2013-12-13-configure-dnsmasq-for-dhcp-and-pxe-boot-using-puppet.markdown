---
author: mugithi
comments: true
date: 2013-12-13 04:50:07+00:00
layout: post
#link: https://fvtool.wordpress.com/2013/12/13/configure-dnsmasq-for-dhcp-and-pxe-boot-using-puppet/
slug: configure-dnsmasq-for-dhcp-and-pxe-boot-using-puppet
title: Configure DNSMASQ for DHCP and PXE BOOT using puppet
wordpress_id: 287
tags:
- cobbler
- dhcpboot
- puppet
- pxeboot
---

Download the DNSMASQ forge module from lex/dnsmasq => http://forge.puppetlabs.com/lex/dnsmasq. There are plenty of modules but I found his module to be easiest to use


    
    <code>Install the module using puppet
    [root@puppet-server modules]# puppet module search dnsmasq
    Notice: Searching https://forge.puppetlabs.com ...
    NAME                  DESCRIPTION                                 AUTHOR         KEYWORDS
    DavidSchmitt-dnsmasq                                              @DavidSchmitt  dns dhcp dnsmasq
    a2tar-dnsmasq         dnsmasq puppet module for ubuntu            @a2tar         ubuntu dnsmasq,
    <font color="#FF0000">lex-dnsmasq           Puppet Dnsmasq management module            @lex           dns dhcp dnsmasq</font>
    netmanagers-dnsmasq   Puppet module for dnsmasq                   @netmanagers   dns dhcp bind cli
    saz-dnsmasq           UNKNOWN                                     @saz           dns dhcp dnsmasq
    saz-resolv_conf       UNKNOWN                                     @saz           redhat dnsmasq
    [root@puppet-server modules]# 
    </code>



Once DNSMASQ is installated you will have this such tree. You will be modifying the file /etc/puppet/modules/dnsmasq/manifests/init.pp and you will be making use of the files dhcpboot.pp and dhcp.pp.


    
    <code>root@puppet-server modules]# tree /etc/puppet/modules/dnsmasq/manifests/
    /etc/puppet/modules/dnsmasq/manifests/
    ├── address.pp
    ├── cname.pp
    <font color="#FF0000">├── dhcpboot.pp</font>
    ├── dhcpoption.pp
    <font color="#FF0000">├── dhcp.pp</font>
    ├── dhcpstatic.pp
    ├── domain.pp
    <font color="#FF0000">├── init.pp</font>
    ├── mx.pp
    ├── params.pp
    ├── ptr.pp
    ├── srv.pp
    └── txt.pp</code>



At the end of the  /etc/puppet/modules/dnsmasq/manifests/init.pp file declare the following classes

    
    <code>[root@puppet-server modules]# cat /etc/puppet/modules/dnsmasq/manifests/init.pp
    #Primary class with options
    class dnsmasq (
      $interface = undef,
      $listen_address = undef,
      $domain = undef,
      $expand_hosts = true,
      $port = '53',
      $enable_tftp = false,
    
    	.....
    	....
    	...
    	..
    
     }
    
      file { $dnsmasq_confdir:
        ensure => 'directory',
      }
    
      concat::fragment { 'dnsmasq-header':
        order   => '00',
        target  => $dnsmasq_conffile,
        content => template('dnsmasq/dnsmasq.conf.erb'),
        require => Package[$dnsmasq_package],
      }
    
      concat { $dnsmasq_conffile:
        notify  => Service[$dnsmasq_service],
        require => Package[$dnsmasq_package],
      }
    
    }
    <font color="#FF0000">#define the chass dhcp
    class dnsmasq::dhcp {
    }
    
    #define the chass dhcpboot
    class dnsmasq::dhcpboot {
    }
    </font></code>



The default puppet installation creates the directory structure under /etc/puppet/manifests/ or /etc/puppetlabs/puppet/manifests/ depending on the puppet version you are running. You will need to create the following files.


    
    <code>[root@puppet-server modules]# tree /etc/puppet/manifests/
    /etc/puppet/manifests/
    <font color="#FF0000">├── init.pp
    └── site.pp </font></code>



In this two files you will define the configuration that will be applied to your puppet client.


    
    <code>[root@puppet-server modules]# cat /etc/puppet/manifests/site.pp
    [root@puppet-server modules]# cat /etc/puppet/manifests/site.pp
    #Default Node configuration
    node default {
    }
    #Add DNSMASQ, DHCP and DHCPBOOT(PXEBOOT) to my puppet client
    #puppet-server that is also the puppet master
    node puppet-server {
    	include dnsmasq
    	include dnsmasq::dhcp
    	include dnsmasq::dhcpboot
    }
    </code>


Under site.pp
[root@puppet-server modules]# cat /etc/puppet/manifests/init.pp

    
    <code>#instantiate class dnsmasq
    class { 'dnsmasq':
      interface      => 'eth0',
      listen_address => '10.211.55.4',
      domain         => 'local',
      port           => '53',
      expand_hosts   => true,
      enable_tftp    => true,
      tftp_root      => '/var/lib/tftpboot',
      dhcp_boot      => 'pxelinux.0',
      domain_needed  => true,
      bogus_priv     => true,
      no_negcache    => true,
      no_hosts       => true,
      resolv_file    => '/etc/resolv.conf',
      cache_size     => 1000
    }
    #instantiate class dhcp
    dnsmasq::dhcp { 'dhcp':
      dhcp_start => '10.211.55.100',
      dhcp_end   => '10.211.55.110',
      netmask    => '255.255.255.0',
      lease_time => '24h'
    }
    #instantiate class dhcpboot(pxeboot)
    dnsmasq::dhcpboot { 'local':
      file       => 'pxelinux.0',
      hostname   => 'puppet-local',
      bootserver => '10.211.55.4'
    }</code>



You can then this force the client  query the catalog on the puppet master for state it should be in


    
    <code>[root@puppet-server modules]# puppet agent -t
    </code>



Also, to check for syntax errors during this, you can the puppet parser validate command. At the end of this you should have DNSMASQ running on your puppet master server. Now on to apache and cobbler 


    
    <code>puppet parser validate /etc/puppet/manifests/site.pp</code>
