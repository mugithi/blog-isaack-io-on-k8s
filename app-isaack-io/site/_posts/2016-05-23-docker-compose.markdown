---
layout: post
title: "Docker Compose"
excerpt: "Using docker compose v2 along with all its enhancements to services, networks and volumes to build the following environment that connects an app and db using overlay networks..."
categories: [Docker, Networking]
---
#### Docker Compose

I am using docker compose v2 along with all its enhancements to services, networks and volumes to build the following environment. I will describle a Docker Compose YAML file that describles the ```mariadb:nginx_php```application.

![](http://i.imgur.com/8t6x0Oh.png)


Install docker compose

  ```bash
  curl -L https://github.com/docker/compose/releases/download/1.7.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
  ```

### Docker compose

#### Build

Docker compose can be used to build images by pulling images from a docker registry or building them using a docker file.

I chose build my own image using a docker file starting with the base ubuntu image so that I had more fine grained control of what ended up in the images.

The docker file describing the app service looked like the following

  ```YAML

  version: '2'
  services:

  ########################	- Create the application service -		########################
   app:
    build: app/.				    	#->I build the app service from a Dockerfile located from docker-compose.yml directory app directory
    environment:			     		#-> Variables to be passed into shell during the build
     MYSQL_ROOT_PASSWORD: dpass
     MYSQL_DATABASE: drupal
     MYSQL_USER: drupaluser
     DRUPAL_USER: duser
     DRUPAL_PASSWORD: dpass
    ports:						#-> Ports being mapped to the external application
     - "80:80"
    depends_on:
     - db							#-> In the app depended on the db service, compose first start the app service
    networks:						#-> The app service had two IP addresses in front and back networks
     front:
      ipv4_address: 10.10.10.2
     back:
      ipv4_address: 10.10.11.2
    volumes:						#-> I created two volumes that had the initialization code and the code to run the site
      - ./files:/files


  ########################	- Create the database service -		########################
   db:
    build: db/.         #-> The db service had one IP addresses in back networks, with this setup, I did not have to link the two containers
    networks:
     back:
      ipv4_address: 10.10.11.3
  ```

****

#### A word on docker Volumes
Union FS is emphimeral to the docker container, when you shut down the container, the data that is located in the container is lost.

There are basically three ways to store data in container, some being persistant and some being non persistant

- **Write data to the local file system of the container**
	- This writes data to the containers Union File System
	- Changes will revert back when container is stopped (Non persistant)
	- Data cannot be shared between two containers

- **Write to mounted volumes in directory from the host**
	- This bypass docker's union file system and writes to the host's file system
	- Data can be shared between two containers within the same docker host.
	- The data is persistant provides the fastest read and write access to the data
	- There are basicaly two ways to write data to the host file system
		- ```-v /host/dir:/container_dir``` **This mounts a specified directory on host**.
			- This option can be used to mount NFS iSCSI from the host file system.
			- This option does not provide consistant results and is not [prefered](https://groups.google.com/d/msg/docker-user/EUndR1W5EBo/4hmJau8WyjAJ) for use in production. One ok use case is to copying files to the container.
			- The host directory is **NOT PORTABLE** with the container
		- ```-v /container_dir``` **This option will create a randomly generated path name**
			- The data is then  stores the data under ```/container_dir``` on the host file system on the path under ```/var/lib/docker/volumes/<random_vol_id>/container_dir```
			- With this option, you **DO NOT** specify the host source directory
			- This volume is portable with the container.

- **Write to a volume mounted from other container (depricated use case - Can be used for production)**
	- This **WAS** the prefered way to store persistant data on containers.
	- You first start by creating what is called a ***data only-container***,that is a container with a volume mounted to it from a host file system.
	- ```docker create -v /container_dir --name data_container_name container_repo/image``` :create data-only container - you run this only once, the container does not need to powered on to serve the volume.
	- The volumes from the data only container are then mounted to the container that needs persistant storage
	-  ```docker run -d --volumes-from data_container_name --name db1 container_repo/image```
	- In order to reduce space usage, it is recomended to use the same image for a container and a data-only container
	- The volumes from the data-only container can be presented to multiple containers allowing you share the data among different containers.
	- Persistance determined by storing data on the docker host from the data-only container

- **Mount volumes from shared storage from shared storage (Named volumes - Used for production)**
	- Can mount Iscsi, FC, NFS storage - options are dependnt on the on storage driver in use
	- Data can be shared between two containers. Provide persistant storage to containers
	- The volumes are docker host independent & can be shared across hosts
	- Volume drivers create volumes by names instead of path like other methods
	- ```--volume-driver=flocker -v my-named-volume:/opt/webapp --name web training/webapp ```

****

1. This is how the network configuration looked like, I was using the overlay driver to allow the two services to adhere to the docker philosphy of not being tied to a particular host.

    ```yaml
    networks:
     front:
      driver: overlay
      ipam:
       config:
        - subnet: 10.10.10.0/24
          gateway: 10.10.10.1
     back:
      driver: overlay
      ipam:
       config:
        - subnet: 10.10.11.0/24
          gateway: 10.10.11.1

    ```

2. Sice I am building the application service from a Dockerfile, I had the following file in the  ```app/Dockerfile``` folder from the docker-compose.yml root directory.

    ```bash

    #Built from Ubuntu
    FROM ubuntu:14.04
    #

    # #Install php deps, mysql client,
    RUN apt-get -y update && apt-get install -y \
    nginx \
    nginx-extras \
    php5-fpm \
    drush \
    mysql-client \
    php5-gd \
    php-db \
    php5-cgi \
    php5-cli

    ENTRYPOINT ["files/build/entrypoint.sh"]

    EXPOSE 80

    CMD ["nginx", "-g", "daemon off;"]

    ```

3. As you can see, this is a very simple file with most of the action being performed by the ```files/build/entrypoint.sh```. The entrypoint file as shown below.


    ```bash

    #!/bin/bash
    set -e

    echo "------------------------------------------| Wait for it... Wait for it... mariadb is starting"
    for i in {10..0}; do
      echo "------------------------------------------| mariadb-server container is initalizing.... $i "
      files=$(mysql -uroot -h db -e "GRANT USAGE ON *.* TO ping@'%' IDENTIFIED BY 'ping';")
      if [ $? == 0 ]; then
        echo "------------------------------------------| Creating  DB Drupal user & DB, Clean up DB"
        sleep 3
        mysql -uroot -h db -e "FLUSH PRIVILEGES ;"
        mysql -uroot -h db -e "CREATE DATABASE IF NOT EXISTS $MYSQL_DATABASE;"
        mysql -uroot -h db -e "GRANT ALL PRIVILEGES ON $MYSQL_DATABASE.* TO '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';"
        mysql -uroot -h db -e "FLUSH PRIVILEGES ;"
        break
      fi
          sleep 1
          continue
    done
    #
    echo "------------------------------------------| Fix Nginx for Drupal"
    rm -rf /etc/nginx/sites-enabled/default
    ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default
    sed -i 's=;cgi.fix_pathinfo\=1=cgi.fix_pathinfo\=0=g' /etc/php5/fpm/php.ini
    cp /files/config/default /etc/nginx/sites-available/default
    cp /files/config/www.conf /etc/php5/fpm/pool.d/www.conf

    echo "------------------------------------------| Install Drupal Content Management System"
    cd /usr/share/nginx/
    #cd /usr/share/nginx/
    rm -rf html/
    drush dl drupal --drupal-project-rename=html
    cd html/
    drush site-install -y standard --account-name=$DRUPAL_USER --account-pass=$DRUPAL_PASSWORD --db-url=mysql://$MYSQL_USER:$MYSQL_PASSWORD@db/$MYSQL_DATABASE --site-name=isaack.io

    echo "------------------------------------------| Restore the old drupal site from sql dump"
    chown www-data:www-data /usr/share/nginx/html/sites/default/files/
    mysql -uroot -h db --database drupal < /files/data/file.sql

    echo "------------------------------------------| Restart Nginx And check for any fault status before layer is closed"
    service nginx restart

    echo "------------------------------------------| Start php5-fsm And check for any fault status before layer is closed"
    service php5-fpm start

    echo "------------------------------------------| Tailing logs"
    tail -f /var/log/nginx/error.log

    ```

#### A note on Docker Security
Rule 1 with containers is **DO NOT STORE YOUR CREDENTIALS ARTIFACTS IN CONTAINER.** It is common practise to set your passwords using the  variables set enviromental in the ```docker-compose.yml``` and or the ```Dockerfile```file are only available during container runtime. Without getting too complicated, if using usernames and passwords, it is best to use an entrypoint call to initalize the container. Calling entrypoint allows you to use the env variables avoiding passwords being stored in the image layers during build time. When using compose you can specify a enviromental file ```env_file:``` in docker-compose.yml and ignore it in the .dockerignore file to prevent it from it being pushed to your docker repository.

Unfortunately, this is still not secure and one is still able to see the variables set in a container by running docker inspect on a running container, this situaiton is made worse by the fact that there is really no authentication when connecting to a docker api. One solution for ensuring that your security keys and other artifacts do not end up on the docker image is using [habitus](http://blog.cloud66.com/using-ssh-private-keys-securely-in-docker-build/). I will dig into this in a future post.

Final directory structure looked like this.

  ```bash

  ~/Dropbox/Documentation/Python/SCRIPTS/CLEAN_SCRIPTS/docker/drupal_2_tier(branch:v1*) » tree .                              
  ├── app
  │   ├── Dockerfile
  │ 
  ├── db
  │   └── Dockerfile
  ├── docker-compose.yml
  └── files
      ├── build
      │   └── entrypoint.sh
      ├── config
      │   ├── default
      │   └── www.conf
      └── data
          └── file.sql

  6 directories, 8 files
  ------------------------
  ```
