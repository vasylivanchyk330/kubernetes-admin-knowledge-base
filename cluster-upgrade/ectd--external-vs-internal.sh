# ##################################################################
# this file is a file with notes only. it's not for an execution
# this file has .sh extention only because it's easier to read a content of a file with such an extention
# ##################################################################

# sometimes there might be external etcd
# so in this instruction, I compare inspection for internal and external

# cluster1 -- using internal
# cluster2 -- using external


# 1. exploring
# I
kubectl config use-context cluster1
k get po -A
kubectl get pods -n kube-system | grep etcd # output: etcd-cluster1-controlplane
kubectl get pods -n kube-system etcd-cluster1-controlplane -oyaml

# E
kubectl config use-context cluster2
kubectl get pods -n kube-system  | grep etcd # no pod
ssh cluster2-controlplane 
ps -ef | grep etcd # outputs process with `kube-apiserver`; therefore, use also:
kubectl get pods -n kube-system kube-apiserver-cluster2-controlplane -oyaml 
#  one more thing that points that etcd is external is that the command above outputs:
    # - --etcd-cafile=/etc/kubernetes/pki/etcd/ca.pem
    # - --etcd-certfile=/etc/kubernetes/pki/etcd/etcd.pem
    # - --etcd-keyfile=/etc/kubernetes/pki/etcd/etcd-key.pem
    # - --etcd-servers=https://192.12.123.18:2379
# to find out the etcd data-dir:



#2. loggin to the external etcd
# use ssh `--etcd-servers=https://192.12.123.18:2379`
ssh 192.12.123.18
# here, servername is `etcd-server`, so you can also do 
ssh etcd-server


# 3. to find out what the external etcd data-dir is: (being sshed to `etcd-server`)
ps -ef | grep etcd 


# 4. Check the members of the cluster:
ETCDCTL_API=3 etcdctl \
 --endpoints=https://127.0.0.1:2379 \
 --cacert=/etc/etcd/pki/ca.pem \
 --cert=/etc/etcd/pki/etcd.pem \
 --key=/etc/etcd/pki/etcd-key.pem \
  member list
# output: f0f805fc97008de5, started, etcd-server, https://10.1.218.3:2380, https://10.1.218.3:2379, false



# 5. Backing up
# I
kubectl config use-context cluster1
k get no
ssh cluster1-controlplane
