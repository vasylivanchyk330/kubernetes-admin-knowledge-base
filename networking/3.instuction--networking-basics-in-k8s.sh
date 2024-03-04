

# ################################
# CNI
# ################################

# set of standards for container runtimes (CRs) and plugins to unify network connectivity for containers approach across the industry 
# created and maintained by Cloud Native Computing Foundation 
# some main characteristics:
    # CRs must create nw ns, veth-s pairs
    # CRs must attach a cont to that nw ns
    # CRs must support cli argument ADD/DEL/CHECK
    # CRs must invoke Network Plugin (bridge) when cont is added or deleted to/from nw ns
    # CNI plugins handle IP address management
    # ... and nw resource cleanup
    # JSON format of nw configs
    # when using k8s, kubelet invokes CNI plugins to work with containers
# the CNI bridge workflow
    # 1. create bridge nw ns and if
    # 2. create veth pairs 
    # 3. attach one end of veth to the nw
    # 4. attach other end to the bridge
    # 5. assign ip address
    # 6. bring the if UP
    # 7. enable NAT-IP MASQUARADE 
# come out of the box with plagins:
    # bridge
    # VLAN
    # IPVLAN
    # MACVLAN
    # Windows  
    # etc.

# docker has it's own standard -- CNM
# make possibel CNI standards work with docker, do
    docker run --network=none nginx
    bridge add <cont-id>  /var/run/netns/<cont-id>
# this is actually what k8s does under the hood when working with docker conts




# ################################
# Cluster Networking in k8s
# ################################

# each node must have at least one if connetcet to the cluster network
# each if must have ip 
# each host must have its unique dns name and MAC address

# must-have ports:
    # 2379 - etcd 
    # 2380 - etcd clients (if you have multi-master architecture); peer to peer connectivity
    # 6443 - kube-apiserver service
    # 10250 - kubelet
    # 10259 - kube-scheduler
    # 10257 - kube-conroller-manager
    # 30000-32767 - workernode NodePort services
#



# ################################
# handson working with basic nw in k8s
# ################################

# to get the network if of a node, e.g. controlplane
# (being sshed onto node your checking details of)
k get no -owide # see the ip of controlplane
ip a | grep -B2 192.24.219.9 # -B2   -- for including 2 lines Before the output

# show default gateway 
ip route show default # or
netstat -nr | grep '^0.0.0.0' # n-dont resolve names; r-show routing table

# what's ports etcd client is listening on to
netstat -anp | grep etcd # a-all; n-dont resolve names; p-desplay pid name sockets

# get which port is more listened to 
netstat -anp | grep etcd | grep 2380 | wc -l 
netstat -anp | grep etcd | grep 2379 | wc -l 

# tbc




# ################################
# pod nw
# ################################

# k8s pod nw model is simple
    # every pod must have an IP address
    # every pod must be able to communicate with every other pod in the same node same as with every other pod in the cluster without NAT





# ################################
# CNI in k8s
# ################################

# CNI is configured in kubelet.service files

ExecStart=/usr/local/bin/kubelet \\
--config=/var/lib/kubelet/kubelet-config.yaml \\
--container-runtime=remote \\
--container-runtime-endpoint=unix:///var/run/containerd/containerd.sock \\
--image-pull-progress-deadline=2m \\
--kubeconfig=/var/lib/kubelet/kubeconfig \\
--network-plugin=cni \\  # here
--cni-bin-dir=/opt/cni/bin \\ # here
--cni-conf-dir=/etc/cni/net.d \\ # and here
--register-node=true \\
--v=2

ps -aux | grep kubelet # View kubelet options
ls /opt/cni/bin # here - all the supported CNI plugins installed
ls /etc/cni/net.d #  determine the CNI plugins and configurations that Kubernetes will use for networking
# e.g. :
cat /etc/cni/net.d/10-bridge.conf
{
    "cniVersion": "0.2.0",
    "name": "mynet",
    "type": "bridge",
    "bridge": "cni0",
    "isGateway": true,
    "ipMasq": true,
    "ipam": {
        "type": "host-local",
        "subnet": "10.22.0.0/16",
        "routes": [
            { "dst": "0.0.0.0/0" }
        ]
    }
}


# ################################
# services in k8s
# ################################

# kube-proxy, installed on each node, is the component that manages services.
# in fact, a service is just an abstract term. under the hood, kube-proxi 
# does all.
# the component usually deployed as a pod by a DeamonSet (on each node of the cluster)

# there are 3 proxi modes: [userspace | iptablkes | ipvs ]
    # userspace -- oldest, currently depricated; user-spaces for routing
    # iptables -- configures the node's iptables rules to perform connection redirection; ok but still not that efficient
    # ipvs (ip virtual server) -- now, that's a good enough.  based on the netfilter hook function in the Linux kernel and uses a hash table as the underlying data structure
# to check what type of proxy mode is set:
k -n kube-system logs kube-proxy-5pnh2

# to get network range of services on a cluster 
kube-api-server --service-cluster-ip-range ipNet #or
cat /etc/kubernetes/manifests/kube-apiserver.yaml | grep service-cluster-ip-range # or
ps aux | grep service-cluster-ip-range # or 
kubectl -n kube-system get cm kubeadm-config -o yaml | grep serviceSubnet

# to get network range of the cluster nodes
ip a | grep eth0 # find the ip of a node
ipcalc -b 10.33.39.8 # the command provide stats for an ip address; btw, very handy

# in "kubectl -n kube-system get cm kubeadm-config -o yaml" output you can find alot of useful info about ip ranges





# ################################
# DNS in k8s
# ################################

# Kubernetes uses CoreDNS (or kube-dns in older versions) as its DNS service
# as a set of Pods within the cluster, usually in the kube-system namespace; its deployed as ReplicaSet within Deployment

# when a Service is created, it is automatically assigned a DNS entry by CoreDNS

# Kubernetes clusters are configured with a default DNS domain (usually cluster.local)

# a Service named my-service in the my-namespace namespace can be accessed at my-service.my-namespace.svc.cluster.local
# pay attention to the hierarchy: (down-up)
    # svc name
    # ns name
    # `svc`
    # cluster name (`cluster.local` by default)

#  Kubernetes DNS also supports ExternalName Services


# sys dns resolution conf
cat /etc/resolv.conf
# coreDNS config file
cat /etc/coredns/Corefile 
# info 
kubectl get configmap –n kube-system coredns -oyaml

# ifnfo about dns svc
kubectl get service –n kube-sytem kube-dns

# e.g. you can fine namely kubelet dns settings also here 
cat /var/lib/kubelet/config.yaml

# nslookup from a pod in A-ns for svc in payroll-ns
kubectl exec -it hr -- nslookup mysql.payroll