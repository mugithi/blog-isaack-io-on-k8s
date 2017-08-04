---
layout: post
title: "Jenkins CICD Getting started with Groovy and Docker Containers - Part 2"
excerpt: "In this blog I describe how to configure Jenkins to automatically run a build after a code checkin in Github..., "
categories: [CICD, Jenkins, Groovy]
---

This blog is a continuation of [part 1](https://blog.isaack.io/articles/2016-08/Jenkins-CICD-Getting-Started-With-Groovy-Part-1) where I describe how to get the Jenkins master container configured.

### Review of the workflow

Here is the workflow I use to post to my blog website.

- I write the post using (github atom ide) in a local checkout of the blog source code. The blog is hosted on a Jekyll site and to write I use Macdown. Atom also has great visulization tools for Jekyll websites.
- Once I finish writing, I push to github. Github then pushes a webhook to Jenkins for a build to start. This build is described using Jenkins Jenkinsfile.
- Jenkins then builds a docker Jekyll site and pushes it to my staging site for me to review how the site looks like. I then get a prompt from Jenkins YAY/NAY on whether the push the site to production.
- Once I am ok with the site, I push it to production. Below is an image on how the flow looks like

![](https://i.imgur.com/aKWiVjJ.png)


### Configuring Jenkins

The first step is to configure Jenkins with Github. Is accomplished by configuring the Github-Plugin that was installed in [part 1](https://blog.isaack.io/articles/2016-08/Jenkins-CICD-Getting-Started-With-Groovy-Part-1) as one of the plugins.

Navigate to the the url ```https://jenkins/configure```. Scroll down to the section labeled Github. Select Github -> Advanced

![](https://i.imgur.com/0FXcw4N.jpg)

Select **Convert login and Password Token** from **Login and password**. Type in your Github username and password and select **create token credentials**

![](https://i.imgur.com/9b9kAr2.jpg)

Apply the credentials to Github. Under GitHub API URL, ensure that this is set to ```https://api.github.com``` and under **credentials** select the token credentials that you just created.

![](https://i.imgur.com/Ew15vSb.jpg)


#### Configuring Github

I will be configuring one of my repos to send webhooks to Jenkins to trigger a build. To do that I need to navigate to my github page in the dockerfile and edit the settings page for the particular repo

![](https://i.imgur.com/nh1CUCC.jpg)

Under **integrations and webhooks**, select **add service** and search for the **Jenkins (Github Plugin)**

![](https://i.imgur.com/0OQt0V1.jpg)

Navigate to **webhooks** and under **Jenkins hook url**, add your Jenkins URL ```https:/jenkin/github-webook/``` and click test service to send a post pull requqest to the Jenkins API webook

![](https://i.imgur.com/Vv7ACib.jpg)

#### Usings a Jenkinsfile to configure jenkins pipeline

When I started down the Jenkins path, my purpose was to be able to describe a Jenkins Build job using code. To do that you use Groovy in a Jenkinsfile.

You start by setting up a multibranch pipeline. Navigate to the following url ```https://jenkins/view/All/newJob```.

Enter the name of the new build multibranch pipeline and click ok. The multibranch pipeline is enabled using the [Multi-Branch Pipeline plugin](https://wiki.jenkins-ci.org/display/JENKINS/Pipeline+Multibranch+Plugin)

![](https://i.imgur.com/sLTXLk5.png)


Under the Multibranch pipeline configuration, go ahead and and select the **github repo**,  **github username** and github **credentials**

![](https://i.imgur.com/TgNFkRY.png)

Below I have an example of the Jenkinsfile that describes my Jenkins workflow.

<script src="https://gist.github.com/mugithi/a81d2a9ed4a45fc119fd58470a519b27.js"></script>


Once you have this setup, you get the pipeline visualization on Jenkins

![](https://i.imgur.com/YOBtmeF.png)
