#!/bin/bash

#----------------------------------------------------
# File: sudoer_root.sh
# Contents: 向/etc/sudoers当中添加免密码root
# Date: 18-11-11
#----------------------------------------------------

user=
add=

check_param() {
# 执行权限检查
if [[ "$(whoami)" != "root" ]];then
    echo
    echo "ERROR: Need siwtch to root! "
    echo

    exit
fi

# 参数检查
if [[ -z $1 ]];then
    echo
    echo "Usage: Please input as follows:"
    echo "   sudo ./sudoer_root.sh USERNAME"
    echo

    exit
fi

# 用户检测
if grep -q -o -E "^($1)" /etc/passwd; then
    if [[ $1 != "root" ]];then
        user=$1
        add="$1 ALL=(root)NOPASSWD:ALL";
    else
        echo
        echo "WARNING: The current user is root. Do not need to configure sudoers"
        echo

        exit
    fi
else
    echo "ERROR: Please input a legal USERNAME"

    exit
fi
}

add_user_to_sudoers() {
    sudoers="/etc/sudoers"

    if [[ -e ${sudoers} ]]; then
         chmod u+w ${sudoers}
    else
        exit
    fi

    # 检查是否已经是sudo用户
    if grep -q -x -e "${user}" ${sudoers}; then
        echo
        echo "${user} has root's authority !!!"
        echo

        chmod u-w ${sudoers}
        exit
    else
        echo ${add} >> ${sudoers}

        echo
        echo "${user} has root's authority !!!"
        echo

        chmod u-w ${sudoers}
        exit
    fi
}

check_param $@ && add_user_to_sudoers
