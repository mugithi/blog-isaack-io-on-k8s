---
author: mugithi
comments: true
date: 2012-02-05 05:10:03+00:00
layout: post
#link: https://fvtool.wordpress.com/2012/02/05/purestorage/
slug: purestorage
title: PureStorage
wordpress_id: 34
tags:
- 3PAR
- PureStorage
---

I am reading up on 3Par and I took a detour to read up a bit on PureStorage SSD arrays. Both of this storage architectures are what we call "modern" as opposed to EMC, HDS or Netapp architectures. There are a couple of things I think PureStorage is doing that cannot be said of any other vendor I have seen.





  1. Stateless Controller. The NVRAM is in the same enclosure as the SSDs. This means if you have a failure of the controller, you can just swap it same as what you have on the UCS blades.. Very cool



  2. Raid 3D. From the talk I heard from John Colgrove, it does a combination of Raid 5 and Parity on Raid 5. Same as the 3PAR kinda like chunklets. One example he gave was taking three Raid 5 raid chunklet  and protecting them with a chunklet for parity. The extra chunks for parity can be changed on the fly as data is written; based on disk age, bit errors on disk and space availability. Also something I found to be really cool, is that this additional parity can be added or removed after the fact after the data is written to disk; removed say to free space or added to increase the data protection the system determines a higher level or bit errors coming form a cell in disk.



  3. Inflight duplication. They duplicate at the 512MB granularity. They then compress the deduplicated data. This happened as the data is still sitting on the NVRAM. They also use the NVRAM to calculate parity on reads just so as not to mess with the write order that would reduce the write performance. The system really uses a lot of RAM. The duplication they are using sound like something I have seen on the DataDomain. 


One other cool thing. They are using [MLC SSD](http://en.wikipedia.org/wiki/Multi-level_cell)s, I wonder how fast the array would perform with SLC SSDs.

Some really interesting stuff coming out of their Mountain View offices. I believe our company has a couple of deals already in the pipeline. 

I will delve more into their technology later once I get my hands on one of their arrays.
