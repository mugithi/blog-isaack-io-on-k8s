---
author: mugithi
comments: true
date: 2012-02-01 06:15:17+00:00
layout: post
#link: https://fvtool.wordpress.com/2012/02/01/snmp-monitoring-on-brocade-switches/
slug: snmp-monitoring-on-brocade-switches
title: SNMP Monitoring of CPU and Memory on Brocade Switches
wordpress_id: 25
tags:
- Brocade Switches
---

It turns out there are MIBs provided by Brocade that you can use to monitor your switch performance. Compared to cisco, Brocade Switches have very low CPU utilization but here they are anyway

CPU or memory usage group 

1. The memory usage of a system indicates the system's RAM.

* swCpuUsage 	1.3.6.1.4.1.1588.2.1.1.1.26.1 
  
  



2. The system's CPU usage.   




* swCpuNoOfRetries 	1.3.6.1.4.1.1588.2.1.1.1.26.2 
  
  

3. The number of times the system should take a CPU utilization sample before sending the CPU utilization trap.   




* swCpuUsageLimit	 1.3.6.1.4.1.1588.2.1.1.1.26.3 
  
  

4. The CPU usage limit.   



* swCpuPollingInterval 1.3.6.1.4.1.1588.2.1.1.1.1 
  
  


To monitor this on your switch you need to have Fabric Watch licenses. 

Here is how it looks like. I used snmpwalk, an smnp utility that comes preinstalled in most nix systems.


    
    <code>
    $ $  snmpwalk -v 1 -c public 172.17.100.178   1.3.6.1.4.1.1588.2.1.1.1.26.1
    SNMPv2-SMI::enterprises.1588.2.1.1.1.26.1.0 = INTEGER: 1
    $  snmpwalk -v 1 -c public 172.17.100.178   1.3.6.1.4.1.1588.2.1.1.1.26.2
    SNMPv2-SMI::enterprises.1588.2.1.1.1.26.2.0 = INTEGER: 3
    $  snmpwalk -v 1 -c public 172.17.100.178   1.3.6.1.4.1.1588.2.1.1.1.26.3
    SNMPv2-SMI::enterprises.1588.2.1.1.1.26.3.0 = INTEGER: 75
    $  snmpwalk -v 1 -c public 172.17.100.178   1.3.6.1.4.1.1588.2.1.1.1.26.4
    SNMPv2-SMI::enterprises.1588.2.1.1.1.26.4.0 = INTEGER: 120</code>
