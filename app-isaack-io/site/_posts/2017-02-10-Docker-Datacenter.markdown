---
layout: post
title: "Docker Datacenter"
excerpt: "Docker Datacenter was released in Feb 06. Relatively new product. From the features that I see it has, in a couple of years it could become VMware.. "
categories: [Salt,Ansible,Configuration Management]
---

#Deploying Docker Datacenter

Docker Datacenter was released in Feb 06. Relatively new product. From the features that I see it has, in a couple of years it could become VMware, that is if the company is not bought out. Docker Datacenter allows Enterprise's need to deploy containers in production easily and more palatable without compromising features requested by Enterprise.  In today's Enterprise world, I see alot of companies trying to do it themselves - trying to roll out Kubernetes, but what I have seen is that the containers requires a substancial tooling on the traditional operators. The container intiatives are mostly driven by developer requirements. I have been to several large shops where the folks in charge of the infrustructure have no desire to learn code as anything. In my assessment Docker has made Docker Datacenter so dirt simple that it allows the  operators to keep on doing their VMware thing while still allowing the developers with the smart stuff. The product still does not comparomise on the promise of DevOps toolchain.

###A little about Docker Datacenter.

In docker 1.12 Docker Introduced docker Swarm mode. When running docker in Swarm Mode, Docker in Swarm mode provides 99% of what you get with Kubernetes or Mesos just without all the pluggablility you get with k8s and Mesos. It becomes all grown up. In previous posts, I have written how I got overlay networks working and how much effort it to took to install Consul or Zooker external KV stores and intergrate them with Swarm so that you can run overlay networks. In Swarm Mode you dont need that, that is now all built in.

One other very cool thing that was introduced was the concept of docker service. This has been a tier one feature in K8s and in Mesos for a while. Docker only got it in 1.12 when running in Swarm Mode. This would have been nice on its own, but Docker has maintained backwards compatbaliity with the older like docker commands docker. With Docker Service you can leverage the built in load balancer(more on this later)


###Here are the features
**Orchestration & applications**

* Built in docker 1.12 orchestration
* Desired state with docker service
* backwards compatbility with docker run
* HTTP routing mesh - very cool. I will do another blog on how that works
* Expanded storage support with v3 files

**End to End security**

* Intergrated Notary installation and High evaaibaliyt
* Layered image signing and runtime enforcement policy
* Improved access control


**User Experience**

* Refreshed GUI
* Node managment
* GC performance enhancement
* Container health check
* Tag and metadate activity streams
* Installation flags


![]({{ site.url }}/img/Screen-Shot-2017-02-10-at-9.13.27-AM.png)

##Architecture

UCP managers get deployed. The number of UCP managers you can deploy are 1,3 or 7 depending on the number of failures you are willing to tolerate. The UCP managers contain the internal distributed store of the cluster. From description, it looks like UCP is analogous to Swarm managers in the opensource version of the product.

The UCP managers or Swarm Manager talk to UCP workers which would be the docker engine machines that actually run the application. Communication between the UCP Manager and UCP workers is encrypted by default using TLS with rotated keys. The manager has is own built in certificate manager. You can also use your own certicate which can be added on at the GUI after install of the cluster.



**What does UCP provide in addition to Docker Swarm Open Source**

* Support for 1.x and Docker Swarm Mode. ie you can run docker service command on your existing swarm deployment
* Provides a CLI and API support
* Provides a point and click UI for managment
* Provides secure access control to LDAP/AP and granular RBAC
* Provides Content Security and image signning using Notary


Docker Trusted registry is also deployed as part of DCC. You can deploy multiple instances of the docker that provide image resitry and storage mangement. You can bring your own load balancer.  

![]({{ site.url }}/img/Screen-Shot-2017-02-10-at-12.00.51-PM.png)

Docker engine 1.12 has built in scheduling for storage and networking. To install this you can just start with swarm 1.2 and layer on UCP or you can just start with UCP which will layer on the cluster for you.

Docker 1.12 introduced the concenpt of the routing Mesh. Generally what it seeks to accompish is to reduce complexity on the network.

####Port based routing Mesh
With docker 1.12, once you deploy the application to worker nodes, all the worker nodes that are part of a docker serivce will respond back with the application port regardless of whether they are running the container or not. This is accomplished by running an overlay network between the nodes. I will pubish another blog on docker container networking.

![]({{ site.url }}/img/Screen-Shot-2017-02-10-at-12.40.34-PM.png)

####HTTP routing Mesh

To accomplish host based routing (DNS routing) you would leverage an external load balancer that would route specific DNS names to specific ports in the cluster. You would use tags to tag your application with the specific hostname.

[Blog post on docker networking](https://success.docker.com/KBase/Docker_Reference_Architecture%3A_Universal_Control_Plane_2.0_Service_Discovery_and_Load_Balancing)

##Docker Service

Finally, docker has Service concept, they are finnaly grown up. You get to declare a state and have it enforced by UCP. Any changes being made are made at the container service.

![]({{ site.url }}/img/Screen-Shot-2017-02-10-at-12.54.50-PM.png)


##Security
Security is a very important in Docker and it is very easy to get wrong. I know this becuase I was one of those folks who checked in my secrets in Github in a repo I opensourced. In about 2 hours, my AWS secrets had racked up 6000 dollars in my AWS charges in my personal account. Instances were being used to mine bitcoin i believe. Apparently this is very common and fortunately AWS was kind enough to reverse the charges and wagging their finger let me know what to do to prevent this happening in the future.


#### Role based access
- Can tag containers and sepcify RBAC controls for Networks and Containers
- New 1.12, by default Networks/VOlumes/Containers are hidden to non admins by default

#### Image signing

- Can enforce signature signing by speficic users or goups and keep non-signed containers from being run
- Automatically setup notary

###Secrets 

Secrets best practices
- Keep secrets them away from our code (you should be able to refactor your code without having to change secrets)
- Keep secrets away from our source repository (clearly you know why)
- As an app moves from Dev/Test/Staging, it should access different secrets but access them in the same way
- Secrets should be encrypted at rest and in transit and only delivered to authorized applications
- This applies specifically to containers, Secrets should only be avaibalae in memory but never saved on disk in a container. 

Docker has built in secrets managmenet and this is how it is implemented. Having it built in keeps it portable accross whether you use DDC in AWS, Openstack, VMware or Azure. It is highly portable. 

- Secrets stored on disk encrypted
- Each docker worker-worker worker-master master-master communication is over TLS encrypted channel
- Secrets will only delivered to the hosts running the worker nodes running container that needs them. No worker nodes have access to all the secrets. Only the master nodes have access to all the secrets.
- For keys that are used for external communication eg Github
- To grant secret access to containers, Docker mounts a in memory file system to the container. This servers two purproses
	- Legacy applications still have access to secrets
	- No secrets get stored to the container file system
	
	
- The really cool part is that you can that secret management can be used with docker-compose. The use case is that in development, you would use temporary secrets in development and get to production use production secrets.


It is also priced similar to VMware. This is $1500 Business day (9-6pm) or $3000 Critical Support (24/7). Each node is a max of 2 CPU
