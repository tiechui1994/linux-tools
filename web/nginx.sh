#!/bin/bash

#======================================================
# 条件: ubuntu系统
#
# 源码编译安装nginx
#======================================================

INSTALL_DIR=/opt/local/nginx
VERSION=1.14.0

# 检查并安装curl
if [ -z `whereis curl | grep -E -o '/usr/bin/curl'` ]; then
   sudo apt-get update && sudo apt-get install curl -y
fi

# 获取源代码
curl http://nginx.org/download/nginx-${VERSION}.tar.gz -s -o nginx-${VERSION}.tar.gz

# 解压文件
tar -zvxf nginx-${VERSION}.tar.gz && cd nginx-${VERSION}
DIR=`pwd`

# 安装依赖的包
sudo apt-get install openssl libssl-dev libpcre3 libpcre3-dev zlib1g-dev libxml2 libxml2-dev libxslt-dev perl libperl-dev  -y

# 创建目录
sudo mkdir -p ${INSTALL_DIR}
sudo mkdir -p ${INSTALL_DIR}/tmp/client
sudo mkdir -p ${INSTALL_DIR}/tmp/proxy
sudo mkdir -p ${INSTALL_DIR}/tmp/fcgi
sudo mkdir -p ${INSTALL_DIR}/tmp/uwsgi
sudo mkdir -p ${INSTALL_DIR}/tmp/scgi

# 编译
${DIR}/configure \
--user=www  \
--group=www \
--prefix=${INSTALL_DIR} \
--with-poll_module \
--with-threads \
--with-file-aio \
--with-http_ssl_module \
--with-http_realip_module \
--with-http_addition_module \
--with-http_xslt_module=dynamic \
--with-http_sub_module \
--with-http_dav_module \
--with-http_flv_module \
--with-http_mp4_module \
--with-http_gzip_static_module \
--with-http_slice_module \
--with-http_stub_status_module \
--with-http_perl_module \
--with-mail \
--with-mail_ssl_module \
--with-stream \
--with-pcre \
--with-debug \
--http-client-body-temp-path=${INSTALL_DIR}/tmp/client \
--http-proxy-temp-path=${INSTALL_DIR}/tmp/proxy \
--http-fastcgi-temp-path=${INSTALL_DIR}/tmp/fcgi \
--http-uwsgi-temp-path=${INSTALL_DIR}/tmp/uwsgi \
--http-scgi-temp-path=${INSTALL_DIR}/tmp/scgi


# 编译安装
make -j4 && sudo make install

# 创建用户组并修改权限
sudo groupadd -r www
sudo useradd -r www -g www

sudo chown -R ${INSTALL_DIR}

# 启动
sudo ${INSTALL_DIR}/sbin/nginx

# 清理文件
sudo rm -rf nginx-*
