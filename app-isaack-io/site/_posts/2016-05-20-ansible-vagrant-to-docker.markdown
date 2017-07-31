---
layout: post
title: "ansible:vagrant to docker"
excerpt: "Migrating my ansible-vagrant configurations to docker packaging for the Openstack enviroment..."
categories: [Docker, Ansible, Vagrant]
---

###Inspiration

I work as a Cloud solutions architect in the San Francisco Bay Area. I recently worked with one of our Openstack vendors to put together an openstack reference offering. I also built an Openstack environment that allowed us to validate the components that went into the reference solution and also have an environment that provided our customers a sandbox environment to dip their toes on use of Openstack.

The environment was composed of Juniper physical switches, physical servers running Openstack and the ancillary environment. This blog entry focuses on how I built the anscillary environment and changes that I made to it using docker.

The ancillary enviroment was built for the following reasons.  

- To serve as documentation & registration site to the openstack deployment
- Alowed an on demand create & delete openstack tenants, Juniper SRX vpn and Netapp Solidfire users.

###Ansible and Vagrant
The I had initally provisioned the enviroment using Ansible & vagrant onto KVM hosts and this is how the environment initially looked like.
Code on  [github](https://github.com/mugithi/vagrant)

![](http://i.imgur.com/xF4DsNY.png)

###Move to docker
I later decided to refactor the application to make use containers. This gave me greater application portability and flexibility. I was now able to do more work on my location machine and provision to production. The final application looked like this

![](http://i.imgur.com/8t6x0Oh.png)

I the next entry, I will describe the docker compose file, will describe use of docker compose and how I used to to provision the environment.
