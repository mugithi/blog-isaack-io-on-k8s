---
author: mugithi
comments: true
date: 2013-01-18 01:13:43+00:00
layout: post
#link: https://fvtool.wordpress.com/2013/01/18/savvol-deduplication-snapsure-and-replication/
slug: savvol-deduplication-snapsure-and-replication
title: SavVol Deduplication, Snapsure and Replication
wordpress_id: 193
categories:
- EMC VNX
---

My customer had a question about the relationship between Checkpoints, Replication and Deduplication. EMC has done a good job of putting this information in their documenttation but it is spread out between the CLI guide, Snasure, Deduplication and Replication guides.

First, a PFS by default uses the same SavVol space for deduplication, snap sure checkpoints and for replication checkpoints.

EMC documentation does not describe SavVol Space is provisioned when enabling reduplication on a PFS, but it does a good job of stating what happens when   
By default SavVol has the following characteristics, (PFS means Primary File System - or base volume that has checkpoints on it)

From the VNX snapsure documentation, 
 
If PFS < 64 MB, then SavVol = 64 MB, which is the minimum SavVol  size
If (PFS  64 MB), then SavVol = PFS size.
PFS > 20 GB, then SavVol = 20 GB.
 
**CHECKPOINTS SAVVOL HIGHWATER MARK (HWM)**

SavVol by default is configured to autoextend when it reaches its high water mark. You can check this value by issuing the command fs_ckpt against a filesystem. I issued this command in my VNX and my HWM is 90% indicated by “fullmark” below.  My SavVol will autoextend when it gets to over 90% usage. This is the default value unless modified. This setting is modified using a command similar to this “fs_ckpt  -modify %full=” where  is the file system name and  is %HWM eg 90
 

    
    <code>[nasadmin@hq-vnx-cs0 ~]$ fs_ckpt DATA -list
    id    ckpt_name                creation_time           inuse fullmark   total_savvol_used  ckpt_usage_on_savvol
    25    ckpt_DATA_FS_CKPT_SCHED_ 01/08/2013-16:10:04-PST   y   90%        3%                 1%
    39    ckpt_DATA_daily_001      01/09/2013-19:45:01-PST   y   90%        3%                 1%
    Info 26306752329: The value of ckpt_usage_on_savvol for read-only checkpoints may not be consistent with the total_savvol_used.
    id    wckpt_name               inuse fullmark total_savvol_used  base  ckpt_usage_on_savvol</code>


 
**DEDUPE SAVVOL THRESHOLD**

By default, the system is configured to abort deduplication operations on a file system before it causes the SavVol to extend. This avoids the SavVol expanding due to deduplication activity. If the deduplication process is aborted in this way, an alert is generated that explains what happened.
 
The deduplication Savvol threshold is the percentage of the configured SavVol auto-extension HWM that can be used during deduplication. Right now it yours has been set to  90% of the SavVol HWM. We just set this today morning using the “fs_dedup - -savvol_threshold” command.  Dededuplication will stop when the SavVol reaches 81% full. Which would be SavVol dedupe threshold 90% of the checkpoint HWM of 90%
 
If deduplication stops because of it reaches 81% of configured SavVol, we several choices to make space available in the SavVol.
Delete checkpoints which would free up space in the SavVol and run deduplication in about a week
Manually extend SavVol and manually restart dedupelication
Use fs_dedup to change the SavVol Threshold setting to dedupe to allow SavVol to autoextend. We do this by making fs_dedup - -savvol_threshold=0. If SavVol grows unchecked, it could grow to a size equivalent to the PFS consuming disk space that cannot be reclaimed until all the checkpoints are deleted.
FINDING OUT VALUE OF SAVVOL
You find out the total SavVol being used by issuing the command nas_fs –info –size against a checkpoint
 

    
    <code>[nasadmin@hq-vnx-cs0 ~]$ nas_fs -info -size ckpt_DATA_daily_001
    id        = 39
    name      = ckpt_DATA_daily_001
    acl       = 0
    in_use    = True
    type      = ckpt
    worm      = off
    volume    = vp124
    pool      = DATA
    member_of =
    rw_servers=
    ro_servers= server_2
    rw_vdms   =
    ro_vdms   =
    checkpt_of= DATA Wed Jan  9 19:45:01 PST 2013
    deduplication   = Off
    thin_storage    = False
    tiering_policy  = Auto-Tier/Optimize Pool
    compressed= False
    mirrored  = False
    <font color="#FF0000">size      = volume: total = 20000 avail = 19487 used = 513 ( 3% ) (sizes in MB)  ß Size of SavVol is 20000MB     </font>           
    ckptfs: total = 50419 avail = 42949 used = 7469 ( 15% ) (sizes in MB) ( blockcount = 40960000 ) ckpt_usage_on_savvol: 128MB ( 1% )
    used      = 3%
    full(mark)= 90%
    stor_devs = APM00121103927-0010
    disks     = d9
    disk=d9    stor_dev=APM00121103927-0010 addr=c0t1l0         server=server_2
    disk=d9    stor_dev=APM00121103927-0010 addr=c16t1l0        server=server_2</code>


 
full(mark) is the checkpoint HWM set at 90%
 
SavVol size is given by the line in red
Size = volume: total 20GB with 513MB used which represents 97%(rounded off) of total capacity available for use in SavVol.
