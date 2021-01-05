#!/bin/bash

#----------------------------------------------------
# File: pam-root.sh
# Contents: sudo免密码操作root的所有命令
# Date: 18-11-11
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

param_check() {
    if [[ "$USER" != "root" ]]; then
        log_error "please execute the script with root privileges"
        return 1
    fi

    if [[ ! -e /etc/pam.d/sudo ]]; then
        log_error "unable to increase root privileges"
        return 1
    fi
}

add_user_to_wheel() {
    # params
    if [[ $# -lt 1 ]]; then
        log_error "sudo ./pam-root.sh user1 user2 ..."
        return 1
    fi

    # check
    grep -E "^auth\s+sufficient\s+pam_wheel\.so\s+trust$" /etc/pam.d/sudo
    if [[ $? != 0 ]]; then
        echo "auth  sufficient  pam_wheel.so    trust" >> /etc/pam.d/sudo
    fi

    # wheel group
    grep -o -E "^wheel:" /etc/group
    if [[ $? != 0 ]]; then
        groupadd wheel
    fi

    # add user to wheel
    for i in $*
    do
        grep -o -E "^$i:" /etc/passwd
        if [[ $? != 0 ]]; then
            usermod -aG wheel ${i}
            log_info "success add root privilege to $i"
        else
            log_warn "the user $i does not exist"
        fi
    done
}

param_check && add_user_to_wheel $@