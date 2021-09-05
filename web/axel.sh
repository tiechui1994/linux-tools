#!/bin/bash

#----------------------------------------------------
# File: axel.sh
# Contents: axel是一款多线程文件下载器, 可以快速下载文件.
# Date: 19-1-18
#----------------------------------------------------

declare -r version=2.16.1
declare -r workdir=$(pwd)

declare -r success=0
declare -r failure=1

# log
log_error(){
    red="\033[31;1m"
    reset="\033[0m"
    msg="[E] $@"
    echo -e "$red$msg$reset"
}
log_warn(){
    yellow="\033[33;1m"
    reset="\033[0m"
    msg="[W] $@"
    echo -e "$yellow$msg$reset"
}
log_info() {
    green="\033[32;1m"
    reset="\033[0m"
    msg="[I] $@"
    echo -e "$green$msg$reset"
}

download() {
    name=$1
    url=$2
    cmd=$3
    decompress=$4

    declare -A extends=(
        ["tar"]="application/x-tar"
        ["tgz"]="application/gzip"
        ["tar.gz"]="application/gzip"
        ["tar.bz2"]="application/x-bzip2"
        ["tar.xz"]="application/x-xz"
    )

    extend="${name##*.}"
    filename="${name%%.*}"
    temp=${name%.*}
    if [[ ${temp##*.} = "tar" ]]; then
         extend="${temp##*.}.${extend}"
         filename="${temp%%.*}"
    fi

    # uncompress file
    if [[ -f "$name" ]]; then
        if [[ ${decompress} && ${extends[$extend]} && $(file -i "$name") =~ ${extends[$extend]} ]]; then
            rm -rf ${filename} && mkdir ${filename}
            tar -xf ${name} -C ${filename} --strip-components 1
            if [[ $? -ne 0 ]]; then
                log_error "$name decopress failed"
                rm -rf ${filename} && rm -rf ${name}
                return ${failure}
            fi
        fi

        return ${success} #2
    fi

    # download
    log_info "$name url: $url"
    log_info "begin to donwload $name ...."
    rm -rf ${name}

    command -v "$cmd" > /dev/null 2>&1
    if [[ $? -eq 0 && "$cmd" == "axel" ]]; then
        axel -n 10 --insecure --quite -o ${name} ${url}
    else
        curl -C - --insecure  --silent --location -o ${name} ${url}
    fi
    if [[ $? -ne 0 ]]; then
        log_error "download file $name failed !!"
        rm -rf ${name}
        return ${failure}
    fi

    log_info "success to download $name"

    # uncompress file
    if [[ ${decompress} && ${extends[$extend]} && $(file -i "$name") =~ ${extends[$extend]} ]]; then
        rm -rf ${filename} && mkdir ${filename}
        tar -xf ${name} -C ${filename} --strip-components 1
        if [[ $? -ne 0 ]]; then
            log_error "$name decopress failed"
            rm -rf ${filename} && rm -rf ${name}
            return ${failure}
        fi

        return ${success} #2
    fi
}

check_param() {
    if [[ "$(whoami)" != "root" ]]; then
        log_warn "Please use root privileges to execute"
        exit
    fi

    command -v "axel" > /dev/null 2>&1
    if [[ $? -eq 0 ]]; then
        log_warn "The "axel" command appears to already exist on this system"
        exit
    fi
}

download_axel() {
    prefix="https://github.com/axel-download-accelerator/axel/releases/download"
    url=${prefix}/v${version}/axel-${version}.tar.gz

    download "axel.tar.gz" ${url} curl 1
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
        return ${failure}
    fi

    cpu=$(cat /proc/cpuinfo | grep 'processor' | wc -l)
    make -j ${cpu}
    if [[ $? -ne 0 ]]; then
        log_error "build fail"
        return ${failure}
    fi

    make install
    if [[ $? -ne 0 ]]; then
        log_error "install failed"
        return ${failure}
    fi

    # check
    command -v "axel" > /dev/null 2>&1
    if [[ $? -eq 0 ]]; then
        log_info "the axel install successfully"
        return ${success}
    else
        log_error "the axel install failed"
        return ${failure}
    fi
}

clean() {
    cd ${workdir} && rm -rf axel-${version}*
}

do_install() {
    check_param
    download_axel
    if [[ $? -ne ${success} ]]; then
        return
    fi

    build
    if [[ $? -ne ${success} ]]; then
        return
    fi

    clean
}

do_install