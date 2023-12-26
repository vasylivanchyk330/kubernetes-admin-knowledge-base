

# ################################
# Docker Networking
# ################################

# 1. docker run --network

docker run  --network none  nginx # no contact with world
docker run  --network host  nginx 
    # container is attached to host's nw
    # no nw isolation between the host and cont
    # only 1 cont can listen on `--network host` - other cant get access to the world at the same time
docker run  --network bridge  nginx



# 2. docker bridge network

# when docker is installed on a host, an initial bridge is created automatically
# underneth the command is run:
    ip link add docker0 type bridge

# on the cont lvl
docker network ls # to get list of networks; 
    # here you can find the initial bridge named `bridge`

# on the host lvl
ip link # outputing interfaces, among which one can find docker0 (DOWN by default)

# bridge nw is like an interface to the host but like a switch to nw namespaces/containers

# to get ip info 
ip addr # find docker0: 127.17.0.1/24



# 3 docker container nw ns

# whenever a container is created, docker runtime creates a nw ns for it
ip netns # you can find such a nw ns and its info

# to list all the docker nw ns-s (from the host level)
for container in $(docker ps -q); do
    pid=$(docker inspect --format '{{.State.Pid}}' $container)
    echo "Container ID: $container, Namespace: /proc/$pid/ns/net"
done

# note: The /proc/ directory in Unix-like operating systems, including Linux, 
    # is a special directory and an essential component of the Linux filesystem. # It doesn't contain real files in the traditional sense but is a virtual filesystem that provides a window into the kernel's view of the system. 
    # main purposes:
        # Process Information, by process ids
        # System Information, e.g. /proc/meminfo, /proc/cpuinfo, /proc/net/
        # Interface to Kernel Parameters
        # Virtual Files, don't actually exist on disk, generated on-the-fly by the Linux kernel when read,  information directly from kernel data structures
        # used for Diagnostics and Debugging info
#

# to inspect ns
docker inspect <ns-id>



# 4. underneth of docker cont-to-bridge attachment 

# answer
# docker creates veth, from a cont to the bridge, with 2 interfaces from each ends

# to get info on those 2 interfaces, on the docker server run
ip link # find veth name starting with `veth`
    # this interface is attached to the local bridge
ip  -n <nw-ns-id>  link # usually starts with `eth`
    # interface of the cont 
    # <nw-ns-id> could be find in `ip netns` output (see instruction3 above)

# both interfaces ends with @if<xx>
# moreover, bridge and cont interfaces have concecutive xx of odd and even numbers
# bridge -- odd; cont -- even (in that order)
    # e.g brige if -- veth....@if11;    cont if -- eth....@if12
#



# 5. port mapping 
# (from outside world to cont via docker host, and vice versa)

docker run -p 8080:80  nginx
# (-p host-port:cont-port)

# what's underneth:
iptable \
    -t nat \
    -A DOCKER \
    -j DNAT \
    -dport 8080 \
    -to-destination 172.17.0.3:80 # using cont ip

iptables -nvL -t nat # to list rules; cont lvl

