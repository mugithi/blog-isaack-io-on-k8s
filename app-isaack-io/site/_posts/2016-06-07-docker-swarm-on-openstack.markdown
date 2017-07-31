---
layout: post
title: "Docker Machine on Openstack"
excerpt: "You can use native docker tools to deploy containers onto openstack instances but it is much more easier to use docker-machineuse docker-machine. We will go through the procedure on how to deploy a swarm cluster on Openstack..."
categories: [Docker, Networking]
---

## Docker Machine on Openstack

You can use native docker tools to deploy containers onto openstack. One easy way to do this is to use docker-machine. Docker machine has a built in openstack driver that does the following things.

- Launch an openstack virtual instance. You can setup the following paramenters on the instance
	-  image source
	-  flavor
	-  network
	-  associate with floating ip
	-  creates ssh key per docker host if existing key is not selected (Please note, as of version 11.1, docker-machine deletes the openstack key on docker host delete even for existing keys)
- Install and configure docker-engine on the docker host to listen on port 2375 and configures TLS
- Can be used to install and configure swarm on a docker host instance icluding setting up TLS requirements (later in the post)
 - Can be used to delete the instances configured by issuing ```docker-machine rm <docker-host-name>```


Below are instructions on how to configure docker machine.

1. You first need to have the docker client installed in your [local machine](https://docs.docker.com/engine/installation/).

2. You also need to be have an Openstack tenant account, download your Openstack RC file and save it to your local machine.

3. Source the Openstack credentails from Openstack RC file. You can also just pass the credentials in plain text to ```docker-machine create``` but this is probably not a good idea.

	```bash

	~/Dropbox/Documentation/Python/SCRIPTS/CLEAN_SCRIPTS/MISC(branch:v1) » source admin_rc
	```

4. Using docker-machine, use the ubuntu image to deploy a docker host.

	```bash

	~/Dropbox/Documentation/Python/SCRIPTS/CLEAN_SCRIPTS/MISC(branch:v1*) » docker-machine create -d openstack \
	--openstack-flavor-id 3 \
	--openstack-image-name "Ubuntu 14.04" \
	--openstack-ssh-user ubuntu \
	--openstack-net-name fip_public \
	--openstack-sec-groups security_group_open docker-instance-01
	Running pre-create checks...
	Creating machine...
	(docker-instance-01) Creating machine...
	Waiting for machine to be running, this may take a few minutes...
	Detecting operating system of created instance...
	Waiting for SSH to be available...
	Detecting the provisioner...
	Provisioning with ubuntu(upstart)...
	Installing Docker...
	Copying certs to the local machine directory...
	Copying certs to the remote machine...
	Setting Docker configuration on the remote daemon...
	Checking connection to Docker...
	Docker is up and running!
	To see how to connect your Docker Client to the Docker Engine running on this virtual machine, run: docker-machine env docker-instance-01
	```

5. Simple as that. You can now issue the commands in your shell in order to connect your docker client to the remote docker-machine host

	```bash

	~/Dropbox/Documentation/Python/SCRIPTS/CLEAN_SCRIPTS/MISC(branch:v1) » docker-machine env docker-instance-01
	export DOCKER_TLS_VERIFY="1"
	export DOCKER_HOST="tcp://209.49.73.115:2376"
	export DOCKER_CERT_PATH="/Users/isaackkaranja/.docker/machine/machines/docker-instance-01"
	export DOCKER_MACHINE_NAME="docker-instance-01"
	# Run this command to configure your shell:
	# eval $(docker-machine env docker-instance-01)
	~/Dropbox/Documentation/Python/SCRIPTS/CLEAN_SCRIPTS/MISC(branch:v1) » eval $(docker-machine env docker-instance-01)
	```


## Docker swarm on Openstack

Swarm is native clustering and orchestration solutions. It uses the same started Docker APi that is used by docker-macihne and docker compose, giving it low barrier to entry. It allows you manage a cluster of hosts with the ease of managing one host. For example, instead of issuing ```docker run``` against one docker host, you issue ```docker run swarm``` against a cluster of hosts and swarm figures out the container placement in the cluster.

It a built in tocken based discovery service that can be swaped out for consul or etcd. Future plans are to allow you have the ability of chaing the scheduler

##### Architecture
You have one master node and many agent nodes. Each agent node opens a TCP port over allowing secure communication over TLS with the master node. The master node is responsible for recieving requests from docker client and relying them to the agents. The master node can also function as a agent and run containers.

To configure docker swarm, the good folks at docker released a docker container that is run on both the docker master and docker agent nodes.

Becuase of the TLS requirement between master and slave nodes, the easist way to setup swarm is to use docker-machine which swarm specific deployment options as the ability to manage certs required for TLS between the different swarm components.

Docker swarm is implmeneted through a container that distributed by docker that runs on the master node with the master role and on the agent nodes with the agent roles.

Since we will be using overlay networks, we will use consul as our key-value store for service discovery.

### Swarm Deployment

1. The first thing we do is to deploy our key-value store. We provision this into a docker host called swarm-key-value-store.


	```bash

	~/Dropbox/Documentation/Python/SCRIPTS/CLEAN_SCRIPTS/docker/drupal_2_tier(branch:v1) » docker-machine create -d openstack \                    
	--openstack-flavor-id 3 \
	--openstack-image-name "Ubuntu 14.04" \
	--openstack-ssh-user ubuntu \
	--openstack-net-name fip_public \
	--openstack-sec-groups security_group_open \
	swarm-key-value-store
	Running pre-create checks...
	Creating machine...
	(swarm-key-value-store) Creating machine...
	Waiting for machine to be running, this may take a few minutes...
	Detecting operating system of created instance...
	Waiting for SSH to be available...
	Detecting the provisioner...
	Provisioning with ubuntu(upstart)...
	Installing Docker...
	Copying certs to the local machine directory...
	Copying certs to the remote machine...
	Setting Docker configuration on the remote daemon...
	Checking connection to Docker...
	Docker is up and running!
	To see how to connect your Docker Client to the Docker Engine running on this virtual machine, run: docker-machine env swarm-key-value-store
	~/Dropbox/Documentation/Python/SCRIPTS/CLEAN_SCRIPTS/docker/drupal_2_tier(branch:v1) » docker-machine env swarm-key-value-store; eval $(docker-machine env swarm-key-value-store)
	```

2.  The key-value store holds information about the network state which includes discovery, networks, endpoints, IP addresses, and more. Docker supports Consul, Etcd, and ZooKeeper key-value stores. This example uses Consul.

	```bash

	~/Dropbox/Documentation/Python/SCRIPTS/CLEAN_SCRIPTS/docker/drupal_2_tier(branch:v1) » docker run -d \                                         
	    -p "8500:8500" \
	    -h "consul" \
	    progrium/consul -server -bootstrap
	Unable to find image 'progrium/consul:latest' locally
	latest: Pulling from progrium/consul
	c862d82a67a2: Pull complete
	0e7f3c08384e: Pull complete
	0e221e32327a: Pull complete
	09a952464e47: Pull complete
	60a1b927414d: Pull complete
	4c9f46b5ccce: Pull complete
	417d86672aa4: Pull complete
	b0d47ad24447: Pull complete
	fd5300bd53f0: Pull complete
	a3ed95caeb02: Pull complete
	d023b445076e: Pull complete
	ba8851f89e33: Pull complete
	5d1cefca2a28: Pull complete
	Digest: sha256:8cc8023462905929df9a79ff67ee435a36848ce7a10f18d6d0faba9306b97274
	Status: Downloaded newer image for progrium/consul:latest
	cb17fa3fb60b5d48b58f7bd964b7972a53778c1bb5405703ab881736a5c38116
	```

3. Using the docker-machine, we deploy swarm master in on an openstack node called swarm-master and point it to the key value store.

	```bash

	~/Dropbox/Documentation/Python/SCRIPTS/CLEAN_SCRIPTS/docker/drupal_2_tier(branch:v1) » docker-machine create -d openstack \
	--openstack-flavor-id 3 \
	--openstack-image-name "Ubuntu 14.04" \
	--openstack-ssh-user ubuntu \
	--openstack-net-name fip_public \
	--openstack-sec-groups security_group_open \
	--swarm \
	--swarm-master \
	--swarm-discovery="consul://$(docker-machine ip swarm-key-value-store):8500" \
	--engine-opt="cluster-store=consul://$(docker-machine ip swarm-key-value-store):8500" \
	--engine-opt="cluster-advertise=eth0:2376" \
	swarm-master
	Running pre-create checks...
	Creating machine...
	(swarm-master) Creating machine...
	Waiting for machine to be running, this may take a few minutes...
	Detecting operating system of created instance...
	Waiting for SSH to be available...
	Detecting the provisioner...
	Provisioning with ubuntu(upstart)...
	Installing Docker...
	Copying certs to the local machine directory...
	Copying certs to the remote machine...
	Setting Docker configuration on the remote daemon...
	Configuring swarm...
	Checking connection to Docker...
	Docker is up and running!
	To see how to connect your Docker Client to the Docker Engine running on this virtual machine, run: docker-machine env swarm-master
	```

4. We then deploy the second docker agents, the difference between the first two commands is that the second command does not have the role of master.  

	```bash

	~/Dropbox/Documentation/Python/SCRIPTS/CLEAN_SCRIPTS/docker/drupal_2_tier(branch:v1) » docker-machine create -d openstack \
	--openstack-flavor-id 3 \
	--openstack-image-name "Ubuntu 14.04" \
	--openstack-ssh-user ubuntu \
	--openstack-net-name fip_public \
	--openstack-sec-groups security_group_open \
	--swarm \
	--swarm-discovery="consul://$(docker-machine ip swarm-key-value-store):8500" \
	--engine-opt="cluster-store=consul://$(docker-machine ip swarm-key-value-store):8500" \
	--engine-opt="cluster-advertise=eth0:2376" \
	swarm-agent-01
	Running pre-create checks...
	Creating machine...
	(swarm-agent-01) Creating machine...
	Waiting for machine to be running, this may take a few minutes...
	Detecting operating system of created instance...
	Waiting for SSH to be available...
	Detecting the provisioner...
	Provisioning with ubuntu(upstart)...
	Installing Docker...
	Copying certs to the local machine directory...
	Copying certs to the remote machine...
	Setting Docker configuration on the remote daemon...
	Configuring swarm...
	Checking connection to Docker...
	Docker is up and running!
	To see how to connect your Docker Client to the Docker Engine running on this virtual machine, run: docker-machine env swarm-agent-01
	```

5. On checking the status with docker-machine we see that the docker hosts are up and avaiable. We have one host dedicated to running the key-value store consul

	```bash

	~/Dropbox/Documentation/Python/SCRIPTS/CLEAN_SCRIPTS/docker/drupal_2_tier(branch:v1) » docker-machine ls                    
	NAME                    ACTIVE   DRIVER      STATE     URL                         SWARM                   DOCKER    ERRORS
	swarm-agent-01          -        openstack   Running   tcp://209.49.73.117:2376    swarm-master            v1.11.2
	swarm-agent-02          -        openstack   Running   tcp://209.49.73.118:2376    swarm-master            v1.11.2
	swarm-key-value-store   *        openstack   Running   tcp://209.49.73.115:2376                            v1.11.2
	swarm-master            -        openstack   Running   tcp://209.49.73.116:2376    swarm-master (master)   v1.11.2
	```

6. Set the environment to the docker swarm master

	```bash

	~/Dropbox/Documentation/Python/SCRIPTS/CLEAN_SCRIPTS/docker/drupal_2_tier(branch:v1) » eval $(docker-machine env --swarm swarm-master)
	------------------------------------------------------------
	```

7. When you issue ```docker ps``` you issue this against the whole cluster. Here you can see the docker-swarm container running on all the three nodes with the join flag. The manage cluster has it also running with the manage flag

	```bash

	~/Dropbox/Documentation/Python/SCRIPTS/CLEAN_SCRIPTS/docker/drupal_2_tier(branch:v1) » docker ps -a                         
	CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS               NAMES
	e707d8e65837        swarm:latest        "/swarm join --advert"   3 minutes ago       Up 2 minutes                            swarm-agent-02/swarm-agent
	b6621ee252f5        swarm:latest        "/swarm join --advert"   9 minutes ago       Up 9 minutes                            swarm-agent-01/swarm-agent
	b1e5c32ba26d        swarm:latest        "/swarm join --advert"   19 minutes ago      Up 19 minutes                           swarm-master/swarm-agent
	4ef2ee5f90e7        swarm:latest        "/swarm manage --tlsv"   19 minutes ago      Up 19 minutes                           swarm-master/swarm-agent-master
	```

8. We can now start a container using compose that has two networks called front and back  

	```bash

	~/Dropbox/Documentation/Python/SCRIPTS/CLEAN_SCRIPTS/docker/drupal_2_tier(branch:v1) » docker-compose up --build            
	Creating network "drupal2tier_front" with driver "overlay"
	Creating network "drupal2tier_back" with driver "overlay"
	Building db
	Step 1 : FROM ubuntu:14.04
	14.04: Pulling from library/ubuntu
	...
	```

9. Listing the networks, we see the two overlay networks that were created.

	```bash

	~/Dropbox/Documentation/Python/SCRIPTS/CLEAN_SCRIPTS/docker/drupal_2_tier(branch:v1) » docker network ls                    
	NETWORK ID          NAME                    DRIVER
	23b009a4cd4b        drupal2tier_back        overlay
	7bc72de5ae1e        drupal2tier_front       overlay
	cb4dba09573c        swarm-agent-01/bridge   bridge
	5ccc1550a772        swarm-agent-01/host     host
	bd0b84bdc8e9        swarm-agent-01/none     null
	8fe8b38950e8        swarm-agent-02/bridge   bridge
	c399b6f3824a        swarm-agent-02/host     host
	2d3ddedd30e9        swarm-agent-02/none     null
	8efaccf6f68a        swarm-master/bridge     bridge
	40ddac1d99e8        swarm-master/host       host
	83c49ec7cf9d        swarm-master/none       null
	```
