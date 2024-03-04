# ##################################################################
# this file is a file with notes only. it's not for an execution
# this file has .sh extention only because it's easier to read a content of a file with such an extention
# ##################################################################


# curl using certs
curl https://my-kube-playground:6443/api/v1/pods \
    --key admin.key \
    --cert admin.crt \
    --cacert ca.crt \

# same with kubectl
kubectl get pods \
    --server my-kube-playground:6443 \
    --client-key admin.key \
    --client-certificate admin.crt \
    --certificate-authority ca.crt

# same with kubectl but specifying kubeconfig file where key/crt/ca info in placed
kubectl get pods --kubeconfig config

# example of a kubeconfig file
apiVersion: v1
kind: Config
clusters:
contexts:
users:
- name: my-kube-playground
- name: my-kube-admin@my-kube-playground
- name: my-kube-admin
- name: development
contexts:
- name:  my-kube-admin@my-kube-playground
- name: dev-user@google
- name: prod-user@production
users:
- name: production
- name: google
- name: admin
- name: dev-user
- name: prod-user
# the above is simplified one
# see the real one on the cluster, usually in /root/.kube/config

# to view current kubeconfig
kubectl config view
# to view custom kubeconfig (which is not a current one)
kubectl config view –kubeconfig=my-custom-config

# set usage of a particular kubeconfig
kubectl config use-context prod-user@production
kubectl config --kubeconfig=/root/my-kube-config use-context research


# more realistic example of kubeconfig
apiVersion: v1
kind: Config

clusters:
- name: production
  cluster:
    certificate-authority: /etc/kubernetes/pki/ca.crt
    server: https://controlplane:6443

- name: development
  cluster:
    certificate-authority: /etc/kubernetes/pki/ca.crt
    server: https://controlplane:6443

- name: kubernetes-on-aws
  cluster:
    certificate-authority: /etc/kubernetes/pki/ca.crt
    server: https://controlplane:6443

- name: test-cluster-1
  cluster:
    certificate-authority: /etc/kubernetes/pki/ca.crt
    server: https://controlplane:6443

contexts:
- name: test-user@development
  context:
    cluster: development
    user: test-user

- name: aws-user@kubernetes-on-aws
  context:
    cluster: kubernetes-on-aws
    user: aws-user

- name: test-user@production
  context:
    cluster: production
    user: test-user

- name: research
  context:
    cluster: test-cluster-1
    user: dev-user

users:
- name: test-user
  user:
    client-certificate: /etc/kubernetes/pki/users/test-user/test-user.crt
    client-key: /etc/kubernetes/pki/users/test-user/test-user.key
- name: dev-user
  user:
    client-certificate: /etc/kubernetes/pki/users/dev-user/developer-user.crt
    client-key: /etc/kubernetes/pki/users/dev-user/dev-user.key
- name: aws-user
  user:
    client-certificate: /etc/kubernetes/pki/users/aws-user/aws-user.crt
    client-key: /etc/kubernetes/pki/users/aws-user/aws-user.key

current-context: test-user@development
preferences: {}