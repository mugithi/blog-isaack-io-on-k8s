---
author: mugithi
comments: true
date: 2012-01-17 19:32:34+00:00
layout: post
#link: https://fvtool.wordpress.com/2012/01/17/hdiutil-some-of-the-reasons-i-love-using-a-mac/
slug: hdiutil-some-of-the-reasons-i-love-using-a-mac
title: hdiutil - Some of the reasons I love using a mac
wordpress_id: 18
---

create an iso image from disk



```
hdiutil create -srcdevice /dev/disk1 -format UDTO ~/Documents/VNX_Unified_infr_1
```



see cd status



```
drutil status
     Vendor   Product           Rev
     MATSHITA DVD-R   UJ-898    HE13

               Type: DVD-R                Name: /dev/disk1
           Sessions: 1                  Tracks: 1
       Overwritable:   00:00:00         blocks:        0 /   0.00MB /   0.00MiB
         Space Free:   00:00:00         blocks:        0 /   0.00MB /   0.00MiB
         Space Used:  260:16:48         blocks:  1171248 /   2.40GB /   2.23GiB
        Writability:
          Book Type: DVD-R (v5)
           Media ID: MCC 02RG20
```



force eject cdrom



```
hdiutil detach -force /dev/disk1
```



burn iso to dvd



```
hdiutil burn image.iso
```
