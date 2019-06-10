#!/bin/bash

#----------------------------------------------------
# File: timezone
# Contents: set location timezone
# Date: 6/10/19
#----------------------------------------------------

timezone="Asia/Shanghai"

check_user(){
    if [[ "$(whoami)" != "root" ]];then
        echo
        echo "ERROR: Please execute the script with root privileges"
        echo
        exit
    fi
}

check_init() {
    if [[ $(systemctl) =~ -\.mount ]]; then
        return 1
    else
        return 0
    fi
}

do_set() {
    if [[ check_init ]]; then
        timedatectl set-timezone ${timezone}
    else
        echo ${timezone} > /etc/timezone
        ln -sf "/usr/share/zoneinfo/$timezone" /etc/localtime
    fi
}

do_install() {
    check_user
    do_set
}

do_install