#!/bin/sh

#------------------------------------------------
#  进程管理常用命令
#------------------------------------------------

ps

top

nice

renice

# kill 发送一个信号给进程. 默认情况下发送的信号是TERM, 特别有用的信号包括HUP, INT, KILL, COUT
#      TERM 15 终止
#      HUP 1 终端断线
#      INIT 2 中断(Ctrl + C)
#      QUIT 3 退出(Ctrl + \)
#      KILL 9 强制终止
#      CONT 18 继续
#      STOP 19 暂停
# 
# kill [ OPTION ] <pid> [ ... ]
# 参数:
#     -<signal>, -s <signal>, --signal <signal> 发送特定信号, signal可以是name或num
#     -l [signal] 列出信号. 如果给定signal, 则列出与signal相关的信号
#
#
# ===========================================================================================
#
#
# ulimit 设置进程的资源
#
# ulimit [ OPTION ]
# 参数:
#     -a 　 显示目前资源限制的设定.
#
#     -c <core文件上限> 　设定core文件的最大值,单位为区块.
#     -f <文件大小> 　   shell所能建立的最大文件,单位为区块.
#
#     -d <数据区大小> 　程序数据节区的最大值,单位为KB.
#     -s <堆栈大小> 　指定堆叠的上限,单位为KB.
#     -m <内存大小> 　指定可使用内存的上限,单位为KB.
#     -l <锁定内存大小> 指定锁定内存的上限, 单位KB, 默认64
#     -v <虚拟内存大小> 　指定可使用的虚拟内存上限,单位为KB
#     -p <管道大小> 　指定管道缓冲区的大小,单位512字节/0.5KB, 默认是8
#     
#     -n <文件数目> 　指定同一时间最多可打开的文件数. 默认1024
#     -u <进程数目> 　用户最多可启动的进程数目. 默认63227
#     -e <调度优先级> 调度优先级, 默认0
#     -x <文件锁数目> 一个文件最多加锁数目
#     
#     -t <CPU时间> 　指定CPU使用时间的上限,单位为秒.
#
#     -H 　设定资源的硬性限制,也就是管理员所设下的限制.
#     -S 　设定资源的弹性限制.
#
#  NOTE: ulimit的修改只是在当前会话期间有效, 要想永久有效, 需要在/etc/security/limits.conf文件当中
#        添加相应的限制规则.(里面有相应的说明文档)
#
#
# ===========================================================================================
#
#
# w  展示登录者是谁以及正在做的事情
# 
# w [ OPTION ]
# 
# OPTION:
#     -h, --no-header
#     -u, --no-current 忽略当前进程的名称
#     -s, --short 短格式
#     -f, --from 展示远程登录的hostname字段
#     -i, --ip-addr 使用ip地址替换掉hostname(远程登录)
#
#
# ===========================================================================================
#
#
# pgrep  查找进程信息
# 
# pgrep [ OPTION ] pattern
# 
# OPTION:
#     -d, --delimiter delimiter 定义输出的分隔符
# 
#     -l, --list-name     输出PID和PNAME
#     -a, --list-full     输出PID和所有的信息
#     -w, --lightweight   输出所有的TID
# 
#     -n, --newest    选择最新启动的进程
#     -o, --oldest    选择最老启动的进程
# 
#     -v, --inverse       匹配的反条件
# 
#     -g, --pgroup pgrp,...  匹配进程的group
#     -G, --group group,...  匹配进程的真实group
#     -P, --parent PPID,...  匹配
#     -s, --session SID,...  匹配
#     -t, --terminal tty,... 匹配
#     -u, --euid, ID,...     匹配
#     -U, --uid, ID,...      匹配
#     -x, --exact            匹配, 完全与命令名称匹配
#     -f, --full             匹配, 使用完整的进程名称来匹配
#     --ns PID               匹配, namespace

fg, bg, jobs

#
#
# ipcs 查询进程间通信状态
#   
# ipcs [ OPTIONs ]
# OPTION:
#     -i, --id id 仅显示由id标识的一个资源元素的完整详细信息, 必须和资源选项一起使用
# 
#     Resource Option:
#         -a, --all  输出所有的三种资源(默认)
#         -m, --shmems 输出共享资源
#         -q, --queues 输出消息队列
#         -s, --semaphores 输出信号量
# 
#     Output format:(只有最后一个选项起作用)
#         -c, --creator 输出创建者和拥有者
#         -l, --limits  输出资源限制
#         -p, --pid     输出PID的创建者和最新操作者
#         -u, --sumary  输出状态统计
#         --human