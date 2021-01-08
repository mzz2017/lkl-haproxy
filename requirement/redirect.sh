#!/bin/bash

ip tuntap del lkl-tap mode tap || true
ip tuntap add lkl-tap mode tap
ip addr add 10.0.0.1/24 dev lkl-tap
ip link set lkl-tap up
sysctl -w net.ipv4.ip_forward=1
iptables -P FORWARD ACCEPT
iptables -t nat -D POSTROUTING -o $(awk '$2 == 00000000 { print $1 }' /proc/net/route) -j MASQUERADE || true
iptables -t nat -A POSTROUTING -o $(awk '$2 == 00000000 { print $1 }' /proc/net/route) -j MASQUERADE
