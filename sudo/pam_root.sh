#!/bin/bash

#----------------------------------------------------
# File: pam_root.sh
# Contents: sudo免密码操作root的所有命令
# Date: 18-11-11
#----------------------------------------------------

param_check() {
    user=$(whoami)
    # 参数检查
    if [[ ${user} != "root" ]]; then
        echo
        echo "ERROR: Please execute the script with root privileges"
        echo
        exit
    fi

    if [[ $# -lt 1 ]]; then
        echo
        echo "Usage: sudo ./pam_root.sh user1 user2 ..."
        echo

        exit
    fi

    # 检查sudo文件
    if [[ ! -e /etc/pam.d/sudo ]]; then
        echo
        echo -e "ERROR: Unable to increase root privileges"
        echo
        exit
    fi
}

add_user_to_wheel() {
    param_check $*

    check=$(cat /etc/pam.d/sudo | grep -E "^auth\s+sufficient\s+pam_wheel\.so\s+trust$")
    if [[ -z "${check}" ]]; then
        echo "auth  sufficient  pam_wheel.so    trust" >> /etc/pam.d/sudo
    fi

    # 获取wheel组
    if [[ ! $(cat /etc/group | grep -E "^wheel:") ]]; then
        groupadd wheel
    fi

    # 添加用户到组wheel
    for i in $*
    do
        if [[ $(cat /etc/passwd | grep -E "^$i:") ]]; then
            usermod -aG wheel ${i}
            echo "Success add root privilege to $i"
        else
            echo "WARNING: The user $i does not exist !!!"
        fi
    done
}

add_user_to_wheel $@