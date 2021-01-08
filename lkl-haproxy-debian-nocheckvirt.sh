#!/bin/bash
Green_font="\033[32m" && Yellow_font="\033[33m" && Red_font="\033[31m" && Font_suffix="\033[0m"
Info="${Green_font}[Info]${Font_suffix}"
Error="${Red_font}[Error]${Font_suffix}"
echo -e "
${Green_font}
#================================================
# Project: bbrplus lkl-haproxy
# Platform: --CentOS --nocheckvirt
# Version: 1.0.5
# Author: mzz2017
# Github: https://github.com/mzz2017/lkl-haproxy
#================================================
${Font_suffix}"

check_system(){
	[[ -z "`cat /etc/issue | grep -iE "debian"`" ]] && echo -e "${Error} only support Debian !\nYou can find centos script at https://github.com/mzz2017/lkl-haproxy" && exit 1
	[[ "`uname -m`" != "x86_64" ]] && echo -e "${Error} only support 64 bit !" && exit 1
}

check_root(){
	[[ "`id -u`" != "0" ]] && echo -e "${Error} must be root user !" && exit 1
}

check_ovz(){
	apt-get update && apt-get install -y virt-what
	[[ "`virt-what`" != "openvz" ]] && echo -e "${Error} only support OpenVZ !" && exit 1
}

check_ldd(){
	#ldd=`ldd --version | grep ldd | awk '{print $NF}'`
	[[ "`ldd --version | grep ldd | awk '{print $NF}'`" < "2.14" ]] && echo -e "${Error} ldd version < 2.14, not support !" && exit 1
}

check_tuntap(){
	echo -e "\n"

	cat /dev/net/tun

	echo -e "${Info} 请确认上一行的返回值是否为 'File descriptor in bad state'（文件描述符处于错误状态） ？"
	echo -e "1.是\n2.否"
	read -p "输入数字以选择:" tuntap

	while [[ ! "${tuntap}" =~ ^[1-2]$ ]]
	do
		echo -e "${Error} 无效输入"
		echo -e "${Info} 请重新选择" && read -p "输入数字以选择:" tuntap
	done

	[[ -z "${tuntap}" || "${tuntap}" == "2" ]] && echo -e "${Error} 未开启 tun/tap，请开启后再尝试该脚本 !" && exit 1

	#以下为失败，grep 无效
	#echo -n "`cat /dev/net/tun`" | grep "device"
	#[[ -z "${enable}" ]] && echo -e "${Error} not enable tun/tap !" && exit 1
}

directory(){
	[[ ! -d /etc/lklhaproxy ]] && mkdir -p /etc/lklhaproxy
	cd /etc/lklhaproxy
}

config(){
	# choose one or many port
	echo -e "${Info} 你想加速单个端口（例如 443）还是端口段(例如 8080-9090) ？\n1.单个端口\n2.端口段"
	read -p "(输入数字以选择):" choose
	while [[ ! "${choose}" =~ ^[1-2]$ ]]
	do
		echo -e "${Error} 无效输入"
		echo -e "${Info} 请重新选择" && read -p "输入数字以选择:" choose
	done

	# download unfully-config-redirect
	wget https://raw.githubusercontent.com/mzz2017/lkl-haproxy/master/requirement/redirect.sh

	# config: haproxy && redirect
	if [[ "${choose}" == "1" ]]; then
		 echo -e "${Info} 输入你想加速的端口"
		 read -p "(输入单个端口号，例如：443，默认使用 443):" port1
		 [[ -z "${port1}" ]] && port1=443
		 config-haproxy-1
		 config-redirect-1
	else
		 echo -e "${Info} 输入端口段的第一个端口号"
		 read -p "(例如端口段为 8080-9090，则此处输入 8080，默认使用 8080):" port1
		 [[ -z "${port1}" ]] && port1=8080
		 echo -e "${Info} 输入端口段的第二个端口号"
		 read -p "(例如端口段为 8080-9090，则此处输入 9090，默认使用 9090):" port2
		 [[ -z "${port2}" ]] && port2=9090
		 config-haproxy-2
		 config-redirect-2
	fi
}

config-haproxy-1(){
echo -e "global

defaults
log global
mode tcp
option dontlognull
option tcpka
timeout connect 5000ms
timeout client 8000s
timeout server 8000s

frontend proxy-in
bind *:${port1}
default_backend proxy-out

backend proxy-out
server server1 10.0.0.1 maxconn 20480\c" > haproxy.cfg
}

config-haproxy-2(){
echo -e "global

defaults
log global
mode tcp
option dontlognull
option tcpka
timeout connect 5000ms
timeout client 8000s
timeout server 8000s

frontend proxy-in
bind *:${port1}-${port2}
default_backend proxy-out

backend proxy-out
server server1 10.0.0.1 maxconn 20480\c" > haproxy.cfg
}

config-redirect-1(){
sed -i "20i\iptables -t nat -A PREROUTING -i $(awk '$2 == 00000000 { print $1 }' /proc/net/route) -p tcp --dport ${port1} -j DNAT --to-destination 10.0.0.2" redirect.sh
}

config-redirect-2(){
sed -i "20i\iptables -t nat -A PREROUTING -i $(awk '$2 == 00000000 { print $1 }' /proc/net/route) -p tcp --dport ${port1}:${port2} -j DNAT --to-destination 10.0.0.2" redirect.sh
}

check-all(){
	# check config
	[[ ! -f haproxy.cfg ]] && echo -e "${Error} not found haproxy config, please check !" && exit 1
	[[ ! -f redirect.sh ]] && echo -e "${Error} not found redirect config, please check !" && exit 1

	# check lkl-mod
	[[ ! -f liblkl-hijack.so ]] && wget https://raw.githubusercontent.com/mzz2017/lkl-haproxy/master/mod/liblkl-hijack.so
	[[ ! -f liblkl-hijack.so ]] && echo -e "${Error} download lkl.mod failed, please check !" && exit 1

	# check wget
	wget --help > /dev/null || apt-get install -y wget

	# check haproxy
	apt-get install -y iptables bc haproxy
	which haproxy || (echo -e "${Error} failed to install haproxy !" && exit 1)

	# give privilege
	chmod -R +x /etc/lklhaproxy
}

# start immediately
run-it-now(){
	systemctl start lkl-haproxy
	bash /etc/lklhaproxy/redirect.sh
}

# start with reboot
self-start(){
	echo "[Unit]
Description=lkl-haproxy

[Service]
ExecStart=/etc/lklhaproxy/redirect.sh
Restart=always
  
[Install]
WantedBy=multi-user.target

" > /etc/systemd/system/lkl-haproxy.service
	systemctl daemon-reload
	systemctl enable lkl-haproxy
}


install(){
	check_system
	check_root
	#check_ovz
	check_ldd
	check_tuntap
	directory
	config
	check-all
	self-start
	run-it-now
	#status
	echo -e "${Info} 已完成，请稍后使用此脚本第二项判断 lkl 是否成功。"
}

status(){
	pingstatus=`ping 10.0.0.2 -c 3 | grep ttl`
	if [[ ! -z "${pingstatus}" ]]; then
		echo -e "${Info} lkl-haproxy is running !"
		else echo -e "${Error} lkl-haproxy not running, please check !"
	fi
}

uninstall(){
	check_system
	check_root
	apt-get remove -y haproxy
	rm -rf /etc/lklhaproxy
	#iptables -F
	systemctl disable lkl-haproxy
	echo -e "${Info} please remember 重启 to stop lkl-haproxy"
}




echo -e "${Info} 选择你要使用的功能: "
echo -e "1.安装 lkl bbrplus\n2.检查 lkl bbrplus运行状态\n3.卸载 lkl bbrplus"
read -p "输入数字以选择:" function

while [[ ! "${function}" =~ ^[1-3]$ ]]
	do
		echo -e "${Error} 无效输入"
		echo -e "${Info} 请重新选择" && read -p "输入数字以选择:" function
	done

if [[ "${function}" == "1" ]]; then
	install
elif [[ "${function}" == "2" ]]; then
	status
else
	uninstall
fi
