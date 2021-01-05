#!/bin/bash

#----------------------------------------------------
# File: pam-ssh-2fa.sh
# Contents: ssh pam 2fa
# Date: 1/5/21
# Doc: http://blog.gaoyuan.xyz/2017/01/05/2fa-a-programmers-perspective/
#----------------------------------------------------

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


common_download() {
    name=$1
    url=$2
    cmd=$3

    if [[ -d "$name" ]]; then
        log_info "$name has exist !!"
        return 0 #1
    fi

    if [[ -f "$name.tar.gz" && -n $(file "$name.tar.gz" | grep -o 'POSIX tar archive') ]]; then
        rm -rf ${name} && mkdir ${name}
        tar -zvxf ${name}.tar.gz -C ${name} --strip-components 1
        if [[ $? -ne 0 ]]; then
            log_error "$name decopress failed"
            rm -rf ${name} && rm -rf ${name}.tar.gz
            return -1
        fi

        return -1 #2
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
        return -1
    fi

    log_info "success to download $name"
    rm -rf ${name} && mkdir ${name}
    tar -zxf ${name}.tar.gz -C ${name} --strip-components 1
    if [[ $? -ne 0 ]]; then
        log_error "$name decopress failed"
        rm -rf ${name} && rm -rf ${name}.tar.gz
        return -1
    fi

    return 0 #3
}