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