#!/bin/bash

#----------------------------------------------------
# File: stdout.sh
# Contents: print vs echo
# Date: 19-03-20
#----------------------------------------------------


#####################  输出格式  ####################
# echo 换行输出
# printf 一行输出

echo "======================"
echo "123"
echo "======================"


printf "======================"
printf "123"
printf "======================"
printf "\n"



###################  echo特色  #####################
# echo -e "\e[1;NNm...\e[0m", 其中\e等价于\033
# 字体色NN  0:默认, 31:红色, 32:绿色, 33:黄色, 34:蓝色, 35:紫色
# 背景色NN  0:默认, 41:红色, 42:绿色, 43:黄色, 34:蓝色, 45:紫色

echo -e "\033[1;31mRed Background \033[0m"

echo -e "\e[1;31mRed Background \e[0m"

echo -e "\e[1;41mRed Background\e[0m"

# echo -n "..." 取消换行输出
echo -n "1"
echo -n "2"
echo



#######################  printf特色  ##########################
# printf 格式化输出
# %d, %d, %d
#

printf "%10s : %-10s\n" "Name" "Address"
printf "%10s : %-10s\n" "Tom" "HeiBei Province"
printf "%10s : %-10s\n" "Jack" "陕西省西安市蓝田县张家口乡"
