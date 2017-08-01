---
author: mugithi
comments: true
date: 2013-01-10 03:42:35+00:00
layout: post
#link: https://fvtool.wordpress.com/2013/01/10/vnx-file-replication-part-22/
slug: vnx-file-replication-part-22
title: VNX File Replication part 2/2
wordpress_id: 186
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

In Part 1, I verified that the loopback interface was available. I did not want to create replication using the loopback interface that would replicate to the same DataMover DM2-->DM2, but I wanted to put replication from DM2->DM3. I had to configure the IP interfaces on DM3 to get them up to receive the data coming in.

    
    <code> ____________       ____________
    |	     |     |	     	|		
    |    DM2     | --> |	 DM3 	|
    |____________|     |____________| </code>




To create the interfaces in DM3, I first created a I first created a FailSafe Network interface on DataMover 3. A FailSafe interface allows failover from one interface to another. It does not have any load balancing between the two interfaces. Data flows through one interface until it fails.

![Create Network Device](http://fvtool.files.wordpress.com/2013/01/create-network-device.png)

I then created a virtual interface NAS-IP2 on the fail safe interface called FSN-1. 

![Create Network Interface](http://fvtool.files.wordpress.com/2013/01/create-network-interface.png)

To create an interconnect you first have to establish a trust relationship between the Control stations, but since I was using DMs in one VNX, I did not have to create the trust relationship. To create the interconnect, I first checked the name of the cell manager.


    
    <code>[nasadmin@hq-vnx-cs0 ~]$ nas_cel -l
    id    name          owner mount_dev  channel    net_path                                      CMU
    0     hq-vnx-cs0    0                           172.17.101.153                                APM001211039272007</code>



I used that name in the command to below to create the interconnect.


    
    <code>
    
    [nasadmin@hq-vnx-cs0 ~]$ nas_cel -interconnect -create InterConn-DM2--DM3 -source_server server_2 -destination_system hq-vnx-cs0 -destination_server server_3 -source_interfaces ip=172.17.105.90 -destination_interfaces ip=172.17.105.91
    operation in progress (not interruptible)...
    id                                 = 20003
    name                               = InterConn-DM2--DM3
    <font color="#FF0000">source_server                      = server_2
    source_interfaces                  = 172.17.105.90
    </font>destination_system                 = hq-vnx-cs0
    <font color="#FF0000">destination_server                 = server_3
    destination_interfaces             = 172.17.105.91</font>
    bandwidth schedule                 = uses available bandwidth
    crc enabled                        = yes
    number of configured replications  = 0
    number of replications in transfer = 0
    status                             = The interconnect is OK.</code>



For the interconnect to work properly, it requires a peer interface that connects back from the destination DataMover to the source DataMover. I used this commands to create the peer interconnect to enable replication from DM3 to DM2.


    
    <code>[nasadmin@hq-vnx-cs0 ~]$ nas_cel -interconnect -create InterConn-DM3--DM2 -source_server server_3 -destination_system hq-vnx-cs0 -destination_server server_2 -source_interfaces ip=172.17.105.91 -destination_interfaces ip=172.17.105.90
    operation in progress (not interruptible)...
    id                                 = 30003
    name                               = InterConn-DM3--DM2
    <font color="#FF0000">source_server                      = server_3
    source_interfaces                  = 172.17.105.91</font>
    destination_system                 = hq-vnx-cs0
    <font color="#FF0000">destination_server                 = server_2
    destination_interfaces             = 172.17.105.90</font>
    bandwidth schedule                 = uses available bandwidth
    crc enabled                        = yes
    number of configured replications  = 0
    number of replications in transfer = 0
    status                             = The interconnect is OK.</code>



I verified the interconnect.


    
    <code>[[nasadmin@hq-vnx-cs0 ~]$  nas_cel -interconnect -l
    id     name               source_server   destination_system   destination_server
    20001  loopback           server_2        hq-vnx-cs0           server_2
    <font color="#FF0000">20003  InterConn-DM2--DM3 server_2        hq-vnx-cs0           server_3</font>
    30001  loopback           server_3        hq-vnx-cs0           server_3
    <font color="#FF0000">30003  InterConn-DM3--DM2 server_3        hq-vnx-cs0           server_2</font></code>




    
    <code>[nasadmin@hq-vnx-cs0 ~]$ nas_cel -interconnect -validate id=20003
    InterConn-DM2--DM3: has 1 source and 1 destination interface(s); validating - please wait...ok
    [nasadmin@hq-vnx-cs0 ~]$ nas_cel -interconnect -validate id=30003
    InterConn-DM3--DM2: has 1 source and 1 destination interface(s); validating - please wait...ok
    </code>



If you do not create a peer interface and instead just have one interconnect replication in one direction, you will get an error that looks similar to this when you try and validate


    
    <code>[nasadmin@hq-vnx-cs0 ~]$ nas_cel -interconnect -validate id=20003
    InterConn-DM2--DM3: has 1 source and 1 destination interface(s); validating - please wait...failed</code>



I now had a new interconnects shown in RED. I needed now to create a storage pool to hold my replicated file systems. I would name that DATA_REP. To create a Storage pool, you have to do it in two steps. Provision LUNs from the VNX Fibre channel side to the Data Movers. Once the Volumes are available to the DataMover, you can now create the Storage Pool.

I started by first two LUNs called DATA-03-FILE and DATA-04-FILE. 

![Create LUNs](http://fvtool.files.wordpress.com/2013/01/create_luns.png)

I then added the two LUNs to the storage group ~filestorage. This is the LUN masking to the DataMover.

![Add to storage group](http://fvtool.files.wordpress.com/2013/01/add_to_storage_group.png)

I checked the devices that had been presented to the VNX file, I only had disk d8 and d9 currently presented. 


    
    <code>[nasadmin@hq-vnx-cs0 ~]$  nas_disk -list
    id   inuse  sizeMB    storageID-devID   type  name          servers
    1     y      11260  APM00121103927-2007 CLSTD root_disk     1,2
    2     y      11260  APM00121103927-2008 CLSTD root_ldisk    1,2
    3     y       2038  APM00121103927-2009 CLSTD d3            1,2
    4     y       2038  APM00121103927-200A CLSTD d4            1,2
    5     y       2044  APM00121103927-200B CLSTD d5            1,2
    6     y      65526  APM00121103927-200C CLSTD d6            1,2
    7     y       1023  APM00121103927-0000 MIXED d7            
    8     y      20479  APM00121103927-000F MIXED d8            1,2
    9     y     102399  APM00121103927-0010 MIXED d9            1,2</code>



I then ran the following command to have the DataMovers to rescan their HBAs to discover and save all SCSI devices.


    
    <code>[nasadmin@hq-vnx-cs0 ~]$ server_devconfig server_2 -create -scsi -all
    
    Discovering storage on hq-vnx-cs0 (may take several minutes)
    server_2 : done
    
    Info 26306752254: server_2 : APM00121103927 reassigned LUN 0017 in storage group '~filestorage' from host id 0006 to 0019
    
    Info 26306752254: server_2 : APM00121103927 reassigned LUN 0018 in storage group '~filestorage' from host id 0007 to 0018
    
    Warning 17717198868: server_2 : The FAST-POOL-0 on APM00121103927 storage pool contains disk volumes that use different data service configurations. Creating and extending file systems using this storage pool may cause performance inconsistency.
    [nasadmin@hq-vnx-cs0 ~]$ server_devconfig server_3 -create -scsi -all
    
    Discovering storage on hq-vnx-cs0 (may take several minutes)
    server_3 : done</code>



On rechecking the disks available to the data movers, I now saw that I now had two disks d10 and d11 of size 60GB each.


    
    <code>[nasadmin@hq-vnx-cs0 ~]$ nas_disk -list
    id   inuse  sizeMB    storageID-devID   type  name          servers
    1     y      11260  APM00121103927-2007 CLSTD root_disk     1,2
    2     y      11260  APM00121103927-2008 CLSTD root_ldisk    1,2
    3     y       2038  APM00121103927-2009 CLSTD d3            1,2
    4     y       2038  APM00121103927-200A CLSTD d4            1,2
    5     y       2044  APM00121103927-200B CLSTD d5            1,2
    6     y      65526  APM00121103927-200C CLSTD d6            1,2
    7     y       1023  APM00121103927-0000 MIXED d7            
    8     y      20479  APM00121103927-000F MIXED d8            1,2
    9     y     102399  APM00121103927-0010 MIXED d9            1,2
    10    n      61439  APM00121103927-0012 MIXED d10           1,2
    11    n      61439  APM00121103927-0011 MIXED d11           1,2</code>



I then created a Storage Pool to hold the replicated file system


    
    <code>[nasadmin@hq-vnx-cs0 ~]$ nas_pool -create -name DATA_REP -description 'Replication Destination' -volumes d10,d11 -default_slice_flag y
    id                   = 45
    name                 = DATA_REP
    description          = Replication Destination
    acl                  = 0
    in_use               = False
    clients              = 
    members              = d10,d11
    storage_system(s)    = APM00121103927
    default_slice_flag   = True
    is_user_defined      = True
    thin                 = False
    tiering_policy       = Auto-Tier/Optimize Pool
    compressed           = False
    mirrored             = False
    disk_type            = Mixed
    server_visibility    = server_2,server_3
    is_greedy            = False
    template_pool        = N/A
    num_stripe_members   = N/A
    stripe_size          = N/A</code>



I now had space to send my replicated data. It was a storage pool DATA_REP.  I now started the replication using the following commands.


    
    <code>[nasadmin@hq-vnx-cs0 ~]$ nas_replicate -create rep1 -source -fs DATA -destination -pool DATA_REP -interconnect InterConn-DM2--DM3 -max_time_out_of_sync 15
    OK
    </code>



And verified that replication was ok using the following commands


    
    <code>[nasadmin@hq-vnx-cs0 ~]$ nas_replicate -list
    Name                      Type       Local Mover               Interconnect         Celerra      Status
    rep1                      filesystem server_2-->server_3       InterConn-DM2--D+ hq-vnx-cs0   OK
    
    [nasadmin@hq-vnx-cs0 ~]$ nas_replicate -info rep1
    ID                             = 119_APM00121103927_2007_129_APM00121103927_2007
    Name                           = rep1
    Source Status                  = OK
    Network Status                 = OK
    Destination Status             = OK
    Last Sync Time                 = 
    Type                           = filesystem
    Celerra Network Server         = hq-vnx-cs0
    Dart Interconnect              = InterConn-DM2--DM3
    Peer Dart Interconnect         = InterConn-DM3--DM2
    Replication Role               = local
    Source Filesystem              = DATA
    Source Data Mover              = server_2
    Source Interface               = 172.17.105.90
    Source Control Port            = 0
    Source Current Data Port       = 50325
    Destination Filesystem         = DATA_replica1
    Destination Data Mover         = server_3
    Destination Interface          = 172.17.105.91
    Destination Control Port       = 5085
    Destination Data Port          = 8888
    Max Out of Sync Time (minutes) = 15
    Current Transfer Size (KB)     = 8461480
    Current Transfer Remain (KB)   = 8173480
    Estimated Completion Time      = Wed Jan 09 19:16:41 PST 2013
    Current Transfer is Full Copy  = Yes
    Current Transfer Rate (KB/s)   = 6022
    Current Read Rate (KB/s)       = 3407
    Current Write Rate (KB/s)      = 320
    Previous Transfer Rate (KB/s)  = 0
    </code>



As per the customer requirements, I setup daily recurring checkpoints on the source file system that would take place every day at 7:45pm keeping the last 20.


    
    <code>[nasadmin@hq-vnx-cs0 ~]$ nas_ckpt_schedule -create DATA_daily -filesystem DATA -recurrence daily -every 1 -start_on 2013-1-9 -end_on 2013-1-9 -runtimes 19:45 -keep 20 -cvfsname_prefix evening
    OK
    </code>



Running the file system list. I could now see that I had the primary file system checkpoint and the destination file system. The destination file system name was DATA_replica1.

    
    <code>[nasadmin@hq-vnx-cs0 ~]$ nas_fs -l
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
    21        y    1   0     119       DATA                1
    23        n    5   0     121       root_panic_reserve  
    25        y    7   0     124       ckpt_DATA_FS_CKPT_S 1
    <font color="#FF0000">34        y    1   0     129       DATA_replica1       2</font>  <---- Destination File system
    <font color="#FF0000">39        y    7   0     124       ckpt_DATA_daily_001 1</font>  <-----Source file system checkpoint
    </code>



I also created the checkpoints for the destination file system. And this is how the command looked like. 


    
    <code>[nasadmin@hq-vnx-cs0 ~]$ nas_ckpt_schedule -create <font color="#FF0000">DATA_replica_daily</font> -filesystem DATA_replica1 -recurrence daily -every 1 -start_on 2013-1-9 -end_on 2013-1-9 -runtimes 19:55 -keep 20 -cvfsname_prefix evening
    OK
    </code>



And this is how the file systems looked like with the Destination file system checkpoint. I would suggest that you take the checkpoint after the file system completed replicating so that you do not use up so much of the SavVol.


    
    <code>[nasadmin@hq-vnx-cs0 ~]$ nas_fs -l
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
    21        y    1   0     119       DATA                1
    23        n    5   0     121       root_panic_reserve  
    25        y    7   0     124       ckpt_DATA_FS_CKPT_S 1
    34        y    1   0     129       DATA_replica1       2
    39        y    7   0     124       ckpt_DATA_daily_001 1
    <font color="#FF0000">40        y    7   0     133       ckpt_DATA_replica_d 2</font></code>




I hope this helps out someone out there.
