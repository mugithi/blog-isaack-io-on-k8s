---
author: mugithi
comments: true
date: 2013-04-15 07:03:14+00:00
layout: post
#link: https://fvtool.wordpress.com/2013/04/15/c7000-bl465c-on-centos-5-2-part-2-update-nic-driver-in-initrd-image/
slug: c7000-bl465c-on-centos-5-2-part-2-update-nic-driver-in-initrd-image
title: C7000 BL465c on Centos 5.2 Part 2 (UPDATE NIC DRIVER IN INITRD IMAGE)
wordpress_id: 200
categories:
- OS Install
---

Prerequisites

You need the kernel module for the NIC (bnx2x.ko). 
This can be extracted from the driver rpm using the following command:


    
    <code>#rpm2cpio kmod-hp-netxtreme2-.i686.rpm | cpio -ivd</code>



Module gets placed here (relaltive to the directory the rpm was expanded in)


    
    <code>#lib/modules/2.6.18-128.el5/extra/hp-netxtreme2/bnx2x.ko</code>



Extract original initrd.img (the one you would like to add the driver to)
to a working directory


    
    <code>#mkdir /tmp/initrd
    #cd /tmp/initrd
    #gzip -dc  | cpio -ivd</code>




The modules are in another archive called modules.cgz in the modules directory
of the initrd


    
    <code>#cd /tmp/initrd/modules
    #gzip -dc modules.cgz | cpio -ivd</code>



Copy the kernel module you extracted from the driver rpm to the directory
structure of the modules.cgz you just extracted


    
    <code>#cd /tmp/initrd/modules
    #cp  2.6.18-128.el5/i686/ (this will overwrite the old one)
    </code>



Next, update the modules.alias file with the proper lines referencing the hardware IDs


    
    <code>#modinfo -F alias 2.6.18-128.el5/i686/bnx2x.ko | sed -e 's/^/alias /' -e 's/$/ bnx2x/' >> modules.alias
    </code>



Rebuild the modules.cgz archive


    
    <code>#cd /tmp/initrd/modules
    #find 2.6.18-128.el5 | cpio -o -H crc | gzip -9 > modules.cgz
    #rm -rf 2.6.18-128.el5
    </code>



Rebuild the initrd.img


    
    <code>#cd /tmp/initrd
    # find . | cpio -o -H newc | gzip -9 > /tmp/initrd-new.img
    </code>



Done
