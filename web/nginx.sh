#!/bin/bash

#======================================================
# 条件: ubuntu系统
#
# 源码编译安装nginx
#======================================================

INSTALL_DIR=/opt/local/nginx
VERSION=1.14.0
WORKDIR=`pwd`/nginx-${VERSION}

#######################  准备工作 #######################################
# 安装下载工具
if [ -z `whereis axel | grep -E -o '/usr/bin/axel'` ]; then
   sudo apt-get update && sudo apt-get install axel -y
fi

# 安装依赖的包
sudo apt-get update && \
sudo apt-get install openssl libssl-dev libpcre3 libpcre3-dev zlib1g-dev libxml2 libxml2-dev libxslt-dev perl libperl-dev  -y

# 获取源代码
axel -n 100 http://nginx.org/download/nginx-${VERSION}.tar.gz -f nginx-${VERSION}.tar.gz

# 解压文件
tar -zvxf nginx-${VERSION}.tar.gz && cd nginx-${VERSION}



##########################  源码编译安装  #################################
# 创建目录
sudo mkdir -p ${INSTALL_DIR}
sudo mkdir -p ${INSTALL_DIR}/tmp/client
sudo mkdir -p ${INSTALL_DIR}/tmp/proxy
sudo mkdir -p ${INSTALL_DIR}/tmp/fcgi
sudo mkdir -p ${INSTALL_DIR}/tmp/uwsgi
sudo mkdir -p ${INSTALL_DIR}/tmp/scgi

# 创建用户组并修改权限
sudo groupadd -r www
sudo useradd -r www -g www

# 编译
${WORKDIR}/configure \
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


# 安装
make -j4 && sudo make install


# 启动
sudo chown -R ${INSTALL_DIR} && \
sudo ${INSTALL_DIR}/sbin/nginx



##############################  文件清理  ##################################
# 清理文件
sudo rm -rf nginx-*
