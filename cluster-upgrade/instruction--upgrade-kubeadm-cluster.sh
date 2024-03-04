# ##################################################################
# this file is a file with notes only. it's not for an execution
# this file has .sh extention only because it's easier to read a content of a file with such an extention

# main reference:
# https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/
# ##################################################################


######## Prepare

apt update
apt-cache madison kubeadm # shows all the supported versions
# pick one



######## Upgrading control plane nodes

# a. Upgrade kubeadm
apt-mark unhold kubeadm && \
apt-get update && apt-get install -y kubeadm='1.27.0-00' && \
apt-mark hold kubeadm # replace x in 1.29.x-* with the latest patch version
# no change is visible in `kubectl get nodes` output 
# as the agent that provide such info is kubelet, which is not upgraded yet

# b. checks
kubeadm version # Verify that the download works and has the expected version
kubeadm upgrade plan # show details of currest versions breakdown and other useful details

# c. apply upgrade
sudo kubeadm upgrade apply v1.29.x

# (d. Manually upgrade your CNI provider plugin)

# (e. For the other control plane nodes)
sudo kubeadm upgrade node # instead of `sudo kubeadm upgrade apply`


# f. drain
kubectl drain <node-to-drain> --ignore-daemonsets

# g. Upgrade kubelet and kubectl 
# Upgrade the kubelet and kubectl
apt-mark unhold kubelet kubectl && \
apt-get update && apt-get install -y kubelet='1.27.0-00' kubectl='1.27.0-00' && \
apt-mark hold kubelet kubectl
# Restart the kubelet
sudo systemctl daemon-reload
sudo systemctl restart kubelet

# h. Uncordon the node
kubectl uncordon <node-to-uncordon>




######## Upgrading a worker node (with draining)

# a. ssh to the node

# b. Upgrade kubeadm
sudo kubeadm upgrade node 

# c. apply upgrade
sudo kubeadm upgrade node

# d. from the control plane!, drain
kubectl drain <node-to-drain> --ignore-daemonsets

# e. from the node!, upgrade and kubelet and kubectl
# Upgrade the kubelet and kubectl
apt-mark unhold kubelet kubectl && \
apt-get update && apt-get install -y kubelet='1.29.x-*' kubectl='1.29.x-*' && \
apt-mark hold kubelet kubectl
# no need to restart services (?)

# h. Uncordon the node from the controlplane
kubectl uncordon <node-to-uncordon>




######### All together

# TASK:
# Upgrade the current version of kubernetes from 1.26.0 to 1.27.0 exactly using the kubeadm utility. Make sure that the upgrade is carried out one node at a time starting with the controlplane node. To minimize downtime, the deployment gold-nginx should be rescheduled on an alternate node before upgrading each node.

root@controlplane:~# kubectl drain controlplane --ignore-daemonsets
root@controlplane:~# apt update
root@controlplane:~# apt-get install kubeadm=1.27.0-00
root@controlplane:~# kubeadm upgrade plan v1.27.0
root@controlplane:~# kubeadm upgrade apply v1.27.0
root@controlplane:~# apt-get install kubelet=1.27.0-00
root@controlplane:~# systemctl daemon-reload
root@controlplane:~# systemctl restart kubelet
root@controlplane:~# kubectl uncordon controlplane

#Before draining node01, we need to remove the taint from the controlplane node

# Identify the taint first. 
root@controlplane:~# kubectl describe node controlplane | grep -i taint

# Remove the taint with help of "kubectl taint" command.
root@controlplane:~# kubectl taint node controlplane node-role.kubernetes.io/control-plane:NoSchedule-

# Verify it, the taint has been removed successfully.  
root@controlplane:~# kubectl describe node controlplane | grep -i taint


root@controlplane:~# kubectl drain node01 --ignore-daemonsets

# SSH to the node01 and perform the below steps as follows: -
root@node01:~# apt update
root@node01:~# apt-get install kubeadm=1.27.0-00
root@node01:~# kubeadm upgrade node
root@node01:~# apt-get install kubelet=1.27.0-00
root@node01:~# systemctl daemon-reload
root@node01:~# systemctl restart kubelet

root@controlplane:~# kubectl uncordon node01
root@controlplane:~# kubectl get pods -o wide | grep gold # (make sure this is scheduled on a node)





kubectl -n admin2406 get deployment -o custom-columns=DEPLOYMENT:.metadata.name,CONTAINER_IMAGE:.spec.template.spec.containers[].image,READY_REPLICAS:.status.readyReplicas,NAMESPACE:.metadata.namespace --sort-by=.metadata.name > /opt/admin2406_dat