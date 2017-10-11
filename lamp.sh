#!/bin/bash
# -------------------------------------------------------------------------
# Name: lamp.sh
# Description: 
# Author: zxs
# Version: 0.0.1
# Datatime: 2017-09-22
# Usage: 
# -------------------------------------------------------------------------

echo_info() {
   echo -e "[\033[32minfo\033[0m] $*"
}

echo_error() {
   echo -e "[\033[32merror\033[0m] $*"
}

# Usage: action <"comment"> <COMMAND>
action() {
   local srting rc
   string=$1
   shift
   "$@" >/dev/null && echo_info "${string}" || echo_error "${string}"
   rc=$?
   return $rc
}

# check system environment
check_env() {
	while [ $# -gt 0 ];do
		if ! rpm -q $1 &>/dev/null;then
			action "Install Pakeage $1" yum -q -y install $1
		fi
		shift
	done
}


install_httpd() {
	echo "Download httpd source..."
	echo "-----------------------------------------------------"
	curl -o /usr/local/src/${apr_version}.tar.gz ${apr_down1} || \
	curl -o /usr/local/src/${apr_version}.tar.gz ${apr_down2}
	curl -o /usr/local/src/${aprutil_version}.tar.gz ${aprutil_down1} || \
	curl -o /usr/local/src/${aprutil_version}.tar.gz ${aprutil_down2}
	curl -o /usr/local/src/${httpd_version}.tar.gz ${httpd_down1} || \
	curl -o /usr/local/src/${httpd_version}.tar.gz ${httpd_down2}
	echo "Startting Install..."
	echo "-----------------------------------------------------"
	cd /usr/local/src
	tar xf /usr/local/src/${httpd_version}.tar.gz
	tar xf /usr/local/src/${apr_version}.tar.gz
	tar xf /usr/local/src/${aprutil_version}.tar.gz
	cp -r ${apr_version} ${httpd_version}/srclib/apr
	cp -r ${aprutil_version} ${httpd_version}/srclib/apr-util
	cd ${httpd_version}
		./configure --prefix=/usr/local/httpd \
		--sysconfdir=/etc/httpd \
		--enable-so --enable-ssl \
		--enable-rewrite \
		--with-zlib \
		--with-pcre \
		--with-included-apr \
		--enable-deflate \
		--enable-modules=most \
		--enable-mpms-shared=all \
		--with-mpm=prefork
	make && make install

# httpd setting
	sed  '/DirectoryIndex index.html/s@index.html@index.php index.html@' /etc/httpd/httpd.conf
	cat >>/etc/httpd/httpd.conf <<EOF
ServerName 127.0.0.1:80
LoadModule proxy_module modules/mod_proxy.so
LoadModule proxy_fcgi_module modules/mod_proxy_fcgi.so
AddType application/x-httpd-php .php
AddType application/x-httpd-source .phps
ProxyRequests Off
ProxyPassMatch ^(.*\.php)$ fcgi://127.0.0.1:9000/usr/local/httpd/htdocs/$1
EOF

	mv /usr/local/httpd/htdocs/index.{html,php}
	cat >/usr/local/httpd/htdocs/index.php <<EOF
<?php
\$mysqli=new mysqli("localhost","root","123456");
if(mysqli_connect_errno()){
echo "connect to database failure!";
\$mysqli=null;
exit;
}
echo "connect to database success!";
\$mysqli->close();
phpinfo();
?>
EOF
}



install_php() {
	echo_info "Download php source..."
	curl -o /usr/local/src/${php_version}.tar.bz2 ${php_down1} || \
	curl -o /usr/local/src/${php_version}.tar.bz2 ${php_down2} 
	echo_info "Starting install php-fpm..."
	echo "-------------------------------------"
	cd /usr/local/src
	tar xf ${php_version}.tar.bz2
	cd ${php_version}
	./configure --prefix=/usr/local/php \
		--with-mysql=mysqlnd \
		--with-mysqli=mysqlnd \
		--with-pdo-mysql=mysqlnd \
		--with-openssl \
		--enable-mbstring \
		--with-freetype-dir  \
		--with-jpeg-dir \
		--with-png-dir \
		--with-zlib \
		--with-libxml-dir=/usr \
		--enable-xml \
		--enable-sockets \
		--enable-fpm \
		--with-mcrypt \
		--with-config-file-path=/etc/ \
		--with-config-file-scan-dir=/etc/php.d \
		--with-bz2
	make && make install 

# php setting
	cp /usr/local/php/etc/php-fpm.conf.default /usr/local/php/etc/php-fpm.conf
	cp /usr/local/src/${php_version}/sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm
	cp /usr/local/src/${php_version}/php.ini-production /etc/php.ini
	chmod +x /etc/init.d/php-fpm
	chkconfig --add php-fpm
}

install_xcache() {
	echo_info "DownLoad Xcache..."
	echo "-----------------------"
	curl -o /usr/local/src/${xcache_version}.tar.gz ${xcache_down1} || \
	curl -o /usr/local/src/${xcache_version}.tar.gz ${xcache_down2} 
	cd /usr/local/src
	tar xf ${xcache_version}.tar.gz
	cd ${xcache_version}
	/usr/local/php/bin/phpize
	./configure  --enable-xcache \
		--with-php-config=/usr/local/php/bin/php-config
	make && make install

# xcache setting
	mkdir /etc/php.d
	cp /usr/local/src/${xcache_version}/xcache.ini /etc/php.d/
	xcache_so_path=`find /usr/local/php/lib/php/extensions/ -name "xcache.so"`
	sed -i  '/^extension = xcache.so/c\extension = '"${xcache_so_path}"'' /etc/php.d/xcache.ini
}


install_mariadb() {
	echo_info "Download mariadb source..."
	echo "------------------------------------"
	curl -L -o /usr/local/src/${mariadb_version}-${mariadb_arch}.tar.gz ${mariadb_down1} || \
	curl -L -o /usr/local/src/${mariadb_version}-${mariadb_arch}.tar.gz ${mariadb_down2}
	cd /usr/local/src
	tar xf ${mariadb_version}-${mariadb_arch}.tar.gz -C /usr/local/
	ln -s /usr/local/${mariadb_version}-${mariadb_arch} /usr/local/mysql
	cd /usr/local/mysql

# setting mariadb
	id mysql &>/dev/null || useradd -r mysql
	touch /var/log/mysqld.log
	chown mysql /var/log/mysqld.log
	chown -R mysql.mysql .
	[ -d ${datadir} ] || mkdir $datadir
	./scripts/mysql_install_db --user=mysql --datadir=${datadir}
	cp support-files/my-huge.cnf /etc/my.cnf
	sed -i '/^\[mysqld\]/a\'datadir="${datadir}"'' /etc/my.cnf
	sed -i '/^\[mysqld\]/a\log-error=/var/log/mysqld.log' /etc/my.cnf
	cp support-files/mysql.server /etc/init.d/mysqld

# run mysql_secure_installation, default set db password '123456'
	service mysqld start
echo "
y
123456
123456
y
y
y
y" | /usr/local/mysql/bin/mysql_secure_installation 
echo 'export PATH=/usr/local/php/bin:/usr/local/httpd/bin:/usr/local/mysql/bin:$PATH' > /etc/profile.d/lamp.sh
. /etc/profile.d/lamp.sh
}

# Install verison you can change this
apr_version=apr-1.5.2
aprutil_version=apr-util-1.5.4
httpd_version=httpd-2.4.27
php_version=php-5.6.31
xcache_version=xcache-3.2.0
mariadb_version=mariadb-5.5.57
mariadb_arch=linux-x86_64

# Download website you can change this
apr_down1=ftp://172.18.0.1/pub/Sources/sources/httpd/${apr_version}.tar.bz2
apr_down2=http://mirrors.tuna.tsinghua.edu.cn/apache//apr/${apr_version}.tar.gz
aprutil_down1=ftp://172.18.0.1/pub/Sources/sources/httpd/${aprutil_version}.tar.bz2
aprutil_down2=http://mirrors.tuna.tsinghua.edu.cn/apache//apr/${aprutil_versiom}.tar.gz
httpd_down1=ftp://172.18.0.1/pub/Sources/sources/httpd/${httpd_version}.tar.bz2
httpd_down2=http://mirrors.tuna.tsinghua.edu.cn/apache//httpd/${httpd_version}.tar.gz
php_down1=ftp://172.18.0.1/pub/Sources/sources/php/${php_version}.tar.xz
php_down2=http://mirrors.sohu.com/php/${php_version}.tar.gz
xcache_down1=ftp://172.18.0.1/pub/Sources/sources/php/${xcache_version}.tar.bz2
xcache_down2=https://xcache.lighttpd.net/pub/Releases/${xcache_version#*-}/${xcache_version}.tar.gz
mariadb_down1=ftp://172.18.0.1/pub/Sources/6.x86_64/mariadb/${mariadb_version}-${mariadb_arch}.tar.gz
mariadb_down2=https://downloads.mariadb.org/interstitial/${mariadb_version}/bintar-${mariadb_arch}/${mariadb_version}-${mariadb_arch}.tar.gz/from/http%3A//mariadb.mirror.iweb.com

# my.cnf setting database dir
datadir=/mydata


# check system environment
check_env  make openssl-devel expat-devel pcre-devel gcc libxml2-devel bzip2-devel libmcrypt-devel autoconf


install_httpd
install_php
install_xcache
install_mariadb

service php-fpm start
service iptables stop
chkconfig iptables off
getenforce 0
/usr/local/httpd/bin/apachectl

echo "Install lamp finished, please input url http://<your ip> to make a test!" 
