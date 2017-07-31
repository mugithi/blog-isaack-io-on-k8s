---
layout: post
title: "Converting a Docker Machine node to a Jenkins Slave "
excerpt: "In this blog I will describe how I configured a Docker Machine host to be a Jenkins Slave..."
categories: [CICD, Jenkins, Docker Machine, Groovy]
---

### Jenkins Slave.

Jenkins Slaves allow you run your builds in a distributed Jenkins deployment.  When you setup Jenkins, you have the ability to set buid executioners in the Jenkins Master, but in my configuration I run Jenkins as a docker container. I want to keep the Master nice and clean and so I zero out build executioners in the master and I use virtual machines as dedicated build slaves.

I love Docker Machine. It lets me easily provision Docker Machine instances into to my AWS VPCs and my Openstack environments. Docker Machine's beauty is its ease of configuring Docker TLS and SSH certificatates that my docker client can use to securely talk to Docker Machine provisioned nodes. Unfortunatly Docker Machine was not intended to be used for large scale deployments, as of Dec 2016 anyway. You still need to manually change your enviromental variables in order to use different Docker Machine environemnts. Another consequence of using Docker Machine is that the TLS and SSH certificates are tied to the client machine that you used to provision the Docker Machine instances.  

In this blog I will describe the procedure I use to convert my Docker Machine nodes into Jenkin slaves once I provision an AWS EC2 instance or Openstack Instance with Docker Machine. You will notice that this is still a very manual process that I am yet to automate (another blog post), but for now, I will describe the manual process.

#### Adding a Jenkins Slave

Jenkins has a built-in SSH client implementation that it can use to talk to remote sshd and start a slave agent. This is the most convenient and preferred method for Unix slaves, which normally has sshd out-of-the-box. 

In this [blog](http://blog.isaack.io/articles/2016-06/docker-swarm-on-openstack) I describe how Docker Machine works. When you use Docker Machine to provision an Docker Machine host, the certificates and keys are stored in the Docker Machine directory. I typically use Docker Machine on my mac and the cerfificates can be found under the path ```~/.docker/```. 

<script src="https://gist.github.com/mugithi/2c359b86a25eacd3a90386bddbf8f302.js"></script>

To configure my Docker Machine nodes you just need to move the ssh certificates to the jenkins-master so that they can be used to provision containers in the docker Slave using the docker client in the master server.

#### Create Credentials for Jenkins Slave and Jenkins Slave
- Create Jenkins Slave (Docker Machine) credentials using the ssh certificate from the ```id_rsa``` file created when you issued the Docker Machine Command . 
-  Navigate to the path ```http://jenkins/credentials/store/system/domain/_/newCredentials``` and fill in hte following information
	- login username
	- ssh key from ```id_rsa``` file
	- description (name) of the node

![](http://i.imgur.com/43Mwjor.png)

-  Navigate to path ```http://jenkins.isaack.io/computer/new``` to create a parmanent node and provide the following information
	- name of the jenkins slave
	- Number of executioners
	- root directory of ssh 
	- Set the Launch method as Unix Machines via SSH
	- Specificy the host name and the ssh keys that you created in step 

![](http://i.imgur.com/Tj5678l.png)


#### A note about Labels (Jenkins tagging)

-  When creating nodes, you have the option of setting the following options.
	- jenkins slave label
	- Specify only the build jobs that match the lable to be executed. 

- When you set this options, this allows you to tag the node for only specific jobs eg, production, staging as described in this [jenkinsfile] (https://gist.githubusercontent.com/mugithi/a81d2a9ed4a45fc119fd58470a519b27/raw/17c85a93751a371144e2909a26b26979b2c0e69b/Jenkinsfile). This is extremely usefull when you are buding a multi-pipeline job

