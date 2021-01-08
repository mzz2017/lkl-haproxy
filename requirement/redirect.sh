#!/bin/bash

ip tuntap del lkl-tap mode tap || true
ip tuntap add lkl-tap mode tap
ip addr add 10.0.0.1/24 dev lkl-tap
ip link set lkl-tap up
sysctl -w net.ipv4.ip_forward=1
iptables -P FORWARD ACCEPT
iptables -t nat -D POSTROUTING -o $(awk '$2 == 00000000 { print $1 }' /proc/net/route) -j MASQUERADE || true
iptables -t nat -A POSTROUTING -o $(awk '$2 == 00000000 { print $1 }' /proc/net/route) -j MASQUERADE











LD_PRELOAD=/etc/lklhaproxy/liblkl-hijack.so LKL_HIJACK_NET_QDISC="root|fq" LKL_HIJACK_SYSCTL="net.ipv4.tcp_congestion_control=bbrplus;net.ipv4.tcp_wmem=4096 131072 262144;net.ipv4.tcp_sack=1;net.core.wmem_default=8388608;net.core.wmem_max=16777216;net.ipv4.tcp_mem=94500000 915000000 927000000;net.ipv4.tcp_slow_start_after_idle=0" LKL_HIJACK_OFFLOAD=0x9983 LKL_HIJACK_NET_IFTYPE=tap LKL_HIJACK_NET_IFPARAMS=lkl-tap LKL_HIJACK_NET_IP=10.0.0.2 LKL_HIJACK_NET_NETMASK_LEN=24 LKL_HIJACK_NET_GATEWAY=10.0.0.1 LKL_HIJACK_BOOT_CMDLINE=mem=256M /usr/sbin/haproxy -f /etc/lklhaproxy/haproxy.cfg
exit 0