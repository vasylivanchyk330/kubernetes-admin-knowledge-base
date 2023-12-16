# ##################################################################
# this file is a file with notes only. it's not for an execution
# this file has .sh extention only because it's easier to read a content of a file with such an extention

# main reference:
# https://kodekloud.com/topic/practice-test-backup-and-restore-methods/
# ##################################################################



# 1. export 
export ETCDCTL_API=3

# 2. make a one
ETCDCTL_API=3 etcdctl --endpoints=https://[127.0.0.1]:2379 \
--cacert=/etc/kubernetes/pki/etcd/ca.crt \
--cert=/etc/kubernetes/pki/etcd/server.crt \
--key=/etc/kubernetes/pki/etcd/server.key \
snapshot save /opt/snapshot-pre-boot.db

#########
# mapping, etcdctl options  ---  /etc/kubernetes/manifests/etcd.yaml:
# cert   --- cert-file
# key    --- key-file
# cacert --- trusted-ca-file

# status. 
ETCDCTL_API=3 etcdctl \
snapshot status /opt/snapshot-pre-boot.db

# 3. restore
ETCDCTL_API=3 etcdctl \
snapshot restore  /opt/snapshot-pre-boot.db \
--data-dir /var/lib/etcd-from-backup 

# 4. add record to the etcd pod manifest
vim /etc/kubernetes/manifests/etcd.yaml
# and change:
  volumes:
  - hostPath:
      path: /var/lib/etcd-from-backup # this one
      type: DirectoryOrCreate
    name: etcd-data

# As the ETCD pod has changed it will automatically restart, and also kube-controller-manager and kube-scheduler. Wait 1-2 to mins for this pods to restart. You can run the command: 
watch "crictl ps | grep etcd" 

# If the etcd pod is not getting Ready 1/1, then restart it by kubectl delete pod -n kube-system etcd-controlplane and wait 1 minute.


