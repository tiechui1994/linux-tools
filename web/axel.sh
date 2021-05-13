#!/bin/bash

#----------------------------------------------------
# File: axel.sh
# Contents: axel是一款多线程文件下载器, 可以快速下载文件.
# Date: 19-1-18
#----------------------------------------------------

declare -r version=2.16.1
declare -r workdir=$(pwd)

declare -r SUCCESS=0
declare -r FAILURE=1

# log
log_error(){
    red="\033[97;41m"
    reset="\033[0m"
    msg="[E] $@"
    echo -e "$red$msg$reset"
}
log_warn(){
    yellow="\033[90;43m"
    reset="\033[0m"
    msg="[W] $@"
    echo -e "$yellow$msg$reset"
}
log_info() {
    green="\033[97;42m"
    reset="\033[0m"
    msg="[I] $@"
    echo -e "$green$msg$reset"
}

command_exists() {
	command -v "$@" > /dev/null 2>&1
}

common_download() {
    name=$1
    url=$2
    cmd=$3

    if [[ -d "$name" ]]; then
        log_info "$name has exist !!"
        return ${SUCCESS} #1
    fi

    if [[ -f "$name.tar.gz" && -n $(file "$name.tar.gz" | grep -o 'POSIX tar archive') ]]; then
        rm -rf ${name} && mkdir ${name}
        tar -zvxf ${name}.tar.gz -C ${name} --strip-components 1
        if [[ $? -ne 0 ]]; then
            log_error "$name decopress failed"
            rm -rf ${name} && rm -rf ${name}.tar.gz
            return ${FAILURE}
        fi

        return ${SUCCESS} #2
    fi

    log_info "$name url: $url"
    log_info "begin to donwload $name ...."
    rm -rf ${name}.tar.gz
    command_exists "$cmd"
    if [[ $? -eq 0 && "$cmd" == "axel" ]]; then
        axel -n 10 --insecure --quite -o "$name.tar.gz" ${url}
    else
        curl -C - --insecure --silent ${url} -o "$name.tar.gz"
    fi

    if [[ $? -ne 0 ]]; then
        log_error "download file $name failed !!"
        rm -rf ${name}.tar.gz
        return ${FAILURE}
    fi

    log_info "success to download $name"
    rm -rf ${name} && mkdir ${name}
    tar -zxf ${name}.tar.gz -C ${name} --strip-components 1
    if [[ $? -ne 0 ]]; then
        log_error "$name decopress failed"
        rm -rf ${name} && rm -rf ${name}.tar.gz
        return ${FAILURE}
    fi

    return ${SUCCESS} #3
}

check_param() {
    if [[ "$(whoami)" != "root" ]]; then
        log_warn "Please use root privileges to execute"
        exit
    fi

    if [[ command_exists axel ]]; then
        log_warn "The "axel" command appears to already exist on this system"
        exit
    fi
}

download_axel() {
    prefix="https://github.com/axel-download-accelerator/axel/releases/download"
    url=${prefix}/v${version}/axel-${version}.tar.gz

    common_download "axel" ${url}
    return $?
}

build() {
    # install depend
    apt-get update && \
    apt-get install autoconf pkg-config gettext autopoint libssl-dev && \
    autoreconf -fiv

    # build
    cd ${workdir}/axel && ./configure
    if [[ $? -ne 0 ]]; then
        log_error "configure fail"
        return ${FAILURE}
    fi

    cpu=$(cat /proc/cpuinfo | grep 'processor' | wc -l)
    make -j ${cpu}
    if [[ $? -ne 0 ]]; then
        log_error "build fail"
        return ${FAILURE}
    fi

    make install
    if [[ $? -ne 0 ]]; then
        log_error "install failed"
        return ${FAILURE}
    fi

    # check
    if [[ command_exists axel ]]; then
        log_info "the axel install successfully"
        return ${SUCCESS}
    else
        log_error "the axel install failed"
        return ${FAILURE}
    fi
}

clean() {
    cd ${workdir} && rm -rf axel-${version}*
}

do_install() {
    check_param
    download_axel
    if [[ $? -ne ${SUCCESS} ]]; then
        return
    fi

    build
    if [[ $? -ne ${SUCCESS} ]]; then
        return
    fi

    clean
}

do_install