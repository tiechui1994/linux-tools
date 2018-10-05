#!/bin/bash

#========================================================
# 前提: ubuntu系统
# 
# 为当前用户增加sudo免密码权限
#========================================================

USER=$(whoami)

# 参数检查
if [ ${USER} != "root" ]; then
    echo -e "\033[1;31mPlease execute the script with root privileges\033[0m"
    exit
fi

if [ $# -lt 1 ];then
    echo -e "\033[1;31mUsage: bash sudo.sh user1 user2 ...\033[0m"
    exit
fi

# 检查sudo文件
if [ ! -e /etc/pam.d/sudo ]; then
    echo -e "\033[1;31mUnable to increase root privileges\033[0m"
    exit
fi

check=$(cat /etc/pam.d/sudo | grep -E "^auth[ ]+sufficient[ ]+pam_wheel\.so[ ]+trust$")
if [ -z "${check}" ]; then
    echo "auth  sufficient  pam_wheel.so    trust" >> /etc/pam.d/sudo
fi

# 查看用户组
if [ ! $(cat /etc/group | grep -E "^wheel:") ]; then
    groupadd wheel
fi

# 添加用户到组wheel
for i in $*
do
    if [ $(cat /etc/passwd | grep -E "^${i}:") ]; then
        usermod -aG wheel ${i}
        echo -e "\033[1;32mSuccess add root privilege to ${i}\033[0m"
    fi
done

