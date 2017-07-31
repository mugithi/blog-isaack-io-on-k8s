---
layout: post
title: "Configuring NGINX as load balancer"
excerpt: "How to configure nginx as a container for use as a load balancer..."
categories: [How to]
---


1. Install NGINX into systems

```bash
root@114b0ae90aa8:/# apt-get install nginx -y
```

2. Navigate to /etc/nginx/sites-available/default and add the following files


```bash
root@114b0ae90aa8:/# cat /etc/nginx/sites-available/default
upstream containerapp {
	server 172.17.0.2:2368;
	server 172.17.0.3:2368;
}

server {
	listen *:80;
	server_name 10.211.55.14;
	index index.html index.htm index.php;

	access_log /var/log/nginx/localweb.log;
	error_log /var/log/nginx/logerr.log;

	location / {
		proxy_pass http://containerapp;
	}
}
```

3. Add the start nginx configuration to basic


```bash
root@114b0ae90aa8:/# echo 'service nginx start' >> ~/.bashrc
```
