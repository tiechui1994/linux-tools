#!/bin/bash

#=============================================================
# axel是一款多线程文件下载器, 可以快速下载文件
#
# Ubuntu16.04 下 axel 安装
#=============================================================

VERSION="2.16.1"
WORK_DIR=$(pwd)/axel-${VERSION}
BASE="https://github.com/axel-download-accelerator/axel/releases/download"

command_exists() {
	command -v "$@" > /dev/null 2>&1
}

if [ "$(whoami)" != "root" ]; then
    echo "Please use root privileges to execute"
fi

if command_exists axel; then
    echo
    echo "Warning: the "axel" command appears to already exist on this system."
    exit
fi

# 下载源代码
if ! command_exists curl; then
    apt-get update && \
    apt-get install curl
fi

curl -o axel-${VERSION}.tar.gz ${BASE}/v${VERSION}/axel-${VERSION}.tar.gz && \
tar -zvxf axel-${VERSION}.tar.gz && \
cd axel-${VERSION}

# 安装依赖文件
apt-get update && \
apt-get install autoconf pkg-config gettext autopoint libssl-dev && \
autoreconf -fiv

# 编译安装
./configure && make && make install

# 检查
if command_exists axel; then
    echo "The axel install successful!!!"
else
    echo "The axel install failed"
fi

# 清理工作
cd ../ && \
rm -rf axel-${VERSION}*
