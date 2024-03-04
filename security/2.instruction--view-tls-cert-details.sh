# ##################################################################
# this file is a file with notes only. it's not for an execution
# this file has .sh extention only because it's easier to read a content of a file with such an extention
# ##################################################################


# 1. configuration details
# 1.1 cluster has been created in "hard way"
cat /etc/systemd/system/kube-apiserver.service
# 1.2 cluster has been created with kubeadm
cat /etc/kubernetes/manifests/kube-apiserver.yaml



# 2. get details of .crt
# first get the .crt location, say you need a apiserver.crt
cat /etc/kubernetes/manifests/kube-apiserver.yaml
... 
--tls-cert-file=/etc/kubernetes/pki/apiserver.crt
...

openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout
# output (not formatted here):
: <<'END_COMMENT'
Certificate:
Data:
Version: 3 (0x2)
Serial Number: 3147495682089747350 (0x2bae26a58f090396)
Signature Algorithm: sha256WithRSAEncryption
Issuer: CN=kubernetes
Validity
Not Before: Feb 11 05:39:19 2019 GMT
Not After : Feb 11 05:39:20 2020 GMT
Subject: CN=kube-apiserver
Subject Public Key Info:
Public Key Algorithm: rsaEncryption
Public-Key: (2048 bit)
Modulus:
00:d9:69:38:80:68:3b:b7:2e:9e:25:00:e8:fd:01:
Exponent: 65537 (0x10001)
X509v3 extensions:
X509v3 Key Usage: critical
Digital Signature, Key Encipherment
X509v3 Extended Key Usage:
TLS Web Server Authentication
X509v3 Subject Alternative Name:
DNS:master, DNS:kubernetes, DNS:kubernetes.default,
DNS:kubernetes.default.svc, DNS:kubernetes.default.svc.cluster.local, IP
Address:10.96.0.1, IP Address:172.17.0.27
END_COMMENT



# 3. Inspect Service Logs (when "hard way")
journalctl -u etcd.service -l



# 4. if k8s services are down and you need to get logs from container lvl
docker ps -a # to get the container id
docker logs 87fc



# 5. from k8s 
kubectl logs etcd-master



# 6. with crictl
crictl ps -a # to get container id of say api-server
crictl logs a850a8dd78593
