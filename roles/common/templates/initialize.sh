#!/bin/bash
#author by hoke
#this script is only for Redhat&CentOS 7 by root

#标准化变量
tools_dir="$PWD/../tools"
creat_UID="{{worker_uid}}"
creat_GID="{{worker_gid}}"
system_group="{{worker_group}}"
system_user="{{worker_user}}"
system_user_password="{{worker_passwd}}"
system_user_dir="{{worker_home}}"
ntp_server="{{ ntpserver|default('0.centos.pool.ntp.org') }}"
docker_dir="$tools_dir/docker-ce"

# Set Check shell
system_user_check=`cat /etc/passwd |grep ${system_user} |wc -l`
system_kernel_check=`grep "hoke" /etc/sysctl.conf|wc -l`
system_profile_check=`grep "hoke" /etc/profile|wc -l`

# Color
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

checkos(){
local result=''
if [[ `cat /etc/redhat-release|sed -r 's/.* ([0-9]+)\..*/\1/'` -eq 7 ]] && [[ $EUID -eq 0 ]];then
   result="Linux 7"
fi
if [ "$result" = "Linux 7" ]; then
	return 0
else
	return 1
fi
}

#设置字符集
initCN_UTF8(){
    if [ `grep zh_CN.UTF-8 /etc/locale.conf|wc -l` -eq 1 ]; then
		echo -e "当前系统已为中文字符集\n"
	else
		\cp /etc/locale.conf /etc/locale.conf.$(date +%F)
		sed -i 's#LANG="en_US.UTF-8"#LANG="zh_CN.UTF-8"#' /etc/locale.conf
		source /etc/locale.conf
		echo -e "${green}[info]: 标准化中文字符集成功${plain}\n"
	fi
	sleep 1
}

#设置时区同步时间
initTimezone(){
    if [ `date -R |grep 0800 |wc -l` -gt 0 ]; then
		echo -e "当前系统时区正确"
	else
		rm -rf /etc/localtime && ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
	fi
{% if ntpserver is defined %}	
    ntpdate ${ntp_server} && clock -w
	if [ `cat  /etc/crontab | grep ntpdate | wc -l` -gt 0 ] ; then
        echo -e "当前系统已设置时间同步服务器\n"
    else 
        echo "0 0 * * * root /usr/sbin/ntpdate ${ntp_server}" >> /etc/crontab
#        echo "*/1 * * * * root /usr/sbin/ntpdate ${ntp_server}" >> /etc/crontab
		systemctl restart crond.service
		echo -e "${green}[info]: 标准化时区和时间同步成功${plain}\n"
	fi
{% endif %}
	sleep 1
}

#安装常用软件
install_basesoft(){
{% if ansible_distribution == "CentOS" %}
	tar -zxvf ${tools_dir}/basesoft-centos.tgz -C ${tools_dir}
	yum install ${tools_dir}/basesoft-centos/* -y
    echo -e "${green}[info]: 安装常用软件成功${plain}\n"
{% elif ansible_distribution == "RedHat" and ansible_distribution_version == "7.4"%}
	tar -zxvf ${tools_dir}/rhel7.4-basesoft.tgz -C ${tools_dir}
	yum install ${tools_dir}/rhel7.4-basesoft/* -y
#	rpm -Uvh ${tools_dir}/basesoft/*.rpm
    echo -e "${green}[info]: 安装常用软件成功${plain}\n"
{% else %}
    echo -e "${yellow}[warn]: 不支持的操作系统版本${plain}\n"
{% endif %}
	sleep 1
}

#安装docker
install_docker(){
	tar -zxvf ${tools_dir}/docker-ce.tgz -C ${tools_dir}
	tar -zxvf ${tools_dir}/jq.tgz -C ${tools_dir}
	yum install ${docker_dir}/* -y
	yum install ${tools_dir}/jq/* -y
#	rpm -ivh ${tools_dir}/docker/*.rpm
	\cp ${tools_dir}/docker-compose /usr/local/bin/
	chmod +x /usr/local/bin/docker-compose
    echo -e "${green}[info]: 安装 docker 成功${plain}\n"
	sleep 1
}

#安装ansible
install_ansible(){
    tar -zxvf ${tools_dir}/ansible.tgz -C ${tools_dir}
	yum install ${tools_dir}/ansible/* -y
#	rpm -Uvh ${tools_dir}/ansible/*.rpm
    echo -e "${green}[info]: 安装 ansible 成功${plain}\n"
	sleep 1
}

#安装haproxy
install_haproxy(){
	tar -zxvf ${tools_dir}/haproxy.tgz -C ${tools_dir}
	yum install ${tools_dir}/haproxy/* -y
#	rpm -Uvh ${tools_dir}/haproxy/*.rpm
    echo -e "${green}[info]: 安装 haproxy 成功${plain}\n"
	sleep 1
}

#disabled Selinux
initSelinux(){
    if [[ `getenforce` == "Enforcing" ]] ; then
        setenforce 0
        sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
        echo -e "${green}[info]: SELINUX 禁用成功${plain}\n"
    else
        echo -e "当前系统已禁用 SELINUX\n"
    fi
	sleep 1
}

#标准化防火墙
initFirewall(){
    if [[ `systemctl status firewalld | awk -F ' ' 'NR==3 {print $2}'` == 'active' ]] ; then
        systemctl stop firewalld
		systemctl disable firewalld
        echo -e "${green}[info]: 停止运行 Firewalld 且卸载成功${plain}"
    elif [[ `systemctl status firewalld | awk -F ' ' 'NR==3 {print $2}'` == 'inactive' ]] ; then 
        systemctl disable firewalld
        echo -e "${green}[info]: Firewalld 卸载成功${plain}"
    else
        echo -e "当前系统未安装 Firewalld"
	fi
	sleep 1
}

#创建用户及工作目录
create_user(){
	if [  ${system_user_check} -eq 0 ];then
		[ ! -d ${system_user_dir} ] && mkdir -p ${system_user_dir}
		groupadd -g ${creat_GID} ${system_group}
		useradd -g ${creat_GID} -d ${system_user_dir}/${system_user} -m ${system_user} -u ${creat_UID}
       echo "${system_user_password}" | passwd --stdin ${system_user} && history -c
		#usermod -a -G docker ${system_user}
		echo -e "${green}[info]: 创建用户成功${plain}\n"
	fi
	sleep 1
}

#设置文件句柄&用户进程
openfile(){
    if [[ `ulimit -a |grep "open files"|awk '{print $4}'` -lt 655350 || `ulimit -a |grep "max user processes"|awk '{print $5}'` -lt 655350 ]];then
        \cp /etc/security/limits.conf /etc/security/limits.conf.$(date +%F)
		\cp /etc/security/limits.d/20-nproc.conf /etc/security/limits.d/20-nproc.conf.$(date +%F)
		cat >> /etc/security/limits.conf << EOF
#copyright by hoke
* soft nproc 655350
* hard nproc 655350
* soft nofile 655350
* hard nofile 655350
EOF
		sed -i "s/^*/#*/" /etc/security/limits.d/20-nproc.conf
		sed -i "s/^root/#root/" /etc/security/limits.d/20-nproc.conf
		ulimit -HSn 655350
		ulimit -HSu 655350
		echo -e "${green}[info]: 优化文件句柄数&最大进程数成功${plain}"
	else
		echo -e "当前系统文件句柄数&最大进程数已设置过"
    fi
    sleep 1
}

#标准化全局变量
initProfile(){
	if [[ ! -f /etc/profile.$(date +%F) && ${system_profile_check} -eq 0 ]]; then
        \cp /etc/profile /etc/profile.$(date +%F)
        cat >> /etc/profile << EOF
#全局变量
#copyright by hoke
#alias vi=vim
#stty erase ^H
export PS1='\[\e[1;35m\][\[\e[1;33m\]\u@\h \[\e[1;31m\]\w\[\e[1;35m\]]\\$ \[\e[0m\]'
EOF
		source /etc/profile
		echo -e "${green}[info]: 标准化全局变量成功${plain}\n"
    else
		echo -e "当前系统已设置过全局变量\n"
	fi
}

#优化内核
initKernel(){
	[ ! -f /etc/sysctl.conf.$(date +%F) ] && \mv /etc/sysctl.conf /etc/sysctl.conf.$(date +%F)
	if [ ${system_kernel_check} -eq 0  ];then
        cat > /etc/sysctl.conf << EOF
#copyright by hoke
#最大使用物理内存,默认值60
vm.swappiness = 10                                 
#开启路由转发
net.ipv4.ip_forward = 1                            
# 避免放大攻击
net.ipv4.icmp_echo_ignore_broadcasts = 1
# 开启恶意icmp错误消息保护
net.ipv4.icmp_ignore_bogus_error_responses = 1
#决定检查过期多久邻居条目
net.ipv4.neigh.default.gc_stale_time=120           
#禁用反向路径过滤
net.ipv4.conf.all.rp_filter=0                      
net.ipv4.conf.default.rp_filter=0   
#只用最适合的网卡响应       
net.ipv4.conf.default.arp_announce = 2             
net.ipv4.conf.all.arp_announce=2                   
net.ipv4.conf.lo.arp_announce=2 
#timewait的数量,默认180000
net.ipv4.tcp_max_tw_buckets = 5000
#表示开启重用。允许将TIME-WAIT sockets重新用于新的TCP连接，默认为0，表示关闭；
net.ipv4.tcp_tw_reuse = 1
#表示开启TCP连接中TIME-WAIT sockets的快速回收，默认为0，表示关闭，慎用。
#net.ipv4.tcp_tw_recycle = 0
#修改系統默认的TIMEOUT时间，默认60
net.ipv4.tcp_fin_timeout = 30

#开启SYN Cookies,防止SYN洪水
net.ipv4.tcp_syncookies = 1                        
#表示SYN队列的长度，默认为1024，加大队列长度为8192，可以容纳更多等待连接的网络连接数。
net.ipv4.tcp_max_syn_backlog = 8192               
#TCP三次握手的syn/ack阶段，重试次数，缺省5，设为2-3
net.ipv4.tcp_synack_retries = 2                    
#表示当keepalive起用的时候，TCP发送keepalive消息的频度。缺省是2小时，改为20分钟。
net.ipv4.tcp_keepalive_time = 600
#关闭ipv6
net.ipv6.conf.all.disable_ipv6 = 1                 
net.ipv6.conf.default.disable_ipv6 = 1             
net.ipv6.conf.lo.disable_ipv6 = 1                  

#允许一个进程在VMAs(虚拟内存区域)拥有最大数量/proc/sys/vm/max_map_count
vm.max_map_count = 262144
#/proc/sys/net/core/somaxconn 默认128，系统中每一个端口最大的监听队列的长度
net.core.somaxconn = 4096
EOF
		/sbin/sysctl -p
		echo -e "${green}[info]: 优化内核参数成功${plain}"
	else
		echo -e "当前系统已优化过内核参数"
    fi
	sleep 1
}

AStr="环境初始化"
BStr="安装ansible"
CStr="安装haproxy"
DStr="标准化中文字符集"
QStr="按Q或任意键退出"

clear
echo -e "\e[1;32m+----------------- 欢迎对系统进行初始化设置！------------------+"
echo ""
echo "      A：${AStr}"
echo "      B：${BStr}"
echo "      C：${CStr}"
echo "      D：${DStr}"
echo "      Q：${QStr}"
echo ""
echo -e "+----------------- \033[41;37m10秒后自动一键标准化\033[0m\e[1;32m -------------------------+\033[0m"

read -n1 -t10 -p "请输入[A-D]选项，默认选项[A]:" option
[ -z "${option}" ] && option="A"
flag=$(echo $option|egrep "[A-Da-d]" |wc -l)
if [ $flag -ne 1 ];then
	echo -e "\n\n你输入的选项是：${red} ${option} ${plain}，即将退出Byebye..."
	exit 1
fi
echo -e "\n\n你输入的选项是：${red} ${option} ${plain} ，5秒之后开始运行\n"
sleep 5

if checkos result Linux 7; then
	case $option in
	A|a)
		initSelinux
{% if centosrepo is not defined %}
		install_basesoft
{% endif %}
#		install_docker
		initFirewall
		initTimezone
		initProfile
		openfile
		initKernel
    ;;
    B|b)
		install_ansible
    ;;
    C|c)
		install_haproxy
    ;;
    D|d)
		install_docker
    ;;
    E|e)
		initCN_UTF8
    ;;
	F|f)
		create_user
	;;
	esac
else
	echo -e "${red}[error]: 此脚本仅支持 Linux 7 且必须使用 root 运行!${plain}" 
	exit 1
fi