---
layout: post
title: "Perfect Jenkins workflow Part 03: Helm Charts with SSL - Security for all"
excerpt: "Back in day before ACME protocol existed, securing of sites through obtaining a CA signed Certificate meant spending a fair sum of money through trusted CA..."
categories: [Jenkins, Helm Charts, Terraform, Configuration Management, Security]
---

## Quick Refresher on life before ACME protocol

Back in day before ACME protocol existed, having a secure site and obtaining a CA signed Certificate meant spending a fair sum of money through trusted CA. Come 2016, [Lets Encrypt](https://letsencrypt.org/), a non-profit organization which is under the the Linux Foundation, put their service in public beta. Let's Encrypt offers free CA signed SSL certifiates to all with a goal to secure the internet all with very minimal human intervention. I am going to briefly go into details on how they do this. 

There are bascially three types of SSL certificates

- Extended-Verified SSL Certificate (EV)
- Organization-Verified SSL Certificate (OV)
- Domain-Validated SSL Certificate (DV)

**Extended Verified Certificates** provide the maximum trust to web users. As per CA/Browser Forum guideline, CA has to follow manual through vetting of the entity perferforming the certificate request, for that requester need send organizational documentations to prove business credibility and CA has to verify

- Physical and operational existence of the entity
- Identity of the entity matches official records
- Entity has exclusive right to use the domain specified in the EV SSL Certificate
- Entity has properly authorized the issuance of the EV SSL Certificate

A completely approved EV certificate will display the name of the organization in the green text in most browser address bar. Here is an example from Bank of America. Extended Verified Certificates also contain two encryption algorithms, RSA and DSA within the same SSL certificate. An EV is required for ECommerce websites. 

![](https://raw.githubusercontent.com/mugithi/blog-isaack-io-on-k8s/master/app-isaack-io/site/img/bank-of-america.png)

**Organization Verified Certificates** provides lower level of trust but the CA still checks for the applicants right to use a the domain plus does some vetting of the organization. The OV verification also requires the requester to send organizational documentations to prove business. The verfied Organiation information is displayed to web users by clicking on the Secure Secure Site seal

![](https://raw.githubusercontent.com/mugithi/blog-isaack-io-on-k8s/master/app-isaack-io/site/img/the-gardian.png)

**Domain Verified Certificates** requires the least level of validation to issue a certificate. The Certificate Authority (CA) will assign this certificate by following automated email verification process and/or confirming domain information through the WHOIS record. Subsequently, these certificates are issued within a few minutes. No organization data is checked or shown in the certificate details. DVs are ideal for news sites, small business, blogs.

Lets Encrypt uses [ACME (Automatic Certificate Management Environment)) protocol](https://ietf-wg-acme.github.io/acme/draft-ietf-acme-acme.html) to issue DV X.509 certificates. As of the day of writing this post, the ACME protocol is still to be ratified by the IETF. ACME works by having the requester verify that they control the domain, they do this by having the requester

- Provisining a DNS record
- Provisioning a HTTP header under a well known URI on the domain and sends it to the CA

The CA then provides the requester with a noonce that needs to be signed by the requester using its private key and puts it under its well known  URL. The CA then downloads the signed noance and verfies the signature of the nonace and issues a certificate. 

This process can be automated and if you deploy a website under its real domain, you can install an agent that takes care of this process for you. Let'ts encrypt issues 90 day domain specific certificates, wildcard certificate are yet to be released as of the date of this post.

### Kubernetes Jenkins and Let's Encrypt

Kubernetes makes the process of requesting DV certificates from Let's Encrypt fully automated. Using Jenkins I create DNS entries on Route53 for the production site when I push to master and  DNS entries for functional staging/testing site when I perform a Github Pull request. When I tear down the Staging/Test site, the certificate is revoked. I use several components to accomlish this

### Nginx Controler for Ingress and Egress Load Balancer

My Kubernetes Deployment uses a Nginx Ingress Controller as the application load balancer. When deploying applications on Kubernetes on AWS, one has the choice of using a AWS ELB, but I chose Nginx Load balancer because it made the Jenkins/Kubernetes deployment portable between public clouds since I was not using native  AWS resources. For each application I deployed, I created a Nginx virtual host with the DNS specific entries which along with the Route53 DNS allowed me to create websites reachable over the open internet. Below is the yaml file of the Nginx Controller. 


### ```nginx-controller.yaml```

<script src="https://gist.github.com/mugithi/d17fe5aaa34c0de5115cb3e8b061aa43.js"></script>

Each of the applications helm charts had the values file configured to create the virtual host and request SSLs from Let's Encrypt. See below for application Values file

### ```values.yaml with virtual host and SSL configuration```

<script src="https://gist.github.com/mugithi/a7c539858236d400f8a31d9a16ca0a6d.js"></script>


### Jenkins create Route53 DNS entry using Terraform
In my Jenkins pipeline, for all push to master and github pull requests, I created a DNS entry in route53. I used terrafrom to create the DNS entries. Below is the image of the Jenkins pipeline

![](https://raw.githubusercontent.com/mugithi/blog-isaack-io-on-k8s/master/app-isaack-io/site/img/Jenkinspipeline.png)

Below is the Jenkinsfile that programatically discribles the Jenkins pipeline

### ```Jenkinsfile```
<script src="https://gist.github.com/mugithi/ca6688864641304bc12c955683694fe4.js"></script>


### Kube-lego for Lets Encrypt Intergration

In order to request SSL certificates from Let's Encrypt, kube-lego is used. Kube-lego is installed as a helm chart that can be downloaded by searching the helm stable repo like so 

```
# helm search  | grep -i lego
stable/kube-lego              	0.1.10 	Automatically requests certificates from Let's ...
stable/nginx-lego             	0.2.1  	Chart for nginx-ingress-controller and kube-lego

```

Let's encrypt has two modes, production and staging. Staging SSL certificates are not logged in the  official CA issued certificate database. For production use, the Values file has to be modified with the requesters email ````LEGO-EMAIL``` and sepficiying the ```KUBE-LEGO-URL``` to point to acme-production URL. Below is an example of the Kube-lego values file.


### ```kube-lego-values.yaml```

<script src="https://gist.github.com/mugithi/a49decf448454a8e0572f112bafbb519.js"></script>

## Conclusion

The end result of all of this is I get very site I provision using Jenkins, wether for staging or for production, getting deployed with an CA signed SSL certificate as shown below

![](https://raw.githubusercontent.com/mugithi/blog-isaack-io-on-k8s/master/app-isaack-io/site/img/blog-isaack-io.png)

