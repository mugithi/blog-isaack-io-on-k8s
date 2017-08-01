---
layout: post
title: "Docker Networking"
excerpt: "How to configure overlay networks in Docker Networking. A couple of years back, Docker bought company called Socketplane. Socketplane had a solution that allowed you to build..."
categories: [Docker, Networking]
---

### History

A couple of years back, Docker a company called Socketplane. Socketplane had a solution that allowed you to build overlay tunnels between Docker nodes using VXLAN, allowing traffic to transverse between containers without any modification to the underlying network - hence network overlays... got it.

Since VXLAN is an overlay protocol and handles L2, it does require a way to handle the equivalent of ARP to discover all containers that might be connected to aparticualr network sitting on diferent hosts. This is not a problem unique to Docker and was solved long before Docker was Docker. There are three basic solutions that have long been identified for this problem.

1.  A centralized Control plane
2.  Multicast
3.  Use a specliazed protocol like BGP to advertize host/mac mappings

Docker networking implemnted (1) and (3), i.e centralized control plane and host/mapping advertisement betwen nodes.

For the centralized control plane, Docker uses a Key-value store (Consul, Etcd or Zookeeper) to learn and advertise who owns what.

For the host/mac advertisement, Docker then uses Serf from Harshicorp (a gossip-based protocol) that enables the hosts to directly communicate host/mac mappings. Serf is lightweight, highly available, and distributed.

After Docker acquision, also took out the OpenVswitch implemntation of Socketplane VXLAN solution and left the native VXLAN implementation attached to Linux bridges.  

#### Docker Four modes of networking

There are four modes in Docker networking

```
~ » Docker network ls                                                                                                       
NETWORK ID          NAME                DRIVER
2892e1caff64        bridge              bridge
5c757bb0ea26        host                host
f474dc6a315a        none                null
```

#### Host Mode (The old)

The container attached to the host network shares the network characterists of the host. Ifconfig on the container and host will be identical. You would use this mode when trying to eek all the speed from the network interfaces. To expose ports etc, you would rely on IPtables

```
~ » Docker run -d --name instance1 --net=host mugithi/ghostblog:v1

```

#### Bridge mode

This is the default mode of spining up containers. Communication of containers occurs through Docker0 interface, never leaving the host. You would use this with the ```-p <HostPort>:<ContainerPort>```  flag to map containers to ports

```bash
~ » Docker run -itd --name instance3 -p 80:80 --net=bridge mugithi/ghostblog:v1
~ » Docker run -itd --name instance4 -p 81:80 --net=bridge mugithi/ghostblog:v1
```

#### None mode

You use this to spin up containers not attached to any network

```bash
~ » Docker run -itd --name instance4 -p 81:80 --net=bridge mugithi/ghostblog:v1                                             
6ca1360cdf85c364af11b28e811908347c4ef486a606474eeed7519033c81544
------------------------------------------------------------
~ » Docker run -itd --name instance0 --net=none mugithi/ghostblog:v1                                                        
2c2aa50a8fa1870ca5b5d394761dbd01a751b071e05e226459e74c08443b5e01
------------------------------------------------------------
~ » Docker inspect 2c2aa50a8fa1870ca5b5d394761dbd01a751b071e05e226459e74c08443b5e01 | grep -i IPaddress                     
            "SecondaryIPAddresses": null,
            "IPAddress": "",
                    "IPAddress": "",

```

### User Defined Neworks

This are networks that were introduced in Docker version 0.9.

```bash
~ » Docker network create --driver=bridge --subnet=172.20.0.0/16 --gateway=172.20.0.1 --ip-range=172.20.1.0/24 external_net
32ea2de5a08818898b941e8c0d874ddbc18b2f58a992a93483aabaa52b4a7fc5
```

1. **Subnet**
2. **Gatway**
3. **IP Range (Optional)**


```json
~ » Docker network inspect external_net                                                                                     
[
    {
        "Name": "external_net",
        "Id": "32ea2de5a08818898b941e8c0d874ddbc18b2f58a992a93483aabaa52b4a7fc5",
        "Scope": "local",
        "Driver": "bridge",
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": {},
            "Config": [
                {
                    "Subnet": "172.20.0.0/16",
                    "IPRange": "172.20.1.0/24",
                    "Gateway": "172.20.0.1"
                }
            ]
        },
        "Internal": false,
        "Containers": {},
        "Options": {},
        "Labels": {}
    }
]
```

You  then assign create a VM and attach it to the network and we see it gets assigned an IP from the external_net address

```json
~ » Docker run -itd --name instance0 --net=external_net  mugithi/ghostblog:v1                                               
01813692bfcf6533c2b65db33021753b2d21836da1c4b85a6b0f50762fe23843
~ » Docker inspect 01813692bfcf6533c2b65db33021753b2d21836da1c4b85a6b0f50762fe23843 | grep  IPAddress                       
            "SecondaryIPAddresses": null,
            "IPAddress": "",
                    "IPAddress": "172.20.1.0",

```

You can also create internal networks by specifying the ``` --intnernal``` flag

```json
~ » Docker network create --driver=bridge --subnet=172.50.0.0/16 --gateway=172.50.0.1 --ip-range=172.50.1.0/24 --internal  internal_net
ac01aa553641892db6ea55d00ea39d796f485fda123dce3085f26241c87812b2
------------------------------------------------------------
~ » Docker network inspect internal_net                                                                                     
[
    {
        "Name": "internal_net",
        "Id": "ac01aa553641892db6ea55d00ea39d796f485fda123dce3085f26241c87812b2",
        "Scope": "local",
        "Driver": "bridge",
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": {},
            "Config": [
                {
                    "Subnet": "172.50.0.0/16",
                    "IPRange": "172.50.1.0/24",
                    "Gateway": "172.50.0.1"
                }
            ]
        },
        "Internal": true,
        "Containers": {},
        "Options": {},
        "Labels": {}
    }
]
```

We can connect a container to both internal and external networks to build a secure application. We do this using the ``` Docker network connect ```` and ````Docker network disconnect``` commands. Below we can see how we attach an existing VM to two networks

```json
~ » Docker ps -a                                                                                                            
CONTAINER ID        IMAGE                  COMMAND             CREATED             STATUS              PORTS               NAMES
01813692bfcf        mugithi/ghostblog:v1   "/bin/bash"         12 minutes ago      Up 12 minutes       2368/tcp            instance0
------------------------------------------------------------
~ » Docker inspect 01813692bfcf | grep -i IPAddress                                                                         
            "SecondaryIPAddresses": null,
            "IPAddress": "",
                    "IPAddress": "172.20.1.0",
------------------------------------------------------------
~ » Docker network connect internal_net 01813692bfcf                                                                        
------------------------------------------------------------
~ » Docker inspect 01813692bfcf | grep -i IPAddress                                                                         
            "SecondaryIPAddresses": null,
            "IPAddress": "",
                    "IPAddress": "172.20.1.0",
                    "IPAddress": "172.50.1.0",
------------------------------------------------------------
```

User defined networks also provide domain name resolution using container names. Each Docker host runs an instance of dnsmasq that is used to lease out IPs and keep track of DNS names, this allows you to refer to containers using their names.

On creating a new instance and attaching it to internal_net network, the two VMs can ping each other through their hostnames.

```bash
~ » Docker run -itd --name instance1 --net=internal_net  mugithi/ghostblog:v1                                               
4f49ab9bdccf6b09c8b79fd6aa5fec07edf4f8a2d93a8c54f97d0615f76cd251
------------------------------------------------------------
~ » Docker exec -it instance1 ping instance0                                                                                
PING instance0 (172.50.1.0) 56(84) bytes of data.
64 bytes from instance0.internal_net (172.50.1.0): icmp_seq=1 ttl=64 time=0.069 ms
^C

--- instance0 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 1999ms
rtt min/avg/max/mdev = 0.069/0.077/0.083/0.011 ms
------------------------------------------------------------
~ » Docker exec -it instance0 ping instance1                                                                                
PING instance1 (172.50.1.1) 56(84) bytes of data.
64 bytes from instance1.internal_net (172.50.1.1): icmp_seq=1 ttl=64 time=0.064 ms
```

### Overlay Networks

This kind of network relies on key-value store external to the hosts to store information regarding networks, endpoints, ip addreses and service discovery. You can use etcd, zookeper or consul. I use consul because of the ease of setting it up. The diagram below discribes the final setup, two Docker nodes connected using an overlay network registered to a consul:8500 container. The overlay tunnel uses VXLAN protocol

![](http://i.imgur.com/twJ7LJg.png)


My Docker hosts deployed using ```Docker-machine``` using the Parallels driver. This deploys two boot2Docker vms that will run my vms.

```bash
~ » Docker-machine create --driver=parallels Docker-parallels00
~ » Docker-machine create --driver=parallels Docker-parallels01
```

I modify the ```/var/lib/boot2Docker/profile```. After the existing ```EXTRA_ARGS``` I add the options  ```--cluster-store=consul://10.211.55.15:8500/network --cluster-advertise=eth0:2375'```.  I am telling the Docker host to listen to consul over the port 2375 through interfce ETH0. You would change this interface to whatever your interface public facing interface is. The resulting configuration file looks like this

```bash
~ » Docker-machine ssh Docker-parallels                                  
Boot2Docker version 1.11.1, build HEAD : 7954f54 - Wed Apr 27 16:36:45 UTC 2016
Docker version 1.11.1, build 5604cbe
Docker@Docker-parallels:~$ cat /var/lib/boot2Docker/profile
EXTRA_ARGS=' --label provider=parallels --cluster-store=consul://10.211.55.15:8500/network --cluster-advertise=eth0:2375'
CACERT=/var/lib/boot2Docker/ca.pem
Docker_HOST='-H tcp://0.0.0.0:2376'Docker_STORAGE=aufs
Docker_TLS=auto
SERVERKEY=/var/lib/boot2Docker/server-key.pem
SERVERCERT=/var/lib/boot2Docker/server.pem

```

I deploy a consul key-value store as a container and have it listen over port 8500.  

```bash
~ » Docker run -d -p 8500:8500 -h consul --name consul progrium/consul -server -bootstrap
dc219f379fa9ad52df140383d236110e78a6814eac16e944a143e86d9477f178
------------------------------------------------------------
~ » Docker ps -a                                                         
CONTAINER ID        IMAGE               COMMAND                  CREATED              STATUS              PORTS                                                                            NAMES
dc219f379fa9        progrium/consul     "/bin/start -server -"   About a minute ago   Up 30 seconds       53/tcp, 53/udp, 8300-8302/tcp, 8400/tcp, 8301-8302/udp, 0.0.0.0:8500->8500/tcp   consul

```

I can now create **Docker user defined overlay** network type from host ```Docker-parallels00```


```json
~ » Docker network create -d overlay --subnet=10.10.10.0/24 external-overlay-10-20-10-0-24
918cb379907bff966237366376ff68e159a55aea2b9d48cf9d715a3ec559e7f6
------------------------------------------------------------
~ » Docker network ls                               
NETWORK ID          NAME                    DRIVER
627640f25414        bridge                  bridge
5f3f8dab6891        host                    host
da633dc568a0        none                    null
918cb379907b        external-overlay-10-20-10-0-24   overlay
------------------------------------------------------------
~ » Docker network inspect 918cb379907b             
[
    {
        "Name": "external-overlay-10-20-10-0-24",
        "Id": "918cb379907bff966237366376ff68e159a55aea2b9d48cf9d715a3ec559e7f6",
        "Scope": "global",
        "Driver": "overlay",
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": {},
            "Config": [
                {
                    "Subnet": "10.10.10.0/24"
                }
            ]
        },
        "Internal": false,
        "Containers": {},
        "Options": {},
        "Labels": {}
    }
]
```

On examining it from the second Docker host ```Docker-parallels01``` we see that the network is registered with the same network ID


```bash
~ » Docker network ls           
NETWORK ID          NAME                    DRIVER
0246dd869dd1        bridge                  bridge
461153869d95        host                    host
93fe0001452e        none                    null
918cb379907b        external-overlay-10-20-10-0-24   overlay
```


Using overlay networks, you can then create an internal overlay network that does not pass traffic to the outside world

```bash
~ » Docker network create -d overlay --subnet=10.30.10.0/24 --internal internal-overlay-10-30-10-0-24
a383e330e99f0b537053ea60d4849e24e2489d727e2095f6819afcf5dfa06706

~ » Docker network ls                               
NETWORK ID          NAME                    DRIVER
627640f25414        bridge                  bridge
5f3f8dab6891        host                    host
da633dc568a0        none                    null
141a2caf7294        external-overlay-10-20-10-0-24   overlay
a383e330e99f        internal-overlay-10-30-10-0-24   overlay
------------------------------------------------------------
~ » Docker network inspect a383e330e99f             
[
    {
        "Name": "internal-overlay-10-30-10-0-24",
        "Id": "a383e330e99f0b537053ea60d4849e24e2489d727e2095f6819afcf5dfa06706",
        "Scope": "global",
        "Driver": "overlay",
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": {},
            "Config": [
                {
                    "Subnet": "10.30.10.0/24"
                }
            ]
        },
        "Internal": true,
        "Containers": {},
        "Options": {},
        "Labels": {}
    }
]

```
