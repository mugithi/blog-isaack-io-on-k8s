---
author: mugithi
comments: true
date: 2012-12-09 10:09:58+00:00
layout: post
#link: https://fvtool.wordpress.com/2012/12/09/issue-with-vcloud-http-nfc-error-cannot-deploy-package-from-optvmwarecloud-director/
slug: issue-with-vcloud-http-nfc-error-cannot-deploy-package-from-optvmwarecloud-director
title: Issue with VCLOUD "HTTP NFC Error. Cannot deploy package from /opt/vmware/cloud-director/
wordpress_id: 72
tags:
- Issues
- VCloud 5.1
- VCP
- VMware
---






So I had this problem today with the VCloud 5.1. I was building a 4 Node CentOS 6 Cluster  and when I tried to power on the VAPP, it got the message "failed to power on" I looked at the VCloud event log and found this cryptic message saying.

    
    "Unable to start vApp "CENTOS6-5NODE-CLUSTER".
     - HTTP NFC Error. Cannot deploy package from /opt/vmware/vcloud-director/guestcustomization/unix_deployment_package.tar.gz to 'NODE-2 (baef57c9-8e97-4a14-9447-d801ea2c050d)/unix_deployment_package.tar.gz'.
     - Cannot complete login due to an incorrect user name or password"


In VCenter I found this message in the event log "Cannot log into vslauser@172.17.100.90"


[![5cff49668689e968468265e2da25a9ea](http://fvtool.files.wordpress.com/2012/12/5cff49668689e968468265e2da25a9ea.png?w=300)](http://fvtool.wordpress.com/issue-with-vcloud-http-nfc-error-cannot-deploy-package-from-optvmwarecloud-director/5cff49668689e968468265e2da25a9ea/)








The 172.17.100.90 that was mentioned in the log was the IP of my VCloud Cell and from what I found in [google ](http://kb.vmware.com/selfservice/microsites/search.do?language=en_US&cmd=displayKC&externalId=2019551)it looked like VCloud was logging into the ESX hosts using the username vslauser and a randomly generated password that did not meet the minimum length password requirements on my ESX hosts.


I used this [KB article](http://kb.vmware.com/selfservice/microsites/search.do?language=en_US&cmd=displayKC&externalId=1012033) to fix lower my password requirements. Now this is my lab, if this was production, I would probably find a way increase the length of the radomly generated password.


ssh into the ESX Hosts

    
    chmod +t /etc/pam.d/system-auth
    password requisite    /lib/security/$ISA/pam_passwdqc.so retry=3 min=4,4,4,4,4


I then disabled my hosts,  unprepared and prepared them in VCloud and this fixed the problem


[![9657b03a202363c43719da31f489947f](http://fvtool.files.wordpress.com/2012/12/9657b03a202363c43719da31f489947f.png?w=300)](http://fvtool.wordpress.com/issue-with-vcloud-http-nfc-error-cannot-deploy-package-from-optvmwarecloud-director/9657b03a202363c43719da31f489947f/)



























