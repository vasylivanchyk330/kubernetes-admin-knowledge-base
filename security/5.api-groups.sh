# ##################################################################
# this file is a file with notes only. it's not for an execution
# this file has .sh extention only because it's easier to read a content of a file with such an extention
# ##################################################################

# using curl to get version info
curl https://kube-master:6443/version # u need to provide auth key/cacert etc.
# note: kube-master --  the hostname or IP address of the Kubernetes master node
# 6443 -- port for api calls


# using curl to get pods info
curl https://kube-master:6443/api/v1/pods # u need to provide auth key/cacert etc.

# let's brackdown what might goes after the port:
    # /metrics /healthz /version /api /apis /logs
# here i concentrate on "/api /apis"
# /api -- aka, core api
# /apis -- aka, named apis

# u can get the list of that's inside with `-k`
curl http://localhost:6443 -k 
curl http://localhost:6443/apis -k | grep “name”

# NOTE: if u gonna do curl without specifying auth key/cacert etc., u'll get 'forbidden' message
# so the correct way is smth like
curl http://localhost:6443 –k
--key admin.key
--cert admin.crt
--cacert ca.crt
# u can create a kubectl proxy which would be a proxy agent between ur localhost and say master server
kubectl proxy # output `Starting to serve on 127.0.0.1:8001` 
curl http://localhost:8001 -k
#note: kube proxy -- for service intercluster communication
# while kubectl proxy -- for a proxy agent between ur localhost and say master server