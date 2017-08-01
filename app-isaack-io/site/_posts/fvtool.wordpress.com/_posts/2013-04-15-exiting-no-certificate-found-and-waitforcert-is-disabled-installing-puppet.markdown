---
author: mugithi
comments: true
date: 2013-04-15 06:56:03+00:00
layout: post
#link: https://fvtool.wordpress.com/2013/04/15/exiting-no-certificate-found-and-waitforcert-is-disabled-installing-puppet/
slug: exiting-no-certificate-found-and-waitforcert-is-disabled-installing-puppet
title: Exiting; no certificate found and waitforcert is disabled - Installing puppet
wordpress_id: 198
categories:
- VMware VCloud
tags:
- Exiting; no certificate found and waitforcert is disabled
---

I had this error today when trying to install puppet that just buffled me. It got this message when trying to generate a SSL certificate from the puppet-master. I had previously tried running

On puppet Master

    
    <code>puppet cert sign --all
    puppet cert clean --all</code>



On the Agent

    
    <code>rm -rf /var/lib/puppet/ssl/*</code>



But still nothing when I tried to generate the SSL cert from PuppetMaster


    
    <code>root@ubuntu1:~# puppet agent --no-daemonize --onetime --verbose
    Exiting; no certificate found and waitforcert is disabled</code>



It turns out the client requests the revocation list from the master, you can disable that by setting it's property to false. You add this line in the puppet.conf file


    
    <code>root@ubuntu1:~# cat /etc/puppet/puppet.conf
    [main]
    logdir=/var/log/puppet
    vardir=/var/lib/puppet
    ssldir=/var/lib/puppet/ssl
    rundir=/var/run/puppet
    factpath=$vardir/lib/facter
    templatedir=$confdir/templates
    prerun_command=/etc/puppet/etckeeper-commit-pre
    postrun_command=/etc/puppet/etckeeper-commit-post
    <font color="#FF0000">certificate_revocation = false</font>
    server=puppet-razor.karanja.local
    [master]
    # These are needed when the puppetmaster is run by passenger
    # and can safely be removed if webrick is used.
    ssl_client_header = SSL_CLIENT_S_DN
    ssl_client_verify_header = SSL_CLIENT_VERIFY</code>



Then run 
On puppet Master

    
    <code>puppet cert sign --all
    puppet cert clean --all</code>



On the Agent

    
    <code>rm -rf /var/lib/puppet/ssl/*</code>



Then you can then you can now generate a new cert successfully 


    
    <code>root@ubuntu1:~# puppet agent --no-daemonize --server puppet-razor.karanja.local --onetime --verbose
    info: Creating a new SSL key for ubuntu1.karanja.local
    info: Caching certificate for ca
    info: Creating a new SSL certificate request for ubuntu1.karanja.local
    info: Certificate Request fingerprint (md5): 76:DA:A4:D2:A0:92:4E:94:7B:3F:34:B5:EF:F1:F0:29
    Exiting; no certificate found and waitforcert is disabled</code>



And then sign it from the master

    
    <code>root@puppet-razor:~# puppet cert --list
      "ubuntu1.karanja.local" (76:DA:A4:D2:A0:92:4E:94:7B:3F:34:B5:EF:F1:F0:29)
    root@puppet-razor:~# puppet cert sign "ubuntu1.karanja.local"
    notice: Signed certificate request for ubuntu1.karanja.local
    notice: Removing file Puppet::SSL::CertificateRequest ubuntu1.karanja.local at '/etc/puppetlabs/puppet/ssl/ca/requests/ubuntu1.karanja.local.pem'</code>
