#!/bin/bash

#----------------------------------------------------
# File: axel.sh
# Contents: axel是一款多线程文件下载器, 可以快速下载文件.
# Date: 19-1-18
#----------------------------------------------------

version="2.16.1"
workdir=$(pwd)/axel-${version}

command_exists() {
	command -v "$@" > /dev/null 2>&1
}

check_param() {
    if [[ "$(whoami)" != "root" ]]; then
        echo
        echo "ERROR: Please use root privileges to execute"
        echo
        exit
    fi

    if command_exists axel; then
        echo
        echo "WARN: The "axel" command appears to already exist on this system"
        echo
        exit
    fi
}

download_source_code() {
    # 下载源代码
    if ! command_exists curl; then
        apt-get update && apt-get install curl
    fi

    prefix="https://github.com/axel-download-accelerator/axel/releases/download"
    curl -o axel-${version}.tar.gz ${prefix}/v${version}/axel-${version}.tar.gz && \
    tar -zvxf axel-${version}.tar.gz
}

do_install() {
    # 安装依赖文件
    apt-get update && \
    apt-get install autoconf pkg-config gettext autopoint libssl-dev && \
    autoreconf -fiv

    # 编译安装
     cd ${workdir} && \
    ./configure && make && make install

    # 检查
    if command_exists axel; then
        echo
        echo "INFO: The axel install successfully"
        echo
    else
        echo
        echo "ERROR: The axel install failed"
        echo
    fi
}

clear() {
    # 清理工作
    cd ../ && rm -rf axel-${version}*
}

do_install() {
    check_param
    download_source_code
    do_install
    clear
}

do_install