#!/bin/bash

#=============================================================
# axel是一款多线程文件下载器, 可以快速下载文件
#
# Ubuntu16.04 下 axel 安装
#=============================================================

version="2.16.1"
workdir=$(pwd)/axel-${version}

command_exists() {
	command -v "$@" > /dev/null 2>&1
}

check_param() {
    if [[ "$(whoami)" != "root" ]]; then
        echo "Please use root privileges to execute"
        exit
    fi

    if command_exists axel; then
        echo
        echo "Warning: the "axel" command appears to already exist on this system."
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
        echo "The axel install successful!!!"
    else
        echo "The axel install failed"
    fi
}

clear() {
    # 清理工作
    cd ../ && rm -rf axel-${version}*
}

install() {
    check_param
    download_source_code
    do_install
    clear
}

install