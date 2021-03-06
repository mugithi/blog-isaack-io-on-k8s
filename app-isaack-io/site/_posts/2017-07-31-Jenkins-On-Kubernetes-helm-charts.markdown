---
layout: post
title: "Perfect Jenkins workflow Part 02: Helm Charts"
excerpt: "When deploying applications on kubernetes, one typically has to define the Workload resources using a series of yaml files, Helm makes this easier.. "
categories: [Jenkins, Helm Charts, Terraform, Configuration Management]
---

## Quick Refresher on life before Helm

When deploying applications on kubernetes, one typically has to define the Workload resources using a series of yaml files. Here is an example of an ingress controller single yaml file that describes everything the service, deployment and configMap workload resources.

### ```backend.yaml``` example

<script src="https://gist.github.com/mugithi/a4098f9ae51f99382043bd04f2bf7ace.js"></script>


To install this application you would use ```kubectl create -f nginx-ingress-controller``` with the ```-f``` referencing the path to ```backend.yaml``` file. You could still version your applications by checking in Yaml files but it was a tedious way of deploying applications.


## Hello Helm Charts

I mentioned in the previous blog post that Helm Charts are a package manager for kubernetes - analogous to apt or yum for linux. The goal of Helm charts is to allow people authoring applications to run on Kubernetes to easily package the work they have already done and share it with others. I wount spent much time talking about Helm architecture in this post but the one thing to note is that Helm uses a client server model; Helm(client) runs on your local workstation and Tiller(server) runs on the Kubernetes cluster. You initallize(install tiller server) the cluster by issuing the command ```helm init```. Also you need to have ```kubectl``` installed and configured to talk to your kubernetes cluster.  

You create a helm chart by issueing the command ```helm create chart-template``` which creates a directory with the following files in it


```bash
~/ helm create chart-template
~/ tree chart-template
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

The two items to pay special attention to are the Templates folder and Values file

The templates folder contains the YAML discriptions of your kubernetes objects eg deployment, ingress, service, secrets etc. Here is an example of a ```ingress.yaml``` and  ```service.yaml``` template for blog.isaack.io

### ```ingress.yaml```
<script src="https://gist.github.com/mugithi/a45fbb8ec72ab43a0461acb64edc44ae.js"></script>

### ```service.yaml```

<script src="https://gist.github.com/mugithi/ab30532b8a1d3ea97c3bfbc89b87537d.js"></script>

Helm uses the go-templating engine. The values in this templates are computed from the ```values.yaml``` file, see below for the Values.yaml file of blog.isaack.io

### ```values.yaml```

<script src="https://gist.github.com/mugithi/a7c539858236d400f8a31d9a16ca0a6d.js"></script>


You can check the values being rendered by issuing the command ```helm install --dry-run --debug```


### ```output.yaml```

<script src="https://gist.github.com/mugithi/9e3858bdf71f2f52583dd74ff8413f4d.js"></script>

In ths chart I don't have the secret creation as part of the chart but I could easily implement that by creating a ```secrets.yaml``` file and adding the applications secrets encoded using base64.


It is possible to overide the variables, in my Jenkinsfile, I do this by supplying build values. You overide the variables by using the ```--set``` command. When I run this chart through Jenkins in CI/CD, I overide the image tag variable with the docker image build tag as shown below

``` bash
helm upgrade --install  ./infra-isaack-io --set image.tag=jenkins-build-master-7 --set ingress.hosts=blog.isaack.io master

LAST DEPLOYED: Tue Aug  1 06:45:46 2017
NAMESPACE: default
STATUS: DEPLOYED

RESOURCES:
==> v1beta1/Ingress
NAME              HOSTS           ADDRESS           PORTS    AGE
master-isaack-io  blog.isaack.io  a703619c8759b...  80, 443  3h

==> v1/Service
NAME              CLUSTER-IP     EXTERNAL-IP  PORT(S)   AGE
master-isaack-io  100.67.45.152  <none>       4000/TCP  3h

==> v1/ReplicationController
NAME              DESIRED  CURRENT  READY  AGE
master-isaack-io  1        1        1      3h


NOTES:
1. Get the application URL by running these commands:
  export POD_NAME=$(kubectl get pods --namespace default -l "app=isaack-io,release=master" -o jsonpath="{.items[0].metadata.name}")
  echo "Visit http://127.0.0.1:8080 to use your application"
  kubectl port-forward $POD_NAME 8080:4000
```

I can also issue the following commands

``` helm rollback``` rollback chart by one version

``` helm rollback 1``` roll back chart to specific version

Helm is getting alot of traction in the Kubernetes community and instead of you writing your own application, you can use work other people have done. You can search for existing helm charts using the command ```helm search```

``` bash
▶ helm search  | grep -i wordpress
stable/wordpress              	0.6.8  	Web publishing platform for building blogs and ...

github/github/blog-isaack-io-on-k8s  master ✗
```

Here helm is searching through my helm repos configured to find a chart called wordpress. By default Helm comes with two repos preconfigured, incubator and stable but you can add your own.

``` bash
▶ helm repo list
NAME     	URL
incubator	https://kubernetes-charts-incubator.storage.googleapis.com/
stable   	http://storage.googleapis.com/kubernetes-charts
```

In my next post I will talk about some of the architecture decisions I went with and how I configured https to my applications
