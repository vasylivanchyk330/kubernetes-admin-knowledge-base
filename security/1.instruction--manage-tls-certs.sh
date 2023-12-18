# ##################################################################
# this file is a file with notes only. it's not for an execution
# this file has .sh extention only because it's easier to read a content of a file with such an extention
# ##################################################################


# general  scenario
openssl genrsa -out key.key 1024 # priv key
openssl rsa -in key.key -pubout > pubout.pem # pub key ("pub lock")
openssl req -new -key key.key -out out.csr \  
    -subj "/C=PL/..../CN=web-page.com" # certificate signing request
#


# generate CA key/crt
openssl genrsa -out ca.key 2048 # ca keys
openssl req -new -key ca.key -subj "/CN=KUBERNETES-CA" -out ca.csr # ca csr
openssl x509 -req -in ca.csr -signkey ca.key -out ca.crt # ca crt



# now, that we have CA key/crt, we can gen key/crt pairs for all the needed k8s components or clients 

# generate client key/crt, here for admin user
openssl genrsa -out client-admin.key 2048 # priv key
openssl req -new -key client-admin.key -out client-admin.csr \  
    -subj "/C=PL/..../CN=kube-admin/O=system:masters" # certificate signing request
openssl x509 -req -in client-admin.csr –CA ca.crt -CAkey ca.key -out client-admin.crt # sign certificates

# same procedure is for all other clients, including the system ones e.g:
    # kube-contoller-manager (-subj "/C=PL/..../CN=kube-contoller-manage/O=system:kube-contoller-manage" )
    # kube-sceduler (-subj "/C=PL/..../CN=kube-scheduler/O=system:kube-sceduler" )
    # kube-proxy  (-subj "/C=PL/..../CN=kube-proxy/O=system:kube-proxy" )
#

# to curl using key/crt
curl https://kube-apiserver:6443/api/v1/pods \
    --key admin.key --cert admin.crt   
    --cacert ca.crt

# key/crt used in the kube-config.yaml
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority: ca.crt
    server: https://kube-apiserver:6443
  name: kubernetes
context: 
- name: kubernetes-admin@kubernetes
users:
- name: kubernetes-admin
  user:
    client-certificate: admin.crt
    client-key: admin.key



