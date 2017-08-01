---
author: mugithi
comments: true
date: 2013-01-09 00:58:11+00:00
layout: post
#link: https://fvtool.wordpress.com/2013/01/09/vnx-file-replication/
slug: vnx-file-replication
title: VNX File Replication part 1/2
wordpress_id: 180
categories:
- EMC VNX
tags:
- celerra
- data movers
- file storage
- ip replicator
- provision luns
- vnx
---

I was putting together a configuration for one of my customers. This were his requirements




	
  1. Replicate these filesystems and keep 31 daily snapshots (if 
possible).  The file systems were deduplicated at the source side. 


  2. Automatically delete daily snapshots 32 and older. 


  3. He had nested folders with thousands of #links under them.


  4. He needed a NFS target for his NFS target for his non-VNX data backups. This filesystem (NFS targets) did not need any snapshots as the backup software takes care of multiple copies. 




I decided to put the configuration together in my Demo Lab and generate the scripts I would be using to create replication sessions for my customer. Now, I only have one VNX so I had to figure out how to do replication. I had the choice of putting together a VNX simulator that is pretty much the full blown VNX File(Celerra) running in a VM. The second choice I had was to do replication between the two data movers in my VNX. The VNX comes with two Data Movers, one one active and one standby. 

To do this, I had  to convert my standby data mover into an active data mover. You can do this in the Unisphere but since I did not want to reduce the number of screenshots in this blog I will show you how to do it in CLI. SSH over to the VNX file. To promote the standby DM into an active DM, you need to do two things. The Data Movers have the names server_2 for Data Mover 2 and server_3 for Data Mover 3

	
  1. Deselect server_3 as the standby data mover
	
  2. Change the role of server_3 from an active to a active data mover.




    
    <code>[nasadmin@hq-vnx-cs0 ~]$ server_standby server_2 -delete mover=server_3
    server_2 : done
    [nasadmin@hq-vnx-cs0 ~]$ server_setup server_3 -type nas
    server_3 : reboot in progress 0.0.0.0.0.0.0.0.0.0.0.1.1.1.1.3.4.4. done 
    server_3 : checking root filesystem ... done 
    server_3 : verifying setup for Unicode fonts ... done 
    server_3 : updating local and remote systems configuration ...
    hq-vnx-cs0 : operation in progress (not interruptible)...
    id         = 0
    name       = hq-vnx-cs0
    owner      = 0
    device     = 
    channel    = 
    net_path   = 172.17.101.153
    celerra_id = APM001211039272007
    server_3 : configuring snmpd user...
     done 
    done
    </code>



I wanted to mirror his environment that Production volumes that have checkpoints and so I created a checkpoint schedule


    
    <code>[nasadmin@hq-vnx-cs0 ~]$ nas_fs -list
    id      inuse type acl   volume    name                server
    1         n    1   0     10        root_fs_1           
    2         y    1   0     40        root_fs_common      1,2
    3         n    5   0     73        root_fs_ufslog      
    5         n    5   0     93        root_fs_d3          
    6         n    5   0     94        root_fs_d4          
    7         n    5   0     95        root_fs_d5          
    8         n    5   0     96        root_fs_d6          
    9         y    1   0     12        root_fs_2           1
    13        y    1   0     14        root_fs_3           2
    17        n    5   0     108       delete_me           
    20        y    1   0     115       hq-vnx-vCD-NFS-IMAG 1
    <font color="#FF0000">21        y    1   0     119       DATA </font>               1
    23        n    5   0     121       root_panic_reserve</code>



Pulling information on the file system /DATA i got the following.   

I created a daily checkpoint schedule 


    
    <code>[nasadmin@hq-vnx-cs0 ~]$ nas_ckpt_schedule -create DATA_FS_CKPT_SCHED -filesystem DATA -recurrence once -start_on 2013-01-08 -runtimes 15:59 -cvfsname_prefix morning
    Error 13422428162: User is not allowed to perform this operation due to the snapsure license not being enabled.
    [nasadmin@hq-vnx-cs0 ~]$
    </code>



In Navisphere I noticed that in Unisphere Create File System Checkpoint was greyed out. I needed that enabled. 

![Screen Shot 2013 01 08 at 3 23 37 PM](http://fvtool.files.wordpress.com/2013/01/screen-shot-2013-01-08-at-3-23-37-pm.png)

It seemed that I needed to enable the Snapsure license, which I did and also enabled the replicatorv2 license that I would be using in the configuration.


    
    <code>[nasadmin@hq-vnx-cs0 ~]$ nas_license -list
    key                 status    value
    site_key            online    4f 69 1f 36
    cifs                online    
    nfs                 online    
    [nasadmin@hq-vnx-cs0 ~]$ nas_license -create snapsure
    done
    [nasadmin@hq-vnx-cs0 ~]$ nas_license -list
    key                 status    value
    site_key            online    4f 69 1f 36
    cifs                online    
    nfs                 online    
    snapsure            online    
    [nasadmin@hq-vnx-cs0 ~]$ nas_license -create replicatorV2 
    done
    [nasadmin@hq-vnx-cs0 ~]$ nas_license -list
    key                 status    value
    site_key            online    4f 69 1f 36
    cifs                online    
    nfs                 online    
    snapsure            online    
    replicatorV2        online    
    [nasadmin@hq-vnx-cs0 ~]$ </code>



I ran my schedule again and i got an OK


    
    <code>[nasadmin@hq-vnx-cs0 ~]$ nas_ckpt_schedule -create DATA_FS_CKPT_SCHED -filesystem DATA -recurrence once -start_on 2013-01-08 -runtimes 16:10 -cvfsname_prefix afternoon
    OK
    [nasadmin@hq-vnx-cs0 ~]$ nas_ckpt_schedule -list
       Id Name                 State      Next Run                       Description
        2 DATA_FS_CKPT_SCHED   Pending    Tue Jan 08 16:10:00 PST 2013  
    </code>



With this complete I could not setup replication between the two DataMovers. I was going to replicate the filesystem /DATA

First I checked the DataMover Interconnect over the loopback device existed. This is enabled by default. In the customers production system, I would be doing a 1:1 mapping of Prod Data Mover to DR Data Mover.


    
    <code>nas_cel -interconnect -list
    id     name               source_server   destination_system   destination_server
    20001  loopback           server_2        hq-vnx-cs0           server_2
    30001  loopback           server_3        hq-vnx-cs0           server_3
    </code>


I validated that the interconnects were ok by running the following command.

    
    <code>[nasadmin@hq-vnx-cs0 ~]$ nas_cel -interconnect -validate id=20001
    loopback: has 1 source and 1 destination interface(s); validating - please wait...ok
    [nasadmin@hq-vnx-cs0 ~]$ nas_cel -interconnect -validate id=30001
    loopback: has 1 source and 1 destination interface(s); validating - please wait...ok
    [nasadmin@hq-vnx-cs0 ~]$ </code>





Continued in Part 2
