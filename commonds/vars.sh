#!/bin/bash

#========================================================
# 条件变量替换
#========================================================

# bash shell可以进行变量的条件替换, 即只有某种条件发生时才进行替换,替换的条件放在{}中
# ${value:-word}  当变量value未定义或者值为空时, 返回word, 否则返回value的值
echo ${v:-"未定义"}
v=
echo ${v:-"空"}

# ${value:+word} 若变量value已经赋值, 返回word. 否则不进行任何操作
n="AA"
echo ${n:+"BB"}


# ${value:=word} 当变量value未定义或者值为空时, 返回word的同时将word赋值给value, 否则返回value的值
echo ${p:="未定义"}
p=
echo ${p:="空"}
echo ${p}


# ${value:?message} 若变量value已经赋值,正常运行. 否则将消息message送到标准输出, 并终止shell程序运行
# echo ${m:?"message"}


# ${#value} 获取变量value值字符的个数
x="AA"
echo ${#x}

# ${value:offset:length} 字符串的截取操作(切片操作)
y="abcdefg"
echo ${y:1:2}


# ${value#pattern}  字符串left trim掉pattern
z="ABC"
echo ${z#"A"}

# ${value%pattern} 字符串right trim掉pattern
echo ${z%"C"}

# ${value//pattern/string}  字符串replace操作
t=" A C Y"
echo ${t//" "/"-"}
