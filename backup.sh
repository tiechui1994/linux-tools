#!/bin/sh
#备份文件到u盘中,只需要指定备份的目录即可

#检查u盘挂载情况
USB(){
 flag=`sudo -u root fdisk -l|grep  '(LBA)'|awk '{print $1}'`;
 echo $flag;
}
U=`USB`
if [ -z ${U} ];then
   sudo -u root sh /home/usb.sh
fi

U=`USB`
if [ -z ${U} ];then
  echo -e "\e[1;32mThe usb is not exsits!\e[0m";
  exit;   
fi

#检查传入的参数,只需要提供目录或者文件的绝对路径
if [ $# -eq 0 ];then
  echo -e "\e[1;32mThe argument is as follows:\n\e[0m\e[1;31m  /etc/passwd <---filename \n  /etc        <---directory\e[0m"
  exit
fi

#文件增量备份
NAME=`hostname`
if [ ! -d "/mnt/usb/${NAME}" ];then
   sudo -u root mkdir /mnt/usb/${NAME}
fi

for i in `echo $@ |xargs -n 1`
  do
    if  echo ${i}|grep -q -E '^/' ;then 
      i=${i}   
    else
      path=`pwd`
      i=${path}/${i}
    fi
     
   if [ -d ${i} ];then
      sudo -u root mkdir -p /mnt/usb/${NAME}${i}
      sudo -u root rsync -q -u -r  ${i}  /mnt/usb/${NAME}${i}
   else
      dir=`echo ${i}|grep -o -E "^/.*/"`;
      sudo -u root mkdir -p /mnt/usb/${NAME}${dir}
      sudo -u root rsync -q -u -r  ${i} /mnt/usb/${NAME}${i}
   fi
 done

