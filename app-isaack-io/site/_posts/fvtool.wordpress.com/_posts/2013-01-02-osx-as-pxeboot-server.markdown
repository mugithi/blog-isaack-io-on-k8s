---
author: mugithi
comments: true
date: 2013-01-02 08:41:36+00:00
layout: post
#link: https://fvtool.wordpress.com/2013/01/02/osx-as-pxeboot-server/
slug: osx-as-pxeboot-server
title: OSX as PXEboot server
wordpress_id: 78
categories:
- http.conf
- osx
- pxeboot
- vhosts.conf
tags:
- apache
- http.conf
- osx
- port based
- pxeboot
- pxelinux.0
- vhosts.conf
---

I have found myself doing a lot of Linux installs recently. I had to install a 10 node Rocks HPC cluster three weeks ago and this week I am working on a 20 node Eucalyptus cluster. In my quest to reduce time to install OS, I decided to install a PXE boot server. Now my primary laptop is a 15" mac book pro with SSD, a very fast machine that I am pleased with. I run Parrells so it would have been a fairly trivial to quickly put together a CentOS (my favorite OS second to OSX) VM and used that to be my PXE boot server. But Since OSX is based off unix and has everything to put together a PXE boot server, I decided to use that instead.

Now, since 2009, Apple has been dumbing down the capabilities of OSX and recently launched a separate package that can be installed on top of OSX to give you GUI access to the tools that I was using.  To put together a PXE boot server, i needed the following items in place.



	
  1. DHCP server

	
  2. TFTP boot server

	
  3. HTTP server

	
  4. OS ISOs etc etc





# DHCP server.


Now this is fairly easy. If you have an external DHCP server, TFTP will listen to that server for its configuration. I install my machines in closed environments that do not tie to the outside world so I needed a DHCP server. OSX has a built in DHCP server that can be configured by making changes to this file.


    
    <code>
    /usr/local/etc/dhcpd.conf</code>



In this file, you need to put in your IP subnet, and ip address range that you want to lease out. I also needed to specify the interface that would be used to lease out the IP addresses,  OSX uses en0, en1, enx for the ethernet interfaces. I had to set my ip interface en0 to a static IP which can be done from the  system preferences


    
    <code>
    en0: flags=8963; mtu 1500
     options=2b;
     ether 10:9a:dd:6e:b1:4e 
     inet6 fe80::129a:ddff:fe6e:b14e%en0 prefixlen 64 scopeid 0x5 
     inet <span style="color:#ff6600;">10.10.1.1</span> netmask 0xffff0000 broadcast 10.10.255.255
     media: autoselect</code>





    
    <code>
    → cat /usr/local/etc/dhcpd.conf #
    # PXE Configuration
    default-lease-time 600;
    max-lease-time 7200;
    subnet 10.10.0.0 netmask 255.255.0.0 {
    range 10.10.1.2 10.10.1.10; option routers 10.10.1.1;  
    option domain-name-servers 8.8.8.8, 8.8.4.4; 
    filename "<span style="color:#ff6600;">pxelinux.0</span>"; }</code>



In the DHCP config file, I have specified that 10.10.1.1(en0) is my router IP , I am leasing out IP addresses from 10.10.1.2-10.10.1.10

To start the DHCP server, you need to run the following command


    
    <code>
    sudo /usr/local/sbin/dhcpd -f -d -cf /usr/local/etc/dhcpd.conf</code>



Also in the dhcp file, you would also have to to specify location of the pxelinux.0 file. this will be the absolute path from the root of the TFTP server. More on this on the section below



# TFTP Boot server



The second piece of the puzzle is the TFTP boot server. Changes are made by modifying this file.


    
    <code>
    sudo vi /System/Library/LaunchDaemons/tftp.plist</code>



The first thing you need is to enable the TFTP boot server. You can use VI or nano to edit the file and change


    
    <code>
    <key>Disabled</key>
    <true/></code>



to

    
    <code>
    <key>Disabled</key>
    <false/></code>



You also need to specify the location of your root TFTP folder that you will be dropping a couple of files and this is specified in this section


    
    <code>
    <string>/usr/libexec/tftpd</string>
    		<string>-s&lt/string>
    		<string><font color="#FF0000">/Users/mymac/Downloads/install</font><strong></strong>/</string></code>




To start the TFTP server, you run the following command

    
    <code>
    sudo launchctl load -F /System/Library/LaunchDaemons/tftp.plist</code>



and to stop it


    
    <code>
    sudo launchctl unload -F /System/Library/LaunchDaemons/tftp.plist</code>



Under the path


    
    <code>
    /Users/mymac/Downloads/install/</code>



we will be dropping a couple of files that we will use to setup the PXE boot environment. You get some of this files from your linux distribution, in my case CentOS DVD, and from syslinux.

I created the following directory structure under the path and populated it with the directory structure and files below

    
    <code>
    /Users/mymac/Downloads/install/
    -> Centos6.3/
    -> Centos6.3/initrd.img
    -> Centos6.3/vmlinuz
    -> pxelinux.cfg/
    -> pxelinux.cfg/default
    -> menu.msg
    -> pxelinux.0</code>



The files Initrd.img and vmlinuz files can be obtained from your linux distribution. You are supposed to use a version as close to the version you are trying to deploy. I was deploying CentOS 6.3 and I found that I had the greatest success usings the versions under the [CentOS 6.3 distro](http://mirrors.arpnetworks.com/CentOS/6.3/os/x86_64/images/pxeboot/)

The file menu.msg is used to display an announcement. You can put in any text you want in there. This is what I had in mine


    
    <code>
    ########IT FREAKING WORKS ####################
    ########Centos 6.3 Installing#################
    ##############################################
    </code>



The file pxelinux.0 is the lightweight boot loader that kicks off the PXE boot process. I obtained this from [SYSLINUX](http://www.kernel.org/pub/linux/utils/boot/syslinux/) org and only had success with version 4.06. Version 5.x seems to have a bug

Most of the PXEboot configuration was contained in file pxelinux.cfg/default.


    
    <code>
    → cat default 
    PROMPT 1
    TIMEOUT 2
    DISPLAY menu.msg
    DEFAULT Centos6
    LABEL linux
     localboot 0
    LABEL Centos6
     MENU LABEL CentOS 6 x86_64 KS
     kernel Centos6.3/vmlinuz
     append initrd=Centos6.3/initrd.img ramdisk_size=100 ksdevice=eth0 <strong><font color="#FF0000">ks=http://10.10.1.1:81/Centos6.3.ks</font></strong>
    </code>



I had a very simple configuration, my default file had specifed my pxeboot options. Each Label in my case Label Linux and Label Centos6 represented one pxeboot boot option. The linux option was booting from local disk disk. I configured the  Centos6 as the default boot option. CentOS 6 was configured to load the kernel vmlinuz and pointed to a kickstart file I was serving using http on the IP address 10.10.1.1. This was the ip address of my web server running on OSX.



# OSX Web server


OSX uses apache no surprise there. Again apple has taken away the Gui niceties since Leopard. I wanted to serve up the CentOS 6.3 repo and the Kickstart file using HTTP. To do this I used Apache port separation to separate my HTTP sessions. HTTP is controlled by making modifications to this files.


    
    <code>
    sudo vi /etc/apache2/httpd.conf</code>



In this file, i allowed for the use of virtual hosts by uncommenting this line


    
    <code>
    Include /private/etc/apache2/extra/httpd-vhosts.conf</code>



Now alittle explanation on virtual hosts. Apache gives you the choice of name based or port based virtual web servers.Virtual web servers allow you to have different sites being served from the same web servers. I found port virtual hosts gave me much more flexibility for what I was trying to do. This are controlled by httpd-vhosts.conf file. I edited the file and added the following snippet a the bottom of the file; this pointed the  location of my kickstart folder to port 81.


    
    <code>
    sudo vi /private/etc/apache2/extra/httpd-vhosts.conf</code>




    
    <code>&ltVirtualHost *:81&gt
        DocumentRoot "/Users/mymac/Sites/ks"
        ServerName ks
    &ltVirtualHost&gt</code>



I then restarted apache using the following command.


    
    <code>
    sudo apachectl gracefull</code>



Inside the folder /Users/mymac/Sites/ks I had the following items.




	
  1. /Users/mymac/Sites/ks/Centos6.3.ks kickstart file referenced by my pxeboot/default file and

	
  2. /Users/mymac/Sites/ks/x86_64 that contained files from my distro which I pulled a CentOS 6.3 DVD iso Image




One more thing



#  KICKSTART file


I created the following kickstart file. 


    
    <code>
    → cat /Users/mymac/Sites/ks/Centos6.3.ks 
    install
    <strong><font color="#FF0000">url --url http://10.10.1.1:81/x86_64/</font></strong>
    lang en_US.UTF-8
    keyboard us
    timezone --utc America/Los_Angeles
    network --noipv6 --onboot=yes --bootproto dhcp
    authconfig --enableshadow --enablemd5
    rootpw --plaintext CHANGEME
    firewall --enabled --port 22:tcp
    selinux --disabled
    bootloader --location=mbr --driveorder=sda --append="crashkernel=auth rhgb"
    
    # Disk Partitioning
    clearpart --all --initlabel --drives=sda
    part /boot --fstype=ext4 --size=200 #create boot of size 200MB
    part pv.1 --grow --size=1
    volgroup vg1 --pesize=4096 pv.1
    
    logvol / --fstype=ext4 --name=lv001 --vgname=vg1 --size=6000 
    logvol /var --fstype=ext4 --name=lv002 --vgname=vg1 --grow --size=1 #create var rest of drive
    logvol swap --name=lv003 --vgname=vg1 --size=2048 #create swap size 2G
    # END of Disk Partitioning
    
    # Make sure we reboot into the new system when we are finished
    reboot
    
    # Package Selection
    %packages --nobase --excludedocs
    @core
    -*firmware
    -iscsi*
    -b43-openfwwf
    kernel-firmware
    -efibootmgr
    wget
    sudo
    perl
    ntp
    
    %pre
    
    %post --log=/root/install-post.log
    (
    PATH=/bin:/sbin:/usr/sbin:/usr/sbin
    export PATH
    
    # PLACE YOUR POST DIRECTIVES HERE
    ) 2>&1 >/root/install-post-sh.log
    EOF
    </code>



You can create your own custom custom configuration, but the most important bit was to point to the location of the distro files that you will be installing. I was using a web server so my configuration had the line highlighted in red that pointed it to the location being served by my http server. Notice the port 81 in the url.



# Putting it all together



I launched the dhcp server using the command


    
    <code>
    sudo /usr/local/sbin/dhcpd -f -d -cf /usr/local/etc/dhcpd.conf</code>



It runs actively on terminal and you can see whether you are actually leasing out ip address. I hope this helps out someone out there.
