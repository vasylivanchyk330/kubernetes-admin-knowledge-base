# ##################################################################
# this file is a file with notes only. it's not for an execution
# this file has .sh extention only because it's easier to read a content of a file with such an extention
# ##################################################################




# ################################
# Switching, Routing, Gateways
# ################################

# general info 
ip link # about  nw interfaces
ip addr # see ip addresses singed to nw interfaces
route # desplays  kernel ip routing tabel

# connect 2 local devices thru a nw device, switch (so they become a network)
# assume, the switch has address 192.168.1.0
ip addr add  192.168.1.10/24 dev eth0 # assining 192.168.1.10/24 to the first device; dev - name of nw device (switch); eth0 - name of local device 
ip addr add  192.168.1.11/24 dev eth0 # same for the second one
ping 192.168.1.11 # from the first device; it works

# to connect 2 nw-s, we use routers

# add a gateway to a local device routing table 
ip route add 192.168.1.10/24 via 192.168.1.1 # the last one is the ip of a router gateway
route # see the new table record appeared
# the route adding has to be done on all the devices connected to the router to make possible sending/resiving signals

# for all unknown ip, make this gateway a default one
ip route add default via 192.168.2.1 # basically, "default" in destination field means 0.0.0.0

# there could be 0.0.0.0 not in destination field but in gateway field means that you dont need a gateway

# here, u might be confused with the gateway vs port terminology collision.
# metaphore:
    # a network/LAN    -- a walled city
    # a gateway        -- a point of entrance/exit from/to the city
    # an interface     -- a main (phisical) entrense to a building
    # a port           -- a (virtual) door to appartments or mail box  
    # a service/app    -- a citizen
    # a data package   -- a package 
    # a switch         -- internal roadways and intersections within the city
    # a router         -- a city's main administration office or control center that manages and directs all the traffic coming in and out of the city

# main gateway functions in a modern networking:
    # Network Traffic Routing
    # Protocol Translation
    # Security and Firewall
    # Network Address Translation (NAT)
    # VPN Support
    # Data Packet Inspection and Filtering
    # Load Balancing
    # Content Caching
    # Quality of Service (QoS) -  prioritize network traffic
    # Wireless Access Point (in some cases) -  in small networks
#


#  you can make a host to serve as a primitive router between 2 other hosts

    # assume you have:
    # host1 192.168.1.5 (192.168.1.0/24 metwork)
    # host2 192.168.2.6 (192.168.2.0/24 metwork)
    # host3 having gateways open for host1 -  192.168.1.6; for host2 - 192.168.2.6

    # host1 connected to host3 as well as host2 to host3
    # you want to have communication between host1 and host2 via host3

    # add to host1 routing table
    ip route add 192.168.2.0/24 via 192.168.1.6
    # add to host2 routing table
    ip route add 192.168.1.0/24 via 192.168.2.6

    # by default, due to security reasons, the host3 doesnot redirect such communication from host1 to host2
    # so we need to enable it
    # in linux, everything is a file
    # so we need to figure out what file is responsible for such communication and add a corresponding record to allow redirection
    cat /proc/sys/net/ipv4/ip_forward # output: 0
    echo 1 > /proc/sys/net/ipv4/ip_forward # meaning "true" - allow ip forwarding
    
    # this approach is one-time only. it'll be override during the next os reboot
    # to make it pernament:
    vim /etc/sysctl.conf # -> find "net.ipv4.ip_forward" and make its value '1'
    # viala
#

# by default, the all changes made by commands like "ip addr add" etc. are inplace untill the next sys reboot. to make them pesistent -- change /etc/sysctl.conf file





# ################################
# DNS
# ################################

# to assign an ip to a dns
    # host2 -- to be "db"
    # on host1:
    cat >> /etc/hosts      
    <host2_ip>      db
#
# no you can just
ping db


# such an approach was good for a local nw, and if it was small
# but if there are a lot of host in a nw or a lot of nw-s, it might be very tidious task to maintain those entries on all the hosts

# so that's how a "DNS server" approach emerged
# now, we gonna have all those records for all hosts to be on 1 server, DNS server

# to point a host to connect to DNS server,
cat >> /etc/resolv.conf
<DNS-server>  <DNS-server-ip>   # a scheme
nameserver    192.168.1.100    # e.g.

# remember precedence: 
    # by def., local  /etc/hosts has higher precedence than a dns-server
    # but it can be changed: 
    vim  /etc/nsswitch.conf
        hosts:        files dns # to change precedence, switch values places

# you can add to /etc/resolv.conf
nameserver      8.8.8.8  # server, managed by google, with most common internet hostnames


# DNS name structure
    # e.g. www.google.com. -- fqdn; the precedence
        # (last).  -- root
        # .com      -- high-lvl domain
        # google    -- domain
        # www       -- subdomain
    # by this precedence, the DNS systems narrow down when searching you request `www.google.com` in the internet
#

# different types of dns record types
    # A     -- mapping: dns name VS ipv4
    # AAAA  -- mapping: dns name VS ipv6
    # CNAME -- mapping: dns name VS dns names
    # and theres more
#

# you can use this command to check details of dns name
nslookup www.google.com
# it doesnt look up for local dns in /etc/host tho, only in dns server

# similar -- dig command
dig www.google.com






# ################################
# Network Namespaces
# ################################

ip netns add nsname # create a ns
ip netns # list
ip netns exec nsname  ip link # list ip interfaces in the chosen ns
ip  -n nsname  link # same as above

# u can create a virtual connection between 2 ns
    # connect 2 virtual ethernets (veth)
    ip link add  veth-red  type veth peer name  veth-blue
    # attach each veth to approptiate ns
    ip link set  veth-red   netns red
    ip link set  veth-blue   netns blue
    # assign ip addresses to veth-s
    ip  -n red  addr set 192.168.15.1  dev veth-red
    ip  -n blue  addr set 192.168.15.2  dev veth-blue
    # turn veth-s up
    ip  -n red  link set  veth-red  up
    ip  -n red  link set  veth-blue  up
    # check connection from red to blue
    ip netns exec  red  ping 192.168.15.2
    ip netns exec  red  arp # check cached routing table
#
# that's when u have 2 virtual ethernets
# but what if u have many? 
# u need a virtual network and for that u need virtual switch
# there are different tools for that but here i use Linux Bridge
    # add a vnet
    ip link add  v-net-0  type bridge
    ip link # it's be visible in here
    # set it up
    ip link set  v-net-0  up
    # now, similar to the example with 2 veth-s, connect each veth but not to each other - to the brigde
    ip link add  veth-red  type veth peer name  veth-red-br
    ip link add  veth-blue type veth peer name  veth-blue-br
    ip link add  veth-yellow type veth peer name  veth-yellow-br # etc
    # now, set each veth-s to each ns-s
    ip link set  veth-red  netns red # etc.
    # set veth-s to the vnet we created at the beginning
    ip link set  veth-red-br   master v-net-0 #etc
    # assign ip addresses to veth-s
    ip  -n red  addr set 192.168.15.1  dev veth-red # etc.
    # turn veth-s up
    ip  -n red  link set  veth-red  up # etc.
# no all the ns-s are connected to the nw thru the switch and can communicate with each other 
# 
# if it's needed to start communication between another host (say, local host) under this interface and these v-net ip-s, here's how
    # assign an ip to the v-net
    ip addr add 192.168.15.5/24  dev v-net-0 
    # now you can 
#
# if we need to connect from v-net-0 to another ethernet host
# we can use the local host (here, 192.168.15.5) 
# (as it's been added to the vnet0 routing table already and it has connection to LAN) 
# in other words, we are making the local host to become a sort of gateway from v-net-0 to the whole LAN
ip netsn exec blue ip route add 192.168.1.0/24 via 192.168.15.5
# but still it wouldn't work as expected. why?
# the local host has not only the local host ip address (here, 192.168.15.5),
# but also an ip address for communication with outside world (say, 192.168.1.2)
# so in order this all to work as wanted, we need to "add NAT functionality to the equasion" "acting as a gateway" with it's own name and ip address
    # run from local host 192.168.15.5
    iptables -t nat -A POSTROUTING -s 192.168.15.0/24 -j MASQUARADE
    # which means 
    # -t nat  -- add to table nat
    # -A  -- appending a new rule 
    # POSTROUTING  -- type of rules; what to do with data packet after it's been routed; it's basically a NAT level rule
    # -s 192.168.15.0/24  -- source=thisIP
    # -j  -- tells the packet to "jump" to a specified target if it matches the rule. In this case, the target is MASQUERADE
    # MASQUERADE  --  dynamic NAT. It masks the source IP address of outgoing packets.
# in this way, outside destination hosts think that data packets come from the host, not from within the v-ns-s
#
# if we'd like to ping www:
    ip netns exec nsname  ip rout add default  via 192.168.15.5
#

