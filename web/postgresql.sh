#!/bin/sh

#=================================================================
# ubuntu16.04安装 postgresql
#==================================================================

VERSION=10.5
WORKDIR=$(pwd)/mysql-${VERSION}
INSTALL_DIR=/opt/local/pgsql
USER=$(whoami)

if [ "${USER}" != "root" ]; then
    echo "请使用root权限执行"
    exit
fi

command_exists() {
	command -v "$@" > /dev/null 2>&1
}

#######################  准备工作 #######################################
## 安装下载工具
#if [ ! command_exists axel ]; then
#   apt-get update && sudo apt-get install axel -y
#fi
#
## 获取源代码
#doamin=http://ftp.postgresql.org/pub/source
#axel -n 100 -o postgresql-${VERSION}.tar.gz "${doamin}/v${VERSION}/postgresql-${VERSION}.tar.gz"
#
## 解压文件
#tar -zvxf postgresql-${VERSION}.tar.gz && cd postgresql-${VERSION}
#
## 安装依赖包
#apt-get install zlib1g zlib1g-dev libedit-dev libperl-dev openssl libssl-dev \
#libxml2 libxml2-dev libxslt-dev bison tcl tcl-dev flex -y

#######################  安装 #######################################
# 删除旧目录
rm -rf ${INSTALL_DIR}

# 编译配置
cd postgresql-${VERSION} && \
./configure \
--prefix=${INSTALL_DIR} \
--with-tcl \
--with-perl \
--with-openssl \
--without-readline \
--with-libedit-preferred \
--with-libxml \
--with-libxslt

# 安装
cpu=$(cat /proc/cpuinfo |grep 'processor'|wc -l)
make -j${cpu} && sudo make install

# 配置
mkdir ${INSTALL_DIR}/conf && \
mkdir ${INSTALL_DIR}/data && \
mkdir ${INSTALL_DIR}/log

