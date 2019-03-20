#!/bin/bash

#----------------------------------------------------
# File: awk.sh
# Contents: awk内容详解
# Date: 18-12-10
#----------------------------------------------------

#---------------------------------------------------------------------------------------------------
# awk介绍:
#   awk是linux shell 编程的三剑客(grep, sed, awk)之一, awk是强大的文本分析工具. 相对于grep的查找,
# sed的编辑, awk在其对数据分析并生成报告时,显得尤为强大.
#   简单来说awk就是把文件逐行的读入, 以空格为默认分隔符将每行切片, 切开的部分再进行各种分析处理.
#---------------------------------------------------------------------------------------------------


#---------------------------------------------------------------------------------------------------
# awk三种调用方式:
#   1. 命令行方式
#       awk 'commands' input-file(s)
#   2. shell脚步方式
#       将所有的awk命令插入一个文本, 并使用awk命令解释器执行
#       使用 #!/bin/awk 替换 #!/bin/bash
#   3. 将所有的awk命令插入一个单独文件,然后调用
#       awk -f awk-script input-file(s)
#---------------------------------------------------------------------------------------------------


#---------------------------------------------------------------------------------------------------
# awk常用:
#   语法:
#   awk [OPTIONS] 'pattern {action}' file
#
#   说明: BEGIN是开始控制; END是结束控制, 中间的是遍历的行控制
#
#   OPTIONS:
#       -F s, 设置域分隔符
#       -v var=value 为程序变量var赋值
#       --, 表示可选选项结束
#
#
#   AWK程序是一系列 pattern {action} 对 和 用户函数定义.
#   一个patern可以是:
#       BEGIN
#       END
#       expression
#       expression, expression
#
#   一个action是一段可执行的代码.
#
#   pattern {action}, 两者中可以省略一个, 但不能都被省略. 如果省略 {action}, 则隐示使用 {print}
#   如果 pattern 被省略, 则对文本全匹配. BEGIN和END模式需要一个动作.
#   语句由换行符,分号或两者终止.
#
#   example:
#       awk '/awk/ {print $1}; /www/ {print $1}' // 完整写法, /awk/ <=> $0 ~ /awk/
#       awk '/awk/'
#       awk '{print $1}'
#       awk 'BEGIN {print}'
#
#   express(正则匹配):
#       expr ~ /regex/
#       $0 ~ /regex/  <=> /regex/
#
#       regex: ^ $ . [ ] | ( ) * + ?
#
#   action(语法):
#       if ( expr ) statement
#       if ( expr ) statement else statement
#       while ( expr ) statement
#       do statement while ( expr )
#       for ( opt_expr ; opt_expr ; opt_expr ) statement
#       for ( var in array ) statement
#
#   express and operators:
#       ||, &&
#       +, -, *, /, <, >, in ....
#
#   内置参数:
#       ARGC 命令行参数个数
#       ARGV 命令行参数排列
#       ENVIRON 支持队列中系统环境变量的使用
#       FILENAME awk浏览的文件名
#       FNR 已经浏览文件的记录数(一般和NR相同)
#
#       NR 已读的记录数
#       NF 当前行的域的个数
#
#       FS 设置输入域分隔符, 等价于命令行 -F 选项
#       RS 文件记录分隔符, 默认是 '\n'
#
#       OFS 输出域分隔符, 默认 ' '
#       ORS 输出记录分隔符, 默认 '\n'
#
#       $0 当前行所有内容
#       $N 当前行第N个域
#
#   内置函数:
#       gsub(regex, str, repl) 全局替换, 使用repl替换regex匹配的字符串
#       sub(regex, str, repl) 只替换第一个
#       index(str, sub)
#       length(str)
#       match(str, regex)
#       split(str, array, separator), split(str, array)此时separator为FS
#       substr(str, index, length)
#       tolower(str)
#       toupper(str)
#---------------------------------------------------------------------------------------------------


awk '/sh/ && /root/ {print $1}' /etc/passwd

#---------------------------------------------------------------------------------------------------
# awk 传入参数:
#   awk -v var=value '{}' file
#   awk '{}' var=value file
#
#   declare $(awk '{}')
#
#   前两种方式, 只是传入参数, 在awk内部使用, 无法修改外部参数
#   最后一种方式, 既可以使用外部参数, 又可以修改外部参数(使用 print 拼接修改).
#
#    v=100
#    declare $(awk '{ print "v="1000 }' ./awk.sh)
#    echo ${v}
#
#    w=1
#    awk -v w=${w} '{ print(w); }' ./awk.sh
#    echo ${w}
#
#---------------------------------------------------------------------------------------------------