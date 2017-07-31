---
layout: post
title: "Perfect Jenkins workflow Part 01: Jenkins on Kubernetes"
excerpt: "  "
categories: [Jenkins,Helm Charts,Terraform, Configuration Management]

## My Jenkins Workflow 

My intention was to build Kubernetes enviroment that was auto scaling up/down based on the number of containers/PODs I was runnining. My CI/CD tool was Jenkins which built the infrustcture based on a Jenkinsfile that was stored on Github repo. See below for the workflow diagram. 

In this post will describe the tools that I used and why I chose them. I subsequent posts, I will go deeper on how the components come together and how the architecture descisions that I made.


Below is a diagram showing Jenkins workflow. 


![](https://raw.githubusercontent.com/mugithi/blog/master/site/images/jenkins-workflow.png?token=ABTZB6SDKcBnbTvcIeWEFVejQSFTrV_bks5ZiM8DwA%3D%3D)

## Introduction  

I started to transition all enviroments that I manage to run to Docker containers. I love docker containers since they allow me to easilyspining up, spining down enviroments. I also was transitioning to architecting and building applications to immutable applications. Previously, I had been deploying using Ansible for my configuration management. I run applications on Openstack, VMware and AWS and I realised having applications containerized gave me alot of flexibility on where I can deploy. My initial setup involved Docker but quickly switched to Kubernetes due to reasons I will detail later in this blog.  I will quickly go through the tools that I use and reasons why I chose them

### Terraform 
Terraform is developed by Harshi-Corp. It is a tool for building, changing, and versioning infrastructure safely and efficiently. Terraform can manage existing infrustrcutre (think VMware) and popular service providers(think GCP, AWS, Azure) as well as custom in-house solutions (think Openstack); something they call [providers](https://www.terraform.io/docs/providers/index.html). In order to use terraform, you describe everything in a YAML files which can be versioned and stored in your source-code repository. Terraform then talks to the infrustrcutre API endpoints and creates whatever your described in YALM files. 

The reason I picked terraform over something like AWS cloudFormation is because Terraform is cloud agnostic; it allows me to write something for AWS and if I need to deploy the same constructs on Openstack, I can easily reuse the work I have already done without having to learn new syntax. 

I also can use Ansible, by calling provisioners to configure the Operating System once I have span up the infrustructure. [Here is a example](https://github.com/mugithi/vpshere-docker-ansible-terraform) of using Terraform to provision infrustructure on VMware after which I use Ansible  to install Docker on the provisioned nodes.
 
 

### Jenkins
I love Jenkins with all its quirks and that is all there is to it. See previous entries I have done regarding [Jenkins](https://blog.isaack.io/articles/2016-08/Jenkins-CICD-Getting-Started-With-Groovy-Part-1) and [Jenkinsfiles](https://blog.isaack.io/articles/2016-08/Jenkins-CICD-Getting-Started-With-Groovy-Part-2)


### Kubernetes Helm

I got introduced to [Kubernetes](https://blog.isaack.io/articles/2016-06/deploying-kubernetes-on-aws) a while back and have been using it for sometime. I got introduced to Helm late last year. Helm is a package manager for kubernetes. It was originally a [Dies](https://deis.com/blog/2016/getting-started-authoring-helm-charts/) project that has since been opensourced. Helm allows you to take those quirky Kubernetes YAML files and create structure around them. They call this charts which is organization around the yaml files. Below is the structure of the Helm Chart


```yaml
~/
▶ helm create chart-template
Creating chart-template

~/
▶ tree chart-template
chart-template
├── Chart.yaml
├── charts
├── templates
│   ├── NOTES.txt
│   ├── _helpers.tpl
│   ├── deployment.yaml
│   ├── ingress.yaml
│   └── service.yaml
└── values.yaml

2 directories, 7 files
```

This charts can then been versioned, shared and published. It makes working with Kubernetes alot of fun. 

This are the tools I chose to build upon. 

I used [KOPS](https://github.com/kubernetes/kops/blob/master/docs/terraform.md) to generate the terrafrom configurations and deploy the AWS enviroment. 
