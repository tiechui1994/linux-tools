#!/bin/bash

#----------------------------------------------------
# File: sudoer-root.sh
# Contents: 向/etc/sudoers当中添加免密码root
# Date: 18-11-11
#----------------------------------------------------

USERNAME=""

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

check_user() {
    if [[ "$USER" != "root" ]];then
        log_error "need siwtch to root"
        return 1
    fi

    if [[ $# != 1 ]]; then
        log_error "usage: please input as follows:"
        log_error "   sudo ./sudoer_root.sh USERNAME"
        return 1
    fi

    if [[ $1 -eq "root" ]]; then
        log_warn "the current user is root. do not need to configure sudoers"
        return 1
    fi

    grep -o -E "^$1" /etc/passwd
    if [[ $? = 0 ]]; then
        USERNAME=$1
    else
        log_error "please input a legal USERNAME"
        return 1
    fi
}

add_user_to_sudoers() {
    sudoers="/etc/sudoers"
    if [[ -e ${sudoers} ]]; then
         chmod u+w ${sudoers}
    else
        return
    fi

    # 检查是否已经是sudo用户
    grep -q -x -E "^$USERNAME" ${sudoers}
    if [[ $? = 0 ]]; then
        log_info "$USERNAME has root's authority"
    else
        echo "$1 ALL=(root)NOPASSWD:ALL" >> ${sudoers}
        log_info "$USERNAME has root's authority"
    fi

    chmod u-w ${sudoers}
}

check_user $@ && add_user_to_sudoers
