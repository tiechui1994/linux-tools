#!/bin/sh

#配置sudo用户

#执行命令的用户检查,必须是root用户
if [ `whoami` != "root" ];then
 echo -e "\e[1;31mNeed siwtch to root!\e[0m";
 exit;
fi

#参数检查
if [ -z $1 ];then
  echo -e "\e[1;31mUsage:Please input as follows:\n   sh sudo.sh\e[0m\e[1;32m USERNAME\e[0m";
  exit
fi

#输入用户合法性检查
NAME=${1}
if grep -q -o -E "^(${NAME})" /etc/passwd;then
  if [ ${NAME} != "root" ];then
     ADD="${NAME} ALL=(root)NOPASSWD:ALL";
  else
     echo -e "\e[1;31mThe current user is root.Do not configure sudoers\e[0m";
     exit;
  fi
else
  echo -e "\e[1;31mPlease input a legal USERNAME\e[0m"
  exit;
fi

#添加过程
PH="/etc/sudoers";
chmod u+w ${PH};

#检查是否已经是sudo用户
if grep -q -x -e "${ADD}" ${PH};then
  echo -e "\e[1;32m  ${NAME}\e[0m\e[1;31m has root's authority!!!\e[0m";
  chmod u-w ${PH};
  exit;
else
  echo ${ADD}>> ${PH}
  echo -e "\e[1;32m  ${NAME}\e[0m\e[1;31m has root's authority!!!\e[0m";
  chmod u-w ${PH};
  exit;
fi

