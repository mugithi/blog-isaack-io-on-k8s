---
layout: post
title: "Jenkins CICD Getting started with Groovy and Docker Containers"
excerpt: "In todays world of CICD, Jenkins is the undisputed champion, Jenkins has been deployed..., "
categories: [CICD, Jenkins, Groovy]
---

<!-- TOC depthFrom:1 depthTo:6 withLinks:1 updateOnSave:1 orderedList:0 -->

		- [History](#history)
			- [Docker Four modes of networking](#docker-four-modes-of-networking)
			- [Host Mode (The old)](#host-mode-the-old)
			- [Bridge mode](#bridge-mode)
			- [None mode](#none-mode)
		- [User Defined Neworks](#user-defined-neworks)
		- [Overlay Networks](#overlay-networks)
<!-- /TOC -->

#### Introduction to Groovy

Groovy is an agile DSL for JVM. Here is an awesome video on getting started with [Groovy](https://www.youtube.com/watch?v=B98jc8hdu9g). I have become huge fan of this learn an language in one hour videos, by the end of the video you get a good idea on the ramp up time required to take on learning a new programing launuage. I am pretty profecient in python and with groovy I get the feeling I am working with Python rather than with Java 

#### Jenkins and Groovy

Jenkins pipelines replaced the old hudson workflows and are now considered the goto for writing your CICD pipeline [there, i said it again :-)]. There has always been a option to capture the xml of the job by navigating to https://<jenkinsip>:8080/job/config.xml and capturing the xml configuration of the job, but Groovy takes it a step further and gives you a powerfull way to decribe your deployment pipline in code. 

When running groovy, you can either paste it in the 

#### Requirements 

You need to install the groovy plugin that adds the following options for you

Execute Groovy as main job or part of job

![](http://i.imgur.com/4etNbma.png =120x)

Execuite Groovy Script as part of the post build of a job.

![](http://i.imgur.com/WzRbIAh.png =120x)


### Running Groovy Scrips

There are to basic ways to run Groovy code

1. The plain "Groovy Script" is run in a forked JVM, on the slave where the
build is run. It's the basically the same as running the "groovy"
command and pass in the script

2. The system groovy script, OTOH, runs inside the Jenkins master's
JVM. Thus it will have access to all the internal objects of Jenkins, so
you can use this to alter the state of Jenkins itself and slave nodes. 

![](http://i.imgur.com/9Ji4WbM.png =120x)

When running groovy as part of the job, Can pull it and execuite from an SCM or you can put the script directly into the command box that is provided 


### Preparing the environment. 

Configure a Jenkins instance. The easiest way to do this is to use a configuration management tool like Ansible, Jenkins is heavily dependant on having Java configured just right or using a docker container. If you use a container, the administration password will be at end of the docker logs

```bash 

$ docker run -p 8080:8080 -p 50000:50000 jenkins
Unable to find image 'jenkins:latest' locally
latest: Pulling from library/jenkins
8ad8b3f87b37: Pull complete
751fe39c4d34: Pull complete
...


...

*************************************************************
*************************************************************
*************************************************************

Jenkins initial setup is required. An admin user has been created and a password generated.
Please use the following password to proceed to installation:

7a4fc92xxxxxxxxxxxxxxxxxxxxaf

This may also be found at: /var/jenkins_home/secrets/initialAdminPassword

*************************************************************
*************************************************************
*************************************************************


```

You can reach the jenkins port by navigating to port https://jenkinshost:8080 and you log in using the password from the docker logs. 

Now, if configuring a Freestyle Project, this is fairly easy to setup and this works as expected, but I wanted to use the new pipeline feature with Pipeline as code and nice visualtion features. For that I chose to use the Github Organization feature.

I was not able to find any good documenation on how to get this configured. This are the things that need to be done.

1. Configure Jenkins webooks to point to github repo.
2. COnfigure Github to point to your Jenkins install to send webooks on build. You can configure this manually but github has a built in service with all the required permissions
3. Configure Jenkins Github Organization plugin
4. Configure your repo to point with the jenkins file with the groovy text that will be compiled when you run the job






