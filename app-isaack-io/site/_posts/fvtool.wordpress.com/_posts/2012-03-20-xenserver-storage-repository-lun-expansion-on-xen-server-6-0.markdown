---
author: mugithi
comments: true
date: 2012-03-20 04:36:38+00:00
layout: post
#link: https://fvtool.wordpress.com/2012/03/20/xenserver-storage-repository-lun-expansion-on-xen-server-6-0/
slug: xenserver-storage-repository-lun-expansion-on-xen-server-6-0
title: XenServer Storage Repository LUN Expansion on Xen Server 6.0
wordpress_id: 45
tags:
- 3PAR
- BL365 GI
- Boot From SAN
- brocade
- c7000
- F200
- HP VC FlexFabric 10Gb/24-Port Module
- multpathing
- XenCenter
- XenServer
---

So, this weekend I had to set up a customer demo that showed xenCenter/xenServer configuration running on a 3PAR array. I built the configuration on two BL365 G1 blades in a C7000 chassis and presented the storage to the nodes from our 3PAR F200 array. 

The C7000 chassis had 2 HP VC FlexFabric 10Gb/24-Port Modules with FC cables running to a Brocade 300 switch to the 3Par F200 array. Here is the list of items I had to do to get the blades to see the Fabric. I will not get into the details of each one of them but I will list them here and point out the ones that gave me problems.



  1. Configure Service Profiles on Onboard Administrator - Pretty straight forward


  2. Associate this profiles with my blades


  3. Picked the WWNs from the service profile and created zones in my Brocade switches so that the blades could see the front end(FE) ports of the array 


  4. Registered the host with in the array, configured 20GB LUNs and presented them to each of the blades - I used this as boot LUNs to host the XenOS. I also created a shared 80GB LUN to serve as my storage repository


  5. Install the XenServer 6.0 to the blades:I initially installed the OS on the local disks of the one of the blades. Soon after, I realized that my colleague had taken out the drives on the second blade. I then had to start all over again and reinstall the OS on the LUNs coming from the 3PAR. To enable the blades to boot from SAN I had to insert the WWNs of the 3PAR front end ports and specify which LUN to boot from on the service profile attached to the blades. Here is how the screenshot of one of the service profiles looks like. The highlighted WWNs belong to the front end ports from each of the storage processor, the same WWNs I zoned on the Brocade switch. I am booting off LUN 0

![FCOE BootFrom SAN](http://fvtool.files.wordpress.com/2012/03/fcoe-bootfrom-san2.png)

  6. I had to enable multpathing on the XenServers, I was quite surprised that this is not enabled by default





One of the things that was required of the demo, was to show LUN expansion. Now this is very easy to show in VMware, not so with XenServer. I spend quite a bit of time in Google and could not find anybody who had tested this in XenServer 6.0 and so I decided to write this post.






I first went to the 3Par and changed the LUN size from 80G to 100G. This did not reflect on my devices in multi path.





    
    <code>[root@admin-xen-10 ~]# mpathutil status
    350002ac000530dc0 dm-0  3PARdata,VV
    [size=80G][features=0       ][hwhandler=0        ][rw        ]
    \_ round-robin 0 [prio=0][enabled]
    \_ 0:0:0:1 sdb 8:16  [active][ready]
    \_ 1:0:0:1 sdd 8:48  [active][ready]
    </code>





I went ahead and looked for the UUID of the storage repository that I wanted to expand:




    
    <code>[root@admin-xen-10 ~]# xe sr-list name-label=3PAR-SR-01
    uuid ( RO)                : e9d516dd-566e-c9a8-90e9-a8d0fbb8547e
              name-label ( RW): 3PAR-SR-01
        name-description ( RW): Hardware HBA SR [3PARdata - /dev/sdd [sde]]
                    host ( RO): 
                    type ( RO): lvmohba
            content-type ( RO):
    </code>





I greped for the UUID in pvs.



    
    <code>
    [root@admin-xen-10 ~]# pvs | grep e9d516dd-566e-c9a8-90e9-a8d0fbb8547e
      Found duplicate PV sXrots07heg6mgWJtxIakeiOEui3bMOE: using /dev/sdc3 not /dev/sda3
      /dev/dm-0  VG_XenStorage-e9d516dd-566e-c9a8-90e9-a8d0fbb8547e lvm2 a-   79.99G 59.63G
    </code>





Rescan LUN using EMULEX HBAs to pick up the new changes.



    
    <code>[root@admin-xen-10 ~]# /usr/sbin/lpfc/lun_scan -r</code>





Multipathing had still not recognised the changes



    
    <code>[root@admin-xen-10 ~]# mpathutil status
    350002ac000530dc0 dm-0  3PARdata,VV
    [size=80G][features=0       ][hwhandler=0        ][rw        ]
    \_ round-robin 0 [prio=0][enabled]
    \_ 0:0:0:1 sdb 8:16  [active][ready]
    \_ 1:0:0:1 sdd 8:48  [active][ready]</code>





To get the multipath subsystem to recognize the change I used multipathd to resize the LUN using device id I got from the multi-path command above.




    
    <code>[root@admin-xen-10 ~]# multipathd -k"resize map 350002ac000530dc0"
    ok</code>





Multipath was now able to recognize changes to the size of the LUN. 



    
    <code>
    [root@admin-xen-10 ~]# mpathutil status
    350002ac000530dc0 dm-0  3PARdata,VV
    [size=100G][features=0       ][hwhandler=0        ][rw        ]
    \_ round-robin 0 [prio=0][enabled]
    \_ 0:0:0:1 sdb 8:16  [active][ready]
    \_ 1:0:0:1 sdd 8:48  [active][ready]
    </code>





And checking pvs, changes were also showing. 




    
    <code>[root@admin-xen-10 ~]# pvs | grep -i e9d516dd-566e-c9a8-90e9-a8d0fbb8547e
      Found duplicate PV sXrots07heg6mgWJtxIakeiOEui3bMOE: using /dev/sdc3 not /dev/sda3
      /dev/dm-0  VG_XenStorage-e9d516dd-566e-c9a8-90e9-a8d0fbb8547e lvm2 a-   99.99G 59.63G</code>





I then had to tell  XenCenter to check for new changes on the devices using this command.



    
    <code>[root@admin-xen-10 ~]# xe sr-scan uuid=e9d516dd-566e-c9a8-90e9-a8d0fbb8547e</code>



Using this steps, I was able to get XenCenter to do a live storage repository expansion while VMs were running on the server. Although I had a dual host pool, I ran all this commands on one host and at the end of it XenCenter was able to pick up the new changes. 

Now, it is possible to achieve the same by just rebooting the hosts, one at a time and after the last reboot, xencenter will pick up the changes. 

I hope this will help somebody out there.
