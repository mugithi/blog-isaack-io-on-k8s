### Installing Kubernetes on Openstack

For this I am going to be using the Ubuntu 16.04 image on openstack. I don't have that avaiable in glance so first, I am going to upload [this](http://cloud-images.ubuntu.com/xenial/current/xenial-server-cloudimg-amd64-disk1.img) to glance.

```
cd ~/Downloads
 ✝ ~/Downloads wget http://cloud-images.ubuntu.com/xenial/current/xenial-server-cloudimg-amd64-disk1.img .

openstack image create --disk-format qcow2 --container-format bare --public --file ./xenial-server-cloudimg-amd64-disk1.img Ubuntu_16.04 --tag 'Ubuntu 16.04'

 ✝ ~/Downloads openstack image list
+--------------------------------------+----------------+--------+
| ID                                   | Name           | Status |
+--------------------------------------+----------------+--------+
| ef84759f-8af3-4a6e-86f4-65c1eb724de5 | Ubuntu 16.04   | active |
| c74fd5f0-88a1-43eb-ac39-68a54e3703a6 | CoreOS         | active |
| d0ae2937-b482-45fb-87ef-13710a3a9c40 | Ubuntu 14.04   | active |
+--------------------------------------+----------------+--------+

```

Next I am going to fire up three medium sized instances, one master and two workers

```
✝ ~/Downloads openstack server create --flavor 3 --image ef84759f-8af3-4a6e-86f4-65c1eb724de5 --security-group bdc6461d-d890-4847-b40c-d1a15b98321a --key-name docker-datacenter --nic net-id=$IP_PUBLIC Kubernetes-master
✝ ~/Downloads openstack server create --flavor 3 --image ef84759f-8af3-4a6e-86f4-65c1eb724de5 --security- ✝ ~/Downloads group bdc6461d-d890-4847-b40c-d1a15b98321a --key-name docker-datacenter --nic net-id=$IP_PUBLIC Kubernetes-worker-01 
✝ ~/Downloads openstack server create --flavor 3 --image ef84759f-8af3-4a6e-86f4-65c1eb724de5 --security-group bdc6461d-d890-4847-b40c-d1a15b98321a --key-name docker-datacenter --nic net-id=$IP_PUBLIC Kubernetes-worker-02

 ✝ ~/Downloads  nova list
+--------------------------------------+--------------------+--------+------------+-------------+-------------------------+
| ID                                   | Name               | Status | Task State | Power State | Networks                |
+--------------------------------------+--------------------+--------+------------+-------------+-------------------------+
| 7f236958-43fd-40a0-a5d5-6e7d75ab40e3 | Kubernetes-01      | ACTIVE | -          | Running     | ip_public=172.17.11.189 |
| e0a4e3de-bfc8-46c5-874b-0eca45bee045 | Kubernetes-02      | ACTIVE | -          | Running     | ip_public=172.17.11.185 |
| cab211ca-51b6-48c5-9b0e-f1bdf3e694fb | Kubernetes-master  | ACTIVE | -          | Running     | ip_public=172.17.11.186 |+--------------------------------------+--------------------+--------+------------+-------------+-------------------------+

```

I can now ssh into my instances using my key pair. I will need the following ports opened for through my internal network for the instances workers to be able to join the master. 
	- 6443
	- 9888  

I ssh into all my three instances and update the repo

```
 ✝ ~/Downloads ssh -i k8s-key-pair.pem ubuntu@172.17.11.186
 ✝ ~/Downloads curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
 ✝ ~/Downloads cat <<EOF > /etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF

```

I will also configure the `/etc/hosts` file with the IP addresses so that all the nodes can talk to each other

```
root@kubernetes-01:/home/ubuntu# cat /etc/hosts
127.0.0.1 localhost

# The following lines are desirable for IPv6 capable hosts
::1 ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
ff02::3 ip6-allhosts
50.235.88.186 kubernetes-01 kubernetes-01.isaack.io
50.235.88.185 Kubernetes-02 kubernetes-02.isaack.io
50.235.88.189 kubernetes-master kubernetes-master.isaack.io
root@kubernetes-01:/home/ubuntu#

```
After updaing the key pair, I then issue an apt-get update to load the new repository. From the repository I install docker and kubernetes 

```
sudo apt-get update && sudo apt-get install -y docker.io kubelet kubeadm kubectl kubernetes-cni

```
Once this are installed on all the nodes, I pick a node that I want to use as my master and I issue the kubeadm init command. This will intialize kubernetes and provide me with a token to use from the workers to  join the cluster


```
root@kubernetes-master:/home/ubuntu# kubeadm init
[kubeadm] WARNING: kubeadm is in alpha, please do not use it for production clusters.
[preflight] Running pre-flight checks
[init] Using Kubernetes version: v1.5.3
[tokens] Generated token: "f70882.f48177d1f7e42558"
[certificates] Generated Certificate Authority key and certificate.
[certificates] Generated API Server key and certificate
[certificates] Generated Service Account signing keys
[certificates] Created keys and certificates in "/etc/kubernetes/pki"
[kubeconfig] Wrote KubeConfig file to disk: "/etc/kubernetes/kubelet.conf"
[kubeconfig] Wrote KubeConfig file to disk: "/etc/kubernetes/admin.conf"
[apiclient] Created API client, waiting for the control plane to become ready
[apiclient] All control plane components are healthy after 42.796057 seconds
[apiclient] Waiting for at least one node to register and become ready
[apiclient] First node is ready after 3.004516 seconds
[apiclient] Creating a test deployment
[apiclient] Test deployment succeeded
[token-discovery] Created the kube-discovery deployment, waiting for it to become ready
[token-discovery] kube-discovery is ready after 20.504808 seconds
[addons] Created essential addon: kube-proxy
[addons] Created essential addon: kube-dns

Your Kubernetes master has initialized successfully!

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
    http://kubernetes.io/docs/admin/addons/

You can now join any number of machines by running the following on each node:

kubeadm join --token=f70882.f48177d1f7e42558 172.17.11.186
root@kubernetes-master:/home/ubuntu# kubectl get nodes
NAME                STATUS         AGE
kubernetes-master   Ready,master   1m
```

