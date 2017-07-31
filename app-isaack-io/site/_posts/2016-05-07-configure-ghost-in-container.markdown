---
layout: post
title: "Configure Ghost in a Container "
excerpt: "Starting with OSX, this is how you configure Ghost to run in a docker container and push to AWS"
categories: [Docker, How to, Ghost]
---

### Install docker-machine in OSX 10

```bash

(branch:v1*) » sudo curl -L https://github.com/docker/machine/releases/download/v0.6.0/docker-machine-`uname -s`-`uname -m` > /usr/local/bin/docker-machine && \\nchmod +x /usr/local/bin/docker-machine
```

###### Docker Machine AWS Enviroment

Install AWS driver

```bash

(branch:v1*) »  cat ~/.aws/credentials                                                                                                                                            
[default]
aws_access_key_id = xxxxxxxxxxxxxxxxxxx
aws_secret_access_key = xxxxxxxxxxxxxxxxxxx
region = us-west-1
```

Create an EC2 instance in us-west-1b called docker-standbox and install docker in it using docker-machine

```bash

(branch:v1*) » docker-machine create --driver amazonec2 --amazonec2-zone=b docker-sandbox
```

Initailize the docker enviroment with variables

```bash

(branch:v1*) » docker-machine env amaz
(branch:v1*) » eval $(docker-machine env amaz)
```

###### Docker Machine Local Enviroment

Install Parallel driver

```bash

(branch:v1*) » docker-machine create --driver amazonec2 docker-sandbox
```

Build base image ghostblog

```bash

(branch:v1*) » cat docker/Dockerfile
FROM ubuntu:14.04
MAINTAINER mugithi  <mugithi@gmail.com>
RUN apt-get update -y && \
apt-get install -y npm curl unzip && \
mkdir -p /var/www/ && \
curl -L https://ghost.org/zip/ghost-latest.zip -o ghost.zip && \
unzip -uo ghost.zip -d /var/www/ghost && \
cd /var/www/ghost && \
ln -s /usr/bin/nodejs /usr/bin/node && \
npm install --production && \
sed -i 's\127.0.0.1\0.0.0.0\' /var/www/ghost/config.example.js && \
echo "cd /var/www/ghost && npm start --production &" >> ~/.bashrc
```

Build the image and push it to dockerhub

```bash

(branch:v1*) » docker build --force-rm=true --rm=true --no-cache -t=mugithi/ghosblog:v1  .
```

Make changes to the blog and commit those changes to the docker image

```

(branch:v1*) » docker commit 323b68138583 mugithi/ghostblog:v1
```

Push the changes to docker hub

````

(branch:v1*) » docker login --username=xxxx --email=xxxx@gmail.com
(branch:v1*) » docker push mugithi/ghostblog:v1
````
