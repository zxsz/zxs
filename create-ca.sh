#!/bin/bash
# -------------------------------------------------------------------------
# Name: create-ca.sh
# Description: 
# Author: zxs
# Version: 0.0.1
# Datatime: 2017-09-06
# Usage: 
# -------------------------------------------------------------------------
declare -a default
# default information for CA , you can change this
default=("CN" "Henan" "Zhengzhou" "Magedu" "Tech" "ca.zxs.com" "zhangxingshi@aliyun.com")

cadir=/etc/pki/CA
cakey_file=$cadir/private/cakey.pem
cacert_file=$cadir/cacert.pem

[ -d ${cakey_file%/*} ] ||  mkdir -p ${cakey_file%/*}
[ -d $cadir/certs ] || mkdir $cadir/certs
[ -d $cadir/newcerts ] || mkdir $cadir/newcerts
[ -d $cadir/crl ] || mkdir $cadir/crl
touch $cadir/index.txt
echo 01 > $cadir/serial

set -e
# create private key
openssl genrsa -out $cakey_file 2048 &>/dev/null
# generate CA 
echo ${default[@]} | sed 's/ /\n/g'|openssl req -new -x509 -key $cakey_file -out $cacert_file &>/dev/null
# show cacert
echo -e "\033[32mcreate CA success,and cacert.pem information is:\033[0m"
openssl x509 -text -in $cacert_file | sed -n '1,/Public/p' 
