#!/bin/sh

#===============================================
# 源码安装 devocat
#===============================================

installdir=/mail
url='https://www.dovecot.org/releases/2.3/dovecot-2.3.3.tar.gz'
curdir=$(pwd)/dovecot-2.3.3

command_exists() {
	command -v "$@" > /dev/null 2>&1
}

if [ "$(whoami)" != "root" ]; then
     echo "Please use root privileges to execute"
    exit
fi

################################# 源码下载  ####################################
if [ command_exists curl ];then
    curl -o dovecot-2.3.3.tar.gz ${url}
fi

################################# 安装 ########################################
./configure && \
--prefix=${installdir}