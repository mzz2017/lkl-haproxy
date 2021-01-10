#!/bin/sh
command=${1:-/usr/sbin/haproxy}

ip tuntap del lkl-tap mode tap > /dev/null 2>&1 || true
ip tuntap add lkl-tap mode tap
ip addr add 10.0.0.1/24 dev lkl-tap
ip link set lkl-tap up
sysctl -w net.ipv4.ip_forward=1
iptables -P FORWARD ACCEPT
iptables -t nat -D POSTROUTING -o $(awk '$2 == 00000000 { print $1 }' /proc/net/route) -j MASQUERADE > /dev/null 2>&1 || true
iptables -t nat -A POSTROUTING -o $(awk '$2 == 00000000 { print $1 }' /proc/net/route) -j MASQUERADE











LD_PRELOAD=/etc/lklhaproxy/liblkl-hijack.so LKL_HIJACK_NET_QDISC="root|fq" LKL_HIJACK_SYSCTL="net.ipv4.tcp_congestion_control=bbrplus;net.ipv4.tcp_congestion_control=bbr;net.ipv4.tcp_wmem=4096 16384 30000000" LKL_HIJACK_OFFLOAD=0x9983 LKL_HIJACK_NET_IFTYPE=tap LKL_HIJACK_NET_IFPARAMS=lkl-tap LKL_HIJACK_NET_IP=10.0.0.2 LKL_HIJACK_NET_NETMASK_LEN=24 LKL_HIJACK_NET_GATEWAY=10.0.0.1 LKL_HIJACK_BOOT_CMDLINE=mem=256M $command -f /etc/lklhaproxy/haproxy.cfg
exit 0