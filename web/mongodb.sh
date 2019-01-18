#!/bin/bash

#----------------------------------------------------
# File: mongodb.sh
# Contents: 安装mongodb服务
# Date: 19-1-18
#----------------------------------------------------

version=3.6.9
workdir=$(pwd)/mongodb-${version}
installdir=/opt/local/mongodb

command_exists() {
	command -v "$@" > /dev/null 2>&1
}

check_param() {
    if [[ "$(whoami)" != "root" ]]; then
        echo
        echo "Please use root privileges to execute"
        echo
        exit
    fi

    if ! command_exists axel; then
        apt-get update && sudo apt-get install axel -y
    fi
}

download_bin_package() {
    http="https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-${version}.tgz"
    axel -n 100 "${http}" -o mongodb-${version}.tgz

    # 解压源文件
    if [[ -e ${workdir} ]]; then
       rm -rf ${workdir}
    fi

    if [[ -e ${installdir} ]]; then
        rm -rf ${installdir}
    fi

    # 构建mongodb
    mkdir ${workdir} && \
    tar -zvxf mongodb-${version}.tgz -C ${workdir} --strip-components 1 && \
    mv ${workdir} ${installdir}
}

add_service() {
    # 创建必要的目录
    mkdir -p ${installdir}/conf && \
    mkdir -p ${installdir}/data && \
    mkdir -p ${installdir}/logs

    # 添加conf配置
    cat >> ${installdir}/conf/mongodb.conf << EOF
#pid file
pidfilepath=${installdir}/logs/mongodb.pid

#log file
logpath=${installdir}/logs/mongodb.log

#log append
logappend=true

#run as deamon
fork = true

#port
port = 27017

#data dir
dbpath=${installdir}/data

#record cpu use
cpu = true

#是否以安全认证方式运行，默认为非安全模式，不进行认证
noauth = true
#auth = true

#详细记录输出
verbose = true

#Enable db quota management
quota = true

# Set oplogging level where n is
#   0=off (default)
#   1=W
#   2=R
#   3=both
#   7=W+some reads
#diaglog=0

#Diagnostic/debugging option 动态调试项
#nocursors = true
#
#Ignore query hints 忽略查询提示
#nohints = true
#
#禁用http界面，默认为localhost:28017
#nohttpinterface = true
#
#关闭服务器端脚本，这将极大的限制功能
#noscripting = true
#
#关闭扫描表，任何查询将会是扫描失败
#notablescan = true
#
#关闭数据文件预分配
#noprealloc = true
#
#为新数据库指定.ns文件的大小,单位:MB
#nssize =
#
#Replication Options 复制选项
#replSet=setname
#
#maximum size in megabytes for replication operation log
#oplogSize=1024
#
#指定存储身份验证信息的密钥文件的路径
#keyFile=/path/to/keyfile
#
EOF

    # 添加service
     cat >> /etc/init/mongod << EOF
#!/bin/sh

MONGOND=${installdir}/bin/mongod
CONF=${installdir}/conf/mongodb.conf
PID=${installdir}/logs/mongodb.pid

# Try to extract nginx pidfile
PID=$(cat ${CONF} | grep -Ev '^\s*#' | awk 'BEGIN { RS="[;{}]" } { if ($1 == "pidfilepath") print $2 }' | head -n1)
if [ -z "${PID}" ]; then
    PID=${installdir}/logs/mongodb.pid
fi
EOF
}

do_install() {
    check_param
#    download_bin_package
    add_service
}

do_install