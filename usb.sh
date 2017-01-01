#!/bin/sh
#加载u盘脚本

#防止多次调用脚本带来的异常信息！
flag='/mnt/usb/System Volume Information'
if [ -e "${flag}" ];then
  echo -e "\e[1;32m   The USB Disk Is Ok\e[0m";
  exit;
fi

#加载USB模块
sudo -u root modprobe usb-storage

#查看USB的设备
USB=`sudo -u root fdisk -l|grep  '(LBA)'|awk '{print $1}'`
if [ -z ${USB} ];then
   echo -e "\e[1;32mThe disk is not exist!\e[0m";
   exit 1;
fi
#建立/mnt/usb文件夹
if [ ! -d "/mnt/usb" ];then
   sudo -u root /mnt/usb
fi

#载入u盘
sudo -u root mount ${USB}   /mnt/usb

#挂载情况
if [ -e "${flag}" ];then
  echo -e "\e[1;32m   The USB Disk Is Ok\e[0m";
else
  echo -e "\e[1;32m   Please Checkout Your Device\e[0m";
fi


