---
layout: post
title: "Jenkins CICD Getting started with Groovy and Docker Containers - Part 1"
excerpt: "In todays world of CICD, Jenkins is the undisputed champion, Jenkins..., "
categories: [CICD, Jenkins, Groovy]
---

#### Introduction to Jenkins

In todays brave world of continous deployment and continous delivery, Jenkins is the undisputed champion. Jenkins has become the open source standard for managing the dev side of devops, from source code management to delivering code to production with popularity being attributed to its pluggable nature. Jenkins has over 1,100 plug-ins, enabling users to add all sorts of functionality and integrate Jenkins with everything from Active Directory to GitHub to the Kubernetes. One sweet feature of Jenkins is that if you currently use another automation tool, Jenkins does not replace it. For instance, if you use Ansible for configuration management, you don't replace Ansible with Jenkins - instead you use Jenkins to call Ansible during the provisioning process.

#### Introduction to Groovy

Groovy is an agile DSL for JVM. Here is an awesome video on getting started with [Groovy](https://www.youtube.com/watch?v=B98jc8hdu9g). I have become huge fan of this learn an language in one hour videos, by the end of the video you get a good idea on the ramp up time required to take on learning a new programing language. I am pretty proficient in python and with groovy I get the feeling I am working with Python rather than with Java.

#### Jenkins and Groovy

Jenkins pipelines replaced the old Hudson workflows and are now considered the goto method for writing your CI/CD pipeline. There has always been a option to capture the xml of the job by navigating to ``` https://<jenkinsip>:8080/job/config.xml``` and capturing the xml configuration of the job, but Groovy takes it a step further and gives you a powerfull way to describe your deployment pipline in code. That being said, I had started this exercise of Jenkins + groovy as a way to auto-provision Jenkins without launching its WebGUI but soon came to realize that it will take me quite a bit of work and I still have not found good documentation that describles how to accomplish that, this is made even more complicated to the tie ins to 3rd party products that I need to make.

That being said, there are alot of [Jenkins](http://www.tutorialspoint.com/jenkins/) tutorials out there on the internet so in this post I focus on the Groovy aspects of Jenkins.


### Differnces between System vs Job Groovy Scrips

There are to basic ways to run Groovy code

-  As a job groovy script, this is the plain "Groovy Script" is run in a forked JVM, on the slave where the build is run. It's the basically the same as running the "groovy" command and pass in the script.

- As a system groovy script, in this mode, the groovy script runs inside the Jenkins master's JVM. In this mode, the groovy script it will have access to all the internal objects of Jenkins, so you can use this to alter the state of Jenkins itself and slave nodes. This is the Groovy Jenkins System in order to have a fully infrustrcutre as code

I want to note, when running groovy as part of the job, Can pull it and execute from an SCM or you can put the script directly into the command box that is provided


### Preparing the environment

In the last part of this post, I will describe how to quick a Jenkins environment running that I will build upon in subsequent posts.

You can run Jenkins in a Docker container and there is an official docker container describing how to do that. From what I have found, there is really no reason to run it in a full virtual machine although if you really want to do that, there are ways to get that going fairly easily provided you have java already installed. Below is an Ansible playbook for deploying Jenkins

<script src="https://gist.github.com/mugithi/4ae26ef24f6fd8431c57a731f2baffa8.js"></script>

To configure the Jenkins container, use the following Dockerfile forked from the [official](https://hub.docker.com/_/jenkins/) Docker image.  

<script src="https://gist.github.com/mugithi/a7fb08d3a45edcdabe6c649377ea98df.js"></script>

If you are converting an existing install to a docker machine, you can pull the versions of plugins installed by using the following command against Jenkins console located at the url ```http://jenkinsurl/script```

<script src="https://gist.github.com/mugithi/5dd42507568f724199fcfdfdda267a1b.js"></script>

Once you have a list of plugins that you need to install, you would add them to the ```plugins.txt``` to specify the plugins that I need installed and will be using in Jenkins.

```
[jenkins] pwd
/Users/github/github/jenkins-server/jenkins
[jenkins] tree .                                                                                         
.
├── Dockerfile
├── README.md
├── init.groovy
├── install-plugins.sh
├── jenkins-support
├── jenkins.sh
├── plugins
│   └── plugins.txt  <--- this file
└── plugins.sh

```

To install the containers and install the plugins, you first build the docker image locally then run that image as a container as shown below..

```
[jenkins] pwd
/Users/github/github/jenkins-server/jenkins
[jenkins] docker build . -t mugithi/jenkins:20
[jenkins] docker run -p 80:8080 -p 50000:50000 -v /jenkins:/var/jenkins_home mugithi/jenkins:20

*************************************************************
*************************************************************
*************************************************************

Jenkins initial setup is required. An admin user has been created and a password generated.
Please use the following password to proceed to installation:

7a4fc92xxxxxxxxxxxxxxxxxxxxaf8sa <--- Jenkins container password

This may also be found at: /var/jenkins_home/secrets/initialAdminPassword

*************************************************************
*************************************************************
*************************************************************

```


After running the container, you can reach the Jenkins port by navigating to port [http://jenkinshost](https://jenkinshost) and you log in using the password from the docker logs.

Now, if configuring a Freestyle Project, it is fairly easy to setup a job using the console or even the groovy DSL and this works as expected. You would go ahead and add your groovy code in either the following two places in the job.

- Execute Groovy as main job or part of a build step.

<img src="http://i.imgur.com/4etNbma.png" width="330">

- Execuite Groovy Script as part of the post build of a job after the job run completes

<img src="http://i.imgur.com/WzRbIAh.png" width="330">


I wanted to use the new pipeline feature with Pipeline as code and nice visualization features. For that I had to install the Pipeline plugin and use the multi-pipeline item. I will describe in the following blog how I got this configured.
