---
author: mugithi
comments: true
date: 2013-05-14 08:28:08+00:00
layout: post
#link: https://fvtool.wordpress.com/2013/05/14/ciscos-play-in-the-cloud-ciac-vs-ciuc/
slug: ciscos-play-in-the-cloud-ciac-vs-ciuc
title: Cisco's Play in the Cloud ( CIAC vs CIUC)
wordpress_id: 280
categories:
- Cloud
tags:
- CIAC
- Cisco Intelligent Automation
- Cloudpia
- UCIS
---

CUIC or Cloudpia, the company that Cisco acquired last year is one of the options Cisco has you to serve up their hardware (UCS Compute, Nexus Switching + {EMC, Netapp}Storage). The there other option is CIA or Cisco Inteligent Automation (love the acronym) .. Well it is actually CIAC :-( Cisco Intelligent Cutomation for Cloud

So why would Cisco go and acquire a product that on deeper inspection has quite a bit of feature overlap with their existing product? CIAC is composed of Cisco Cloud Portal (previously newScale RequestCenter), Cisco Process Orchestrator (was previously Tidal Enterprise Orchestrator),Cisco Server Provisioner (OEM pie boot tool from LinMin) and Cisco Network Service Manager (Cisco Inhouse network policy tool). CIAC breaks down the hardware it manages (Compute, networking - no Storage) into PODs. The granularity of a POD is limited to a UCS chassis. In each POD, you can have one or more virtual Data Centers each VDC as its own networking configured as a VLAN. You can also use CIAC to manage a VCloud environment in which each VCloud vDC will become a CIAC VDC. CIAC can also manage openstack (Xen, KVM, HyperV) along with VCenter and EC2. 


So what about Cloudpia? I find that Cloudpia is a much more complete product. It has Orchestration engine similar to CIAC, Bear Metal provisioning and [all the other features](http://www.cloupia.com/en/cloud-computing-resources-technical-overview.htm) found in CIAC. In addition to that it has Chargback and also array integration for provioning from Netapp and EMC storage arrays. Out of the box it is a better product. In terms of customization CIAC is more flexible. The good thing is that CIAC can be layered on top of CUIC and leverage CIUC northbound APIs. For most users, I suspect that they will not need CIAC, but can use CUIC and have all the functionality that they need for 99% of what they want to achieve.


**EDIT**
Since I posted this, Cisco went and renamed Cloudipa/Cisco CUIC to [Cisco UCS Director](http://www.cisco.com/en/US/products/ps13050/index.html).

I have a customer who is interested in the HP version - HP Oneview. I will do another post that compares this two products in the near future
