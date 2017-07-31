#### Prometus

Graphana, alert manager, cucluate lowest 

- Dimentional data model
- Querry Lauguage
- Simple to run
- Service discovery and integration 

Architecture
 - Uses a label based data model
 - Same label model used by k8s, docker smarm
 - http_requests_total(Job="Nginx", status=500}
 - New lauuage PromSQL used to query the logs 
 	- used for time seris computation
 	- example query node_filesytem_bytes_total {mountpiont  !="/"}

 	
 	
### GRPC 

gRPC - Remote procedure calls
- used to tie varous parts of the infrustrucutre together
- current version 1.2, 1.3 comming out
- [RPC website ](http://www.grpc.io/)
- RPC allows you to call functions remotely, better than API
- MTLS, OATH
- Create channel, that provides services
	- services can be API servers or ports on servers
	- channels act as brocker, will restart if any of the service s stop
	
What do you get from GRPC
- Multi - laungage
- Supports streaming RPC - bidrectinal 



#### Scalable ML Microservices on GPU
- Nvidia Containers (GPU containers)
- [NVIDIA docker continer](https://github.com/NVIDIA/nvidia-docker)
- You can mount to GPU on the Container 


MESOS -
- Support NVIDA GPUS as a first [class citizen](https://mesosphere.com/blog/2015/11/10/mesos-nvidia-gpus/) 
 
- Not avaiable in k8s

Tensorflow will need for you write your own GPU scheduler 


### IMAGE TO DOCKER

- Image2Docker for WIndows, need to be on windows 2016
	- uses powershell modules
	- install module image2docker 
- Image2Docker for MAC

- Issues
	- Security - are there secrets in the VM?
	- contenxt - do we need to lift everything
	- config explosures - how many init systems
	- validation - can we automate testing

- Great for lift and shift scenarios
- How image to docke rworks
	- disovery (detectives & Lift )
	- extrantion 
	- get_a_docker_file