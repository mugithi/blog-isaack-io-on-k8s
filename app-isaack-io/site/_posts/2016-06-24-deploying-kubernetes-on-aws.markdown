---
layout: post
title: "Deploying Kubernetes on AWS"
excerpt: "Containers at scale thanks to Kubernetes..."
categories: [Docker, Networking]
---

### Kubernetes Architecture

Kubernetes has the following architecture

![](http://i.imgur.com/6UwUyBr.png)

Kubernetes nodes can be brocken down into basically two major components.

##### Worker Nodes

This run docker, services, networking for containers. Kubernetes has the following deamons runing on the worker nodes

- **kublet** This manages pods, their containers, images and volumes
- **kube-proxy** This is a simple network proxy/load balnacer for services allowing tcp/udp forwarding on each node:minion

##### Control Plane

This run the scheduler and serve out the kube-API. Kubernetes has the following deamons runing on the control nodes

- **etcd** This stores the peristsnant state of all the controlers(master), allows for notification of change of state reliably
- **Kubernetes api server** This servers kube api. It processes REST operatations and updates etcd.
- **scheduler** This binds unscheduled pods(units of work) to nodes. It is plugable and can be swapped out with other schedulers like Marathon etc.
- **Kubernetes Control Manager Server** performs cluster level functions. Made up of
	- endpoint manager that creates and updates objects.
	- node manager - discovers, managers and minitors nodes

Click on this [diagram](https://raw.githubusercontent.com/kubernetes/kubernetes/release-1.3/docs/design/architecture.png) to see more details on how this pieces fit together
Deployment on AWS

### Kubernetes Deployment


We will be deploying this in AWS and for that we will need two utilities

- [kubectl](http://kubernetes.io/docs/getting-started-guides/docker/#download-kubectl) - This is how we talk to the kubnernetes cluster
- [kube-aws](https://github.com/coreos/coreos-kubernetes/releases) - This is is how we deploy kubernetes on AWS.

I am doing all this on OSX so I am using the latest of the darwin releases of this two binarys. In addition to that, I already have aws-cli configured. I watched a talk by the CoreOS CTO, and they use this tools to deploy in production at CoreOS.

You will need GnuPG that is an application used for public key encryption and verification of signatures using OpenPGP protocol for the Kubernetes binaries. Install this using brew on osx ```brew install gpg2```

1. Download the pgp signature from [CoreOS](https://coreos.com/security/app-signing-key/) and install it using gpg2

	```bash

	~/k8s(branch:master*) » gpg2 --keyserver pgp.mit.edu --recv-key FC8A365E
	gpg: directory '/Users/isaackkaranja/.gnupg' created
	gpg: new configuration file '/Users/isaackkaranja/.gnupg/gpg.conf' created
	gpg: WARNING: options in '/Users/isaackkaranja/.gnupg/gpg.conf' are not yet active during this run
	gpg: keyring '/Users/isaackkaranja/.gnupg/secring.gpg' created
	gpg: keyring '/Users/isaackkaranja/.gnupg/pubring.gpg' created
	gpg: requesting key FC8A365E from hkp server pgp.mit.edu
	gpg: /Users/isaackkaranja/.gnupg/trustdb.gpg: trustdb created
	gpg: key FC8A365E: public key "CoreOS Application Signing Key <security@coreos.com>" imported
	gpg: no ultimately trusted keys found
	gpg: Total number processed: 1
	gpg:               imported: 1  (RSA: 1)
	```

2. Validate the fingerprint

	```bash

		~/k8s(branch:master*) » gpg2 --fingerprint FC8A365E                                                                                                                                                                                       pub   4096R/FC8A365E 2016-03-02 [expires: 2021-03-01]
			Key fingerprint = 18AD 5014 C99E F7E3 BA5F  6CE9 50BD D3E0 FC8A 365E
		uid       [ unknown] CoreOS Application Signing Key <security@coreos.com>
		sub   2048R/3F1B2C87 2016-03-02 [expires: 2019-03-02]
		sub   2048R/BEDDBA18 2016-03-08 [expires: 2019-03-08]
		sub   2048R/7EF48FD3 2016-03-08 [expires: 2019-03-08]
	```

3. For this next step, you need to have downloaded your AWS keys and have them handy. Set the ```AWS_ACCESS_KEY_ID``` and ```AWS_SECRET_ACCESS_KEY``` in the
	```~/.aws/credentials``` file

	```bash
		~/Dropbox/Documentation/Python/SCRIPTS/CLEAN_SCRIPTS/k8s(branch:master*) » cat ~/.aws/credentials                                                                                                                                                                                           
		[default]
		aws_access_key_id = AKIAIYGV7BWX57H7RQ3A
		aws_secret_access_key = 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
		region = us-west-1

	```
4. Create a KMS key that will be used to encrypt and decrypt TLS assets using the aws Click

	```bash
	~/Dropbox/Documentation/Python/SCRIPTS/CLEAN_SCRIPTS/k8s(branch:master*) » aws kms --region=us-west-1 create-key --description="kube-aws assets"                                                                                                                                            
	{
	    "KeyMetadata": {
	        "KeyId": "xxxxxxxx-xxxxxx-xxxxxxxxx",
	        "Description": "kube-aws assets",
	        "Enabled": true,
	        "KeyUsage": "ENCRYPT_DECRYPT",
	        "KeyState": "Enabled",
	        "CreationDate": 1466959529.975,
	        "Arn": "arn:aws:kms:us-west-1:xxxxxxxxxx:key/xxxxxxxx-xxxxxx-xxxxxxxxx",
	        "AWSAccountId": "xxxxxxxxxxxx"
	    }
	}
	```

5. Download the kube-aws, extract it and from tar and move it to ```/usr/local/bin```


	```bash

	~/Downloads » wget https://github.com/coreos/coreos-kubernetes/ releases/download/v0.7.1/kube-aws-darwin-amd64.tar.gz
	~/Downloads » tar -xvf kube-aws-darwin-amd64.tar.gz                                                                                             
	x darwin-amd64/
	x darwin-amd64/kube-aws
	------------------------------------------------------------
	~/Downloads » cd darwin-amd64/
	~/Downloads/darwin-amd64 » mv kube-aws /usr/local/bin
 ```


6. Download the kubectl change execution mode and move it to ```/
usr/local/bin```

	```bash

	~/Downloads » wget https://storage.googleapis.com/kubernetes-release/release/v1.2.4/bin/darwin/amd64/kubectl
	~/Downloads » chmod +x kubectl
	~/Downloads » mv kube* /usr/local/bin  
	```

#### Using kube-aws to deploy a k8s cluster in AWS

The following steps will take you through how this binaries are used to deploy k8s into a AWS stack.

1. Create a repository where you will store all your kubneretes assets and initialize the cluster.  

	```bash
	~/Dropbox/Documentation/Python/SCRIPTS/CLEAN_SCRIPTS/k8s(branch:master*) » mdkir k8s && cd k8s

	```
2. Generate the ```cluster.yml``` file that contains all settings that will be used

	```bash

	~/(branch:master*) » kube-aws init --cluster-name=kube-cluster \             
	--external-dns-name=kube.isaack.io \
	--region=us-west-1 \
	--availability-zone=us-west-1c \
	--key-name=isaack-k8s \
	--kms-key-arn="arn:aws:kms:us-west-1:xxxxxxx-xxxxxxx:key/xxxxxxx-xxxxxxxx-xxxxxxxxxx"
	```

3. Generate the aws-stack template and the credentials that will be used by cloud-formation to create the stack.

	```bash

	~/(branch:master*) » kube-aws render
	~/(branch:master*) » tree .                                                  
	.
	├── cluster.yaml
	├── credentials
	│   ├── admin-key.pem
	│   ├── admin.pem
	│   ├── apiserver-key.pem
	│   ├── apiserver.pem
	│   ├── ca-key.pem
	│   ├── ca.pem
	│   ├── worker-key.pem
	│   └── worker.pem
	├── kubeconfig
	├── stack-template.json
	└── userdata
	    ├── cloud-config-controller
	    └── cloud-config-worker
	```

4. I modified the cluster.yml that contained the configuration parameters that are templatized userdata and Cloudformation stack. I modified the cloud configuration to number of workers and Instance type.

	```yml
	~/(branch:master*) » cat cluster.yaml                                        
	# Unique name of Kubernetes cluster. In order to deploy
	# more than one cluster into the same AWS account, this
	# name must not conflict with an existing cluster.
	clusterName: kube-cluster

	# DNS name routable to the Kubernetes controller nodes
	# from worker nodes and external clients. Configure the options
	# below if you'd like kube-aws to create a Route53 record sets/hosted zones
	# for you.  Otherwise the deployer is responsible for making this name routable
	externalDNSName: kube.isaack.io

	# CoreOS release channel to use. Currently supported options: [ alpha, beta ]
	# See coreos.com/releases for more information
	releaseChannel: alpha

	# Set to true if you want kube-aws to create a Route53 A Record for you.
	createRecordSet: true

	# TTL in seconds for the Route53 RecordSet created if createRecordSet is set to true.
	recordSetTTL: 300

	# DEPRECATED: use hostedZoneId instead
	# The name of the hosted zone to add the externalDNSName to,
	# E.g: "google.com".  This needs to already exist, kube-aws will not create
	# it for you.
	hostedZone: "isaack.io"

	# The ID of hosted zone to add the externalDNSName to.
	# Either specify hostedZoneId or hostedZone, but not both
	#hostedZoneId: "isaack.io"

	# Name of the SSH keypair already loaded into the AWS
	# account being used to deploy this cluster.
	keyName: isaack-k8s

	# Region to provision Kubernetes cluster
	region: us-west-1

	# Availability Zone to provision Kubernetes cluster when placing nodes in a single availability zone (not highly-available) Comment out for multi availability zone setting and use the below `subnets` section instead.
	availabilityZone: us-west-1c

	# ARN of the KMS key used to encrypt TLS assets.
	kmsKeyArn: "arn:aws:kms:us-west-1:xxxxxxx-xxxxxxx:key/xxxxxxx-xxxxxxxx-xxxxxxxxxx"

	# Instance type for controller node
	controllerInstanceType: t2.micro

	# Disk size (GiB) for controller node
	controllerRootVolumeSize: 80

	# Number of worker nodes to create
	workerCount: 2

	# Instance type for worker nodes
	workerInstanceType: t2.micro

	# Disk size (GiB) for worker nodes
	workerRootVolumeSize: 80

	# Price (Dollars) to bid for spot instances. Omit for on-demand instances.
	# workerSpotPrice: "0.05"

	# ID of existing VPC to create subnet in. Leave blank to create a new VPC
	# vpcId:

	# ID of existing route table in existing VPC to attach subnet to. Leave blank to use the VPC's main route table.
	# routeTableId:

	# CIDR for Kubernetes VPC. If vpcId is specified, must match the CIDR of existing vpc.
	# vpcCIDR: "10.0.0.0/16"

	# CIDR for Kubernetes subnet when placing nodes in a single availability zone (not highly-available) Leave commented out for multi availability zone setting and use the below `subnets` section instead.
	# instanceCIDR: "10.0.0.0/24"

	# Kubernetes subnets with their CIDRs and availability zones. Differentiating availability zone for 2 or more subnets result in high-availability (failures of a single availability zone won't result in immediate downtimes)
	# subnets:
	#   - availabilityZone: us-west-1a
	#     instanceCIDR: "10.0.0.0/24"
	#   - availabilityZone: us-west-1b
	#     instanceCIDR: "10.0.1.0/24"

	# IP Address for the controller in Kubernetes subnet. When we have 2 or more subnets, the controller is placed in the first subnet and controllerIP must be included in the instanceCIDR of the first subnet. This convention will change once we have H/A controllers
	# controllerIP: 10.0.0.50

	# CIDR for all service IP addresses
	# serviceCIDR: "10.3.0.0/24"

	# CIDR for all pod IP addresses
	# podCIDR: "10.2.0.0/16"

	# IP address of Kubernetes dns service (must be contained by serviceCIDR)
	# dnsServiceIP: 10.3.0.10

	# Version of hyperkube image to use. This is the tag for the hyperkube image repository.
	# kubernetesVersion: v1.2.4_coreos.1

	# Hyperkube image repository to use.
	# hyperkubeImageRepo: quay.io/coreos/hyperkube

	# Use Calico for network policy. When set to "true" the kubernetesVersion (above)
	# must also be updated to include a version tagged with CNI e.g. v1.2.4_coreos.cni.1
	# useCalico: false

	# AWS Tags for cloudformation stack resources
	stackTags:
	  Name: "Kubernetes"
	  Environment: "Production"
	```

5. Use the validate command to check the validity of the cloud-config files and cloud-formation stack description.

	```bash
	~/(branch:master*) » kube-aws validate                              
		Warning: the 'hostedZone' parameter is deprecated. Use 'hostedZoneId' instead
		Validating UserData...

		UserData is valid.

		Validating stack template...
		Validation Report: {
		  Capabilities: ["CAPABILITY_IAM"],
		  CapabilitiesReason: "The following resource(s) require capabilities: [AWS::IAM::InstanceProfile, AWS::IAM::Role]",
		  Description: "kube-aws Kubernetes cluster kube-cluster"
		}
		stack template is valid.

		Validation OK!
	```
6. Initiate the cluster using the ```kube-aws up``` command.

	```bash
	~/(branch:master*) » kube-aws up
		Warning: the 'hostedZone' parameter is deprecated. Use 'hostedZoneId' instead
		Creating AWS resources. This should take around 5 minutes.
		Success! Your AWS resources have been created:
		Cluster Name:	kube-cluster
		Controller IP:	52.8.150.32

		The containers that power your cluster are now being dowloaded.

		You should be able to access the Kubernetes API once the containers finish downloading.
	```

7. You can watch the status of the AWS cloudformation creation events using the command below

	```bash

	  ~/(branch:master*) » while true; do clear; aws cloudformation describe-stack-events --stack-name kube-cluster | jq '.' | grep -i CREATE_IN_PROGRESS; sleep 5; done
	```
8. You can check the status of the cluster using the ```kubectl command```

	```bash
	~/(branch:master*) » kubectl --kubeconfig=kubeconfig get nodes
		NAME                                       STATUS                     AGE
		ip-10-0-0-184.us-west-1.compute.internal   Ready                      1h
		ip-10-0-0-185.us-west-1.compute.internal   Ready                      1h
		ip-10-0-0-50.us-west-1.compute.internal    Ready,SchedulingDisabled   1h
		------------------------------------------------------------
	~/(branch:master*) »
	```
9. Add the path to the kubectl configuration file by aliasing it as shown below

	```
		~ » alias | grep -i kubectl                                                                                                                     
		kubectl='kubectl --kubeconfig=$PWD/kubeconfig'
	```
10. We can see the services running in kube-system namespace by issuing the following commands

	```bash

		~ » kubectl get pods --namespace=kube-system                                                                                                   
		NAME                                                              READY     STATUS    RESTARTS   AGE
		heapster-v1.0.2-808903792-to1ms                                   2/2       Running   0          52m
		kube-apiserver-ip-10-0-0-50.us-west-1.compute.internal            1/1       Running   0          52m
		kube-controller-manager-ip-10-0-0-50.us-west-1.compute.internal   1/1       Running   0          52m
		kube-dns-v11-1cyv5                                                4/4       Running   0          51m
		kube-proxy-ip-10-0-0-240.us-west-1.compute.internal               1/1       Running   0          52m
		kube-proxy-ip-10-0-0-241.us-west-1.compute.internal               1/1       Running   0          50m
		kube-proxy-ip-10-0-0-50.us-west-1.compute.internal                1/1       Running   0          52m
		kube-scheduler-ip-10-0-0-50.us-west-1.compute.internal            1/1       Running   0          52m

	```
