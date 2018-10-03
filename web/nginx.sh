#!/bin/bash

#======================================================
# 条件: ubuntu系统
#
# 源码编译安装 nginx
#======================================================

INSTALL_DIR=/opt/local/nginx
VERSION=1.14.0
WORKDIR=`pwd`/nginx-${VERSION}
USER=`whoami`

if [ "${USER}" != "root" ]; then
    echo "请使用root权限执行"
    exit
fi

#######################  准备工作 #######################################
# 安装下载工具
if [ -z `whereis axel | grep -E -o '/usr/bin/axel'` ]; then
   apt-get update && sudo apt-get install axel -y
fi

# 安装依赖的包
apt-get update && \
apt-get install zlib1g-dev openssl libssl-dev libpcre3 libpcre3-dev libxml2 libxml2-dev libxslt-dev perl libperl-dev -y

# 获取源代码
echo http://nginx.org/download/nginx-${VERSION}.tar.gz
axel -n 100 -o nginx-${VERSION}.tar.gz http://nginx.org/download/nginx-${VERSION}.tar.gz

# 解压文件
tar -zvxf nginx-${VERSION}.tar.gz && cd nginx-${VERSION}



##########################  源码编译安装  #################################
# 创建目录
rm -rf  ${INSTALL_DIR} && \
mkdir -p ${INSTALL_DIR} && \
mkdir -p ${INSTALL_DIR}/tmp/client && \
mkdir -p ${INSTALL_DIR}/tmp/proxy && \
mkdir -p ${INSTALL_DIR}/tmp/fcgi && \
mkdir -p ${INSTALL_DIR}/tmp/uwsgi && \
mkdir -p ${INSTALL_DIR}/tmp/scgi

# 创建用户组并修改权限
if [ -z `cat /etc/group | grep -E '^www:'` ]; then
    groupadd -r www
fi

if [ -z `cat /etc/password | grep -E '^www:'` ]; then
    useradd -r www -g www
fi

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
cpu=`cat /proc/cpuinfo |grep 'processor'|wc -l`
make -j${cpu} && sudo make install


# 启动
chown -R www:www ${INSTALL_DIR} && \
${INSTALL_DIR}/sbin/nginx

# 测试
if ps aux|grep -E  "master.*/opt/local/nginx/sbin/nginx$"; then
    echo "========================================================"
    echo "nginx install success!!!"
fi


##############################  文件清理  ##################################
# 清理文件
cd ../ && \
rm -rf nginx-*
