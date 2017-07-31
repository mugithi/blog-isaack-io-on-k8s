---
author: mugithi
comments: true
date: 2013-05-09 21:54:44+00:00
layout: post
#link: https://fvtool.wordpress.com/2013/05/09/installing-fedora-18-on-ucs-blades/
slug: installing-fedora-18-on-ucs-blades
title: Installing Fedora 18 on UCS blades
wordpress_id: 265
tags:
- B200
- F17
- F18
- Fedora 17
- Fedora 18
- ucs
---

Fedora 18 has an issue with picking up Video Display. In F18 kernels the display mode is set to CONFIG_DRM_MGA200=m and there seems to be a problem with that particular module. CONFIG_DRM_MGA200=m is not set in F17. So F17 is able to pick up the display but for F18 it is a hit or miss depending on the particular card/machine you have. For UCS blades, it is a miss.

**Symptoms**

Once you Connect UCS KVM to the ISO and after you select install,  the screen blanks and then auto-powers down during the boot process.

> Fixed by removing quiet adding the line nomodeset in the grub boot options

Both Fedora 17/18 do not do a good job of seeing the UCS virtualized hardware. I found that during the install both OSes dropped the CD and were unable to complete the install.

**Symptoms**

dracut Warning: /dev/disk/by-label/... does not exist

When the install fails, Fedora drops you to dracut. You can verify your CDROM is /dev/sr0 by issuing the following commands


    
    <code>dracut# ls -l /dev/sr0
    dracut# blkid /dev/sr0
    dracut# ls -l /run/initramfs/livedev
    dracut# ls -l /run/initramfs/live</code>



> Fixed by adding the line root=live:/dev/sr0


**Complete grub boot options
**


    
    <code>> vmlinuz initrd=initrd.img nomodeset root=live:/dev/sr0</code>
