# ##################################################################
# this file is a file with notes only. it's not for an execution
# this file has .sh extention only because it's easier to read a content of a file with such an extention
# ##################################################################

# create .key -> .csr
openssl genrsa -out jane.key 2048
openssl req -new -key jane.key -subj "/CN=jane" -out jane.csr

cat jane.csr | base64 -w 0 # get decripted oneliner

# create yaml file with CertificateSigningRequest object
apiVersion: certificates.k8s.io/v1beta1
kind: CertificateSigningRequest
metadata:
    name: jane
spec:
    groups:
    - system:authenticated
    # you can get sorta possible options with a command
    # `kubectl get rolebindings,clusterrolebindings -o yaml`
    # pay attention on clusterrolebindings.subjects.name
    usages:
    # list of all valid values can be find: 
    # `k explain CertificateSigningRequest.spec.usages`
    - digital signature
    - key encipherment
    - server auth
    request: # base64 encoded
    # output of `cat jane.csr | base64 -w 0`
#
# apply the file

# info on usages
k explain CertificateSigningRequest.spec.usages
#Valid values are:
    #"signing", "digital signature", "content commitment",
    #"key encipherment", "key agreement", "data encipherment",
    #"cert sign", "crl sign", "encipher only", "decipher only", "any",
    #"server auth", "client auth",
    #"code signing", "email protection", "s/mime",
    #"ipsec end system", "ipsec tunnel", "ipsec user",
    #"timestamping", "ocsp signing", "microsoft sgc", "netscape sgc"
#

# other useful commands
kubectl get csr
kubectl certificate approve jane
kubectl certificate deny jane
kubectl get csr jane -o yaml
echo “LS0…Qo=” | base64 --decode
kubectl delete certificatesigningrequests.certificates.k8s.io agent-smith 