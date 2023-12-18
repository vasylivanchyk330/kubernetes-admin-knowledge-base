# ##################################################################
# this file is a file with notes only. it's not for an execution
# this file has .sh extention only because it's easier to read a content of a file with such an extention
# ##################################################################

# sometimes there might be external etcd
# so in this instruction, I compare handling for internal and external

# cluster1 -- using internal etcd
# cluster2 -- using external etcd


# 1. exploring
# INTERNAL:
kubectl config use-context cluster1
kubectl get po -A
kubectl get pods -n kube-system | grep etcd # output: etcd-cluster1-controlplane
kubectl get pods -n kube-system etcd-cluster1-controlplane -oyaml

# EXTERNAL:
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



# 5. Example of back up restore for internal etcd

# INTERNAL
kubectl config use-context cluster1
kubectl get no
ssh cluster1-controlplane

ETCDCTL_API=3 etcdctl --endpoints=https://192.12.123.3:2379 \
--cacert=/etc/kubernetes/pki/etcd/ca.crt \
--cert=/etc/kubernetes/pki/etcd/server.crt \
--key=/etc/kubernetes/pki/etcd/server.key \
snapshot save /opt/cluster1.db

# (optional) if you need to have it on your jump host (being sshed on your jumphost)
scp cluster1-controlplane:/opt/cluster1.db /opt

# for external the process is similar, - you  have to run the command 
# being etcd-server sshed


# 6. Example of restoring a backup for external etcd: 

# EXTERNAL
# a. ssh to the etcd-server (you should have the backup already there)
ETCDCTL_API=3 etcdctl --endpoints=https://127.0.0.1:2379 \
    --cacert=/etc/etcd/pki/ca.pem \
    --cert=/etc/etcd/pki/etcd.pem \
    --key=/etc/etcd/pki/etcd-key.pem \
    snapshot restore /root/cluster2.db --data-dir /var/lib/etcd-data-new
# b. Update the systemd service unit file for etcd by running `vim /etc/systemd/system/etcd.service` and add the new value for data-dir
[Unit]
Description=etcd key-value store
Documentation=https://github.com/etcd-io/etcd
After=network.target

[Service]
User=etcd
Type=notify
ExecStart=/usr/local/bin/etcd \
  --name etcd-server \
  --data-dir=/var/lib/etcd-data-new  # this

# c. make sure the permissions on the new directory is correct (should be owned by etcd user)
 ls -ld /var/lib/etcd-data-new/
# output: drwx------ 3 etcd etcd 4096 Sep  1 02:41 /var/lib/etcd-data-new/

# d. reload and restart the etcd service
systemctl daemon-reload 
systemctl restart etcd

# e.  (optional): It is recommended to restart controlplane components (e.g. kube-scheduler, kube-controller-manager, kubelet) to ensure that they don't rely on some stale data.
kubectl delete po <pods for kube-scheduler, kube-controller-manage etc.>
sudo systemctl restart kubelet