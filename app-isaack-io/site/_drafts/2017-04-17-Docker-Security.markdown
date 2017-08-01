---
layout: post
title: "Docker Security"
excerpt: " Notes on Docker Security from DockerCon 2017. "
categories: [Docker,Security,Configuration Management]


[ALL LABS](https://github.com/docker/labs/tree/master/security)

## Isolation 
- Kernel namespaces
- Fork Bomb


## Transport Layer
- Client
	- CLI, python, go 
- Daemon/Server
	- REST API 	
Daemon and Clients, 

On Install Docker group to control who can ran Docker Client 
TLS configuration between 2375 & 2376 ports
Mutual TLS, Client can only talk to autneitcated Server and vice versa


##### Registry 
Can be configured to use client keys & Certicates
```
/etc/docker/certs.d/registry.corp.internal
clients.cert
client.key
ca.crt
```

## Code deployment Pipeline

#### Docker Content Trust
- (Publishers) Sign images, on pushing of images - GPG signed
- (Consumers) Verify images
- Context - using tags

- Signatures 
- Collection of Objects 
- Expire collections
- Collaborators - Publishers who can sign content

Enabling docker content on signed images

```
export DOCKER_CONTENT_TRUST=1
```
When using images not signed, it brings out an error on the client


When pushing a signed image, you are asked to create two keys, one 

- a root key in the ~/.docker/trust directory
- generates a repository key in the ~/.docker/trust directory

The passphrase you chose for both the root key and your repository key-pair should be randomly generated and stored in a password manager.

This is based off the TUFF update Framework. There is a nice blog on on this [here](https://theupdateframework.github.io/)

[Watch this video](https://www.youtube.com/watch?v=gHGDWwFdZqc)

## Security Scanning 
[lab](https://github.com/docker/labs/tree/master/security/scanning)

Hosted and on premise service

Vulnaribity Database
- Online updated
- Offline updates mannualy using tar files for air gapped DTR systesm
- enabled at DTR scanned automatically

##  Secure NEtworking
[lab](https://github.com/docker/labs/tree/master/security/swarm)


By default, swarm join uses the manager as the CA authority, you can specify an exteranal CA by using the ```--exernal ca``` flag

You can view the certificates by using OpenSSL 

```
 openssl x509 -in /var/lib/docker/certificates/swarm-node.crt -text
```

Docker uses RAFT protocol to establish consensous betwen the nodes. Does not need an external key value store like Etcd

### Constrains

built-in node attributes : nodeid. nodehostname noderole
built-in engine lables: engine lables operating system
built-in user defined labels: : prod, test etc 


## Container Secret

[lab](https://github.com/docker/labs/tree/master/security/secrets)

- Encrypted at rest
- Encrypted inflight
- Accesible to only nodes explicitly given access to those secrets
- Requires 1:13
- Secrets only decrypted in Memory: Always encrypted in disk
- Workers only see secrets in encrypted form
- Only services that need secrets can decrypt secrets, not containers
- Secretes are stored in Raft log is replicated across the other managers
- When you need a services access to a secret, the decrypted secret is mounted into the container in an in-memory filesystem at /run/secrets/<secret_name>
- Nothing is stored on disk
- ccess to (encrypted) secrets if the node is a swarm manager or if it is running service tasks which have been granted access to the secret. When a container task stops running, the decrypted secrets shared to it are unmounted from the in-memory filesystem for that container and flushed from the node’s memory
- **The RAFT key is the TLS header used to manage the swarm manager**


#### Management 
- Deveopers secrets: Docker Compose: network: secrets: Volumes
- Ops Secretes: Docker Datacenter


Constraints can be used to modify the secrets being used: Eg Prod: ProdSecrets, Test: TestSecretes


## Do not run in Root
[lab] (https://github.com/docker/labs/tree/master/security/userns)
 

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
