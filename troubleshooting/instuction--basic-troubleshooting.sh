# ##################################################################
# this file is a file with notes only. it's not for an execution
# this file has .sh extention only because it's easier to read a content of a file with such an extention
# ##################################################################



# ################################
# Application Failure
# ################################

# if app failed, check
# 1. webservice
curl http://web-service-ip:node-port
kubectl describe service web-service
# check if podSelectors are same for pod and service   

# if ok, 
# 2. pod/delpoy:
kubectl get pod
kubectl describe pod web
kubectl logs web -f --previous

# if ok, 
# 3. dependent service, e.g. db

# if ok, 
# 4. dependent pods, e.g. db


# pay attention on:
    # if svc ports corresponds to pod ports opened
    # env vars are set correctly (e.g db_host, user, password are not set correctly)
#




# ################################
# k8s sys logs
# ################################

#  useful when k8s sys components are down especially apiserver

cd /var/log/pods/ # you can find log dirs for all the k8s sys components
cd /var/log/containers

# when k8s down and you cant see k8s logs with `k logs`
crictl ps 
crictl logs
watch crictl ps

docker ps
docker log

journalctl 
journalctl -u kubelet # not really helpful; a lot of info and not well formatted

vim  /var/log/syslog # these are similar to the above but in much more readible foremat



