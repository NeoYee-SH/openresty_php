#!/bin/bash
PWD=`pwd`

if [ ! -f "$PWD/nginx.conf" ];then
    echo 'file ./nginx.conf not found !'
    exit
fi

#安装 openresty
OPENRESTY_VERSION='1.13.6.2'
yum -y install wget gcc gcc-c++ autoconf automake pcre pcre-devel zlib zlib-devel openssl openssl-devel postgresql-devel

if [ ! -f "openresty-$OPENRESTY_VERSION.tar.gz" ];then
    wget https://openresty.org/download/openresty-$OPENRESTY_VERSION.tar.gz
fi

if [ ! -d "openresty-$OPENRESTY_VERSION" ];then
    tar zxvf openresty-$OPENRESTY_VERSION.tar.gz 
fi

cd openresty-$OPENRESTY_VERSION
./configure --prefix=/usr/local/openresty --with-luajit --without-http_redis2_module --with-http_iconv_module --with-http_postgres_module --sbin-path=/usr/sbin/nginx --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log --pid-path=/var/run/nginx/nginx.pid --lock-path=/var/lock/nginx.lock --user=nginx --group=nginx --with-http_ssl_module --with-http_flv_module --with-http_gzip_static_module --http-log-path=/var/log/nginx/access.log --http-client-body-temp-path=/var/tmp/nginx/client/ --http-proxy-temp-path=/var/tmp/nginx/proxy/ --http-fastcgi-temp-path=/var/tmp/nginx/fcgi/
make
make install
cd -

#安装 PHP
PHP_VERSION='7.2.10'
yum -y install libjpeg libjpeg-devel libpng libpng-devel freetype freetype-devel libxml2 libxml2-devel curl curl-devel libxslt libxslt-devel

if [ ! -f "mirror" ];then
    wget http://hk1.php.net/get/php-$PHP_VERSION.tar.gz/from/this/mirror
fi

if [ ! -d "php-$PHP_VERSION" ];then
    tar zxvf mirror
fi

cd php-$PHP_VERSION/
./configure --prefix=/usr/local/php --with-gd --with-jpeg-dir --with-png-dir --with-zlib --with-freetype-dir --with-libxml-dir --with-iconv --with-gettext=/usr --with-curl --with-openssl --with-pdo_mysql --with-mysqli --with-xsl --with-mhash --without-pdo-sqlite --enable-mbregex --enable-fpm --enable-shared --enable-mbstring --enable-pcntl --enable-opcache --enable-sockets --enable-dom --enable-simplexml --enable-zip --enable-shmop --enable-ftp --enable-bcmath
make
make install
cd -

#配置并启动
groupadd nginx
useradd -r -s /sbin/nologin -g nginx nginx -d /usr/local/nginx
rm -rf /etc/nginx/nginx.conf
cp $PWD/nginx.conf /etc/nginx/nginx.conf
mkdir /var/tmp/nginx
cp -n $PWD/php-$PHP_VERSION/php.ini-production /usr/local/php/lib/php.ini
export PATH=/usr/local/php/bin:/usr/local/php/sbin:$PATH
cp -n /usr/local/php/etc/php-fpm.conf.default /usr/local/php/etc/php-fpm.conf
cp -n /usr/local/php/etc/php-fpm.d/www.conf.default /usr/local/php/etc/php-fpm.d/www.conf
php-fpm
nginx
echo "<?php phpinfo(); ?>" > /usr/local/openresty/nginx/html/index.php