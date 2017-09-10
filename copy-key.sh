#!/bin/bash
# -------------------------------------------------------------------------
# Name: copy_key.sh
# Description: 
# Author: zxs
# Version: 0.0.1
# Datatime: 2017-09-06
# Usage: 
# -------------------------------------------------------------------------
# auto input yes and input password, when run ssh-copy-id
copy_key() {
	expect << EOF
set timeout	3
spawn ssh-copy-id -i $key_name ${2}@${1}
	expect {
    "(yes/no)?" { send "yes\n";exp_continue }
    "password" { send "${3}\n";exp_continue }
}
expect eof
EOF
}
# set then host list and pub_key 
host_list=/tmp/host.txt
key_name=/root/.ssh/id_rsa.pub

if ! rpm -q expect &>/dev/null;then
	yum install -y q expect || exit 3
fi
[ ! -e $host_list ] && echo "Error:create a host list before." && exit 2
ip=(`awk '{print $1}' $host_list`)
user=(`awk '{print $2}' $host_list`)
password=(`awk '{print $3}' $host_list`)

for((i=0;i<${#ip[*]};i++));do
	{
	copy_key ${ip[$i]} ${user[$i]} ${password[$i]} &>/dev/null 
	if [ $? -eq 1 ];then
		 echo -e "${ip[$i]}:\tsend ssh_key[\033[32m success \033[0m]"
	else
		 echo -e "${ip[$i]}:\tsend ssh_key[\033[31m failure \033[0m]"
	fi
	} &
done
wait
