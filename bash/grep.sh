#!/bin/bash

#----------------------------------------------------
# File: grep.sh
# Contents: grep method
# Date: 9/3/19
#----------------------------------------------------


#---------------------------------------------------------------------------------------------------
# grep
#
# grep [OPTIONS] PATTERN [FILE...]
# grep [OPTIONS] [-e PATTERN]...  [-f FILE]...  [FILE...]
#
# OPTIONS - (Matcher Selection)
#   -E, --extended-regexp  将PATTERN解释为扩展正则表达式.
#   -F, --fixed-strings    将PATTERN解释为固定字符串列表(而不是正则表达式), 由换行符分隔, 其中任何一个都要匹配.
#   -G, --basic-regexp     将PATTERN解释为基本正则表达式(BRE). 这是默认值.
#   -P, --perl-regexp      将模式解释为Perl兼容的正则表达式(PCRE). 这是高度实验性的, grep -P可能会警告未实现的功能.
#
# OPTIONS - (Matching Control)
#   -e  PATTERN, --regexp=PATTERN   使用PATTERN作为模式. 如果多次使用此选项或与-f(--file)选项组合使用, 将搜索
# 给定的所有模式. 此选项可用于保护以"-"开头的模式.
#
#   -f FILE, --file=FILE    从FILE获取模式, 每行一个. 如果多次使用此选项或与-e(--regexp)选项组合使用, 将搜索给定
# 的所有模式. 空文件包含零模式, 因此不匹配任何内容.
#
#   -i, --ignore-case   忽略大小写
#   -v, --invert-match  反转匹配
#   -w, --word-regexp   仅选择包含构成整个单词的匹配项的行. 单词构成字符是字母,数字和下划线.
#   -x, --line-regexp   仅选择与整行完全匹配的匹配项. 对于正则表达式模式, 这就像括号模式然后用^和$包围它.
#
# OPTIONS - (General Output Control)
#   -c, --count 抑制正常输出; 而是为每个输入文件打印匹配行的计数. 使用-v, -inverse-match选项,计算不匹配的行.
#
#   -L, --files-without-match   抑制正常输出; 而是打印每个输入文件的名称(匹配). 在第一个匹配之后扫描停止.
#   -l, --files-with-matches    抑制正常输出; 而是打印每个输入文件的名称(不匹配). 在第一个匹配之后扫描停止.
#
#   -m, --max-count=NUM 设置最大匹配数量
#
#   -o, --only-matching 只打印匹配的内容
#
#   -q, --quiet, --silent   不输出任何内容
#
# OPTIONS - (Output Line Prefix Control)
#    -n, --line-number  在输入文件中使用基于1的行号为每行输出添加前缀.
#
# OPTIONS - (Context Line Control)
#   -A NUM, --after-context=NUM  匹配行后的NUM行
#   -B NUM, --before-context=NUM 匹配行前的NUM行
#   -C NUM, --context=NUM        匹配行前的NUM行和匹配行后的NUM行
#
#
# OPTIONS - (File and Directory Selection)
#   -a, --text  像处理文本一样处理二进制文件; 这相当于--binary-files=text选项.
#
#   --binary-files=TYPE   如果文件的前几个字节表明该文件包含二进制数据, 则假定该文件的类型为TYPE. 默认情况下, TYPE
# 是binary,  grep通常输出一行表示二进制文件匹配的消息, 或者如果没有匹配则不输出消息. 如果TYPE不匹配, 则grep假定二进制
# 文件不匹配; 这相当于-I选项. 如果TYPE是text, 则grep处理二进制文件, 就好像它是文本一样; 这相当于-a选项. 处理二进制数
# 据时, grep可能会将非文本字节视为行终止符; 例如, 模式'.' (句点)可能与空字节不匹配, 因为空字节可能被视为行终止符.
# 警告: grep --binary-files=text可能会输出二进制垃圾, 如果输出是终端, 并且终端驱动程序将其中一些解释为命令,则可能会
# 产生令人讨厌的副作用.
#
#   -D ACTION, --devices=ACTION 如果输入文件是device,FIFO或套接字, 请使用ACTION处理它. 默认情况下, 读取ACTION,
# 这意味着读取设备就像它们是普通文件一样. 如果跳过ACTION, 则会以静默方式跳过设备.
#
#   -d ACTION, --directories=ACTION  如果输入文件是目录, 请使用ACTION处理它. 默认情况下, 读取ACTION, 即读取目录,
# 就像它们是普通文件一样. 如果跳过ACTION, 则以静默方式跳过目录. 如果ACTION是递归的, 则只有在命令行上时, 才能以符号链接
# 的形式递归读取每个目录下的所有文件. 这相当于-r选项.
#
#
#   -r, --recursive 只有符号链接在命令行上时, 才能递归地读取每个目录下的所有文件. 请注意, 如果没有给出文件操作数,
# grep将搜索工作目录. 这相当于-d recurse选项.
#
#   -R, --dereference-recursive  递归地读取每个目录下的所有文件. 跟随所有符号链接, 与-r不同.
#
#
#---------------------------------------------------------------------------------------------------

#---------------------------------------------------------------------------------------------------
# grep支持的POSIX字符类:
#
# [[:alnum:]] 文字数字字符(文字,数字)
# [[:alpha:]] 文字字符
# [[:digit:]] 数字字符
# [[:xdigit:]] 十六进制数字(0-9,a-f,A-F)
#
# [[:cntrl:]] 控制字符
# [[:graph:]] 非空字符(非空格,控制字符)
# [[:print:]] 非空字符(包括空格)
# [[:punct:]] 标点符号(括号,点,逗号,下划线,中划线,分号,等)
# [[:space:]] 所有空白字符(新行,空格,制表符)
#
# [[:upper:]] 大写字符
# [[:lower:]] 小写字符
#
#---------------------------------------------------------------------------------------------------