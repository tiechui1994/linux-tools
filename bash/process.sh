#!/bin/bash

#----------------------------------------------------
# File: process.sh
# Contents: 进程管理常用命令
# Date: 19-03-20
#----------------------------------------------------

#---------------------------------------------------------------------------------------------------
#
# ps
#
# STAT列的含义:
#    R Running, 运行. 正在运行或者在运行队列中等待
#    T 停止. 进程收到信号SIGSTOP, SIGSTP, SIGINT, SIGTOU信号
#    S Interruptible Sleep, 休眠. 在等待某个事件,信号
#    D Disk Sleep, 不可中断的睡眠状态, 一般是进程在等待IO等资源, 并且不可中断. D状态相
# 信很多人在实践中第一次接触就是ps卡住. D状态一般在IO等资源就绪之后就会轮转到R状态, 如果进程处于D状态比较久,这个时候往往
# 是IO出现问题, 解决办法大部分情况是重启机器.
#    I Idle, 空闲状态, 不可中断的睡眠的内核进程. 和 D 状态进程的主要区别是可能实际上不会造成负载升高.
#    Z Zombie, 僵尸进程
#    X 死掉的进程
#
#    < 高优先级
#    N 低优先级
#
#    L 有pages在内存中locked. 用于实时或自定义IO
#
#    s 进程领导者, 其有子进程
#    l 多线程(使用CLONE_THREAD)
#    + 位于前台进程组
#
#   CODE        NORMAL   HEADER
#   cputime     TIME      cumulative CPU time, "[DD-]hh:mm:ss" format.  (alias time).
#
#   drs         DRS       数据驻留集大小,专用于可执行代码以外的物理内存量.
#
#   etime       ELAPSED   自该过程开始以来经过的时间, 格式: [[DD-]hh:]mm:ss.
#
#   fgid        FGID      文件系统访问组id
#
#   fgroup      FGROUP    文件系统访问组
#
#   flag        F         标示
#
#   fname       COMMAND   first 8 bytes of the base name of the process's executable file.  The output in this column may contain spaces.
#
#   fuid        FUID      文件系统访问用户标识.
#
#   fuser       FUSER     文件系统访问用户
#
#   gid         GID       进程有效组id
#
#   group       GROUP     进程有效组
#
#   label       LABEL     security label, most commonly used for SELinux context data.  This is for the Mandatory Access Control ("MAC") found on high-security systems.
#
#   lstart      STARTED   time the command started.  See also bsdstart, start, start_time, and stime.
#
#       lsession    SESSION   displays the login session identifier of a process, if systemd support has been included.
#
#       nice        NI        see ni.(alias ni).
#
#       pending     PENDING   mask of the pending signals. See signal(7).  Signals pending on the process are distinct from signals pending on individual threads.  Use the m option
#                             or the -m option to see both.  According to the width of the field, a 32 or 64 bits mask in hexadecimal format is displayed.  (alias sig).
#
#       pgid        PGID      process group ID or, equivalently, the process ID of the process group leader.  (alias pgrp).
#
#       pgrp        PGRP      see pgid.  (alias pgid).
#
#       pid         PID       进程id
#
#       pmem        %MEM      see %mem.  (alias %mem).
#
#       policy      POL       scheduling class of the process.  (alias class, cls).  Possible values are:
#
#                                      -   not reported
#                                      TS  SCHED_OTHER
#                                      FF  SCHED_FIFO
#                                      RR  SCHED_RR
#                                      B   SCHED_BATCH
#                                      ISO SCHED_ISO
#                                      IDL SCHED_IDLE
#                                      ?   unknown value
#
#       ppid        PPID      parent process ID.
#
#       pri         PRI       priority of the process.  Higher number means lower priority.
#
#       rgid        RGID      real group ID.
#
#       rgroup      RGROUP    real group name.  This will be the textual group ID, if it can be obtained and the field width permits, or a decimal representation otherwise.
#
#       rssize      RSS       see rss.  (alias rss, rsz).
#
#       rtprio      RTPRIO    realtime priority.
#
#       ruid        RUID      real user ID.
#
#       ruser       RUSER     real user ID.  This will be the textual user ID, if it can be obtained and the field width permits, or a decimal representation otherwise.
#
#       s           S         minimal state display (one character).  See section PROCESS STATE CODES for the different values.  See also stat if you want additional information
#                             displayed.  (alias state).
#
#       sched       SCH       scheduling policy of the process.  The policies SCHED_OTHER (SCHED_NORMAL), SCHED_FIFO, SCHED_RR, SCHED_BATCH, SCHED_ISO, and SCHED_IDLE are
#                             respectively displayed as 0, 1, 2, 3, 4, and 5.
#
#       size        SIZE      approximate amount of swap space that would be required if the process were to dirty all writable pages and then be swapped out.  This number is very
#                             rough!
#
#       stackp      STACKP    address of the bottom (start) of stack for the process.
#
#       start       STARTED   time the command started.  If the process was started less than 24 hours ago, the output format is "HH:MM:SS", else it is "  Mmm dd" (where Mmm is a
#                             three-letter month name).  See also lstart, bsdstart, start_time, and stime.
#
#       stat        STAT      multi-character process state.  See section PROCESS STATE CODES for the different values meaning.  See also s and state if you just want the first
#                             character displayed.
#
#       state       S         see s. (alias s).
#
#       sz          SZ        size in physical pages of the core image of the process.  This includes text, data, and stack space.  Device mappings are currently excluded; this is
#                             subject to change.  See vsz and rss.
#
#       tgid        TGID      a number representing the thread group to which a task belongs (alias pid).  It is the process ID of the thread group leader.
#
#       thcount     THCNT     see nlwp.  (alias nlwp).  number of kernel threads owned by the process.
#
#       tid         TID       the unique number representing a dispatchable entity (alias lwp, spid).  This value may also appear as: a process ID (pid); a process group ID (pgrp);
#                             a session ID for the session leader (sid); a thread group ID for the thread group leader (tgid); and a tty process group ID for the process group
#                             leader (tpgid).
#
#       time        TIME      cumulative CPU time, "[DD-]HH:MM:SS" format.  (alias cputime).
#
#       tpgid       TPGID     ID of the foreground process group on the tty (terminal) that the process is connected to, or -1 if the process is not connected to a tty.
#
#       tty         TT        controlling tty (terminal).  (alias tname, tt).
#
#       uid         UID       see euid.  (alias euid).
#
#       unit        UNIT      displays unit which a process belongs to, if systemd support has been included.
#
#       user        USER      see euser.  (alias euser, uname).
#
#
#       vsize       VSZ       see vsz.  (alias vsz).
#
#       vsz         VSZ       virtual memory size of the process in KiB (1024-byte units).  Device mappings are currently excluded; this is subject to change.  (alias vsize).
#
#---------------------------------------------------------------------------------------------------


#---------------------------------------------------------------------------------------------------
#
# top
#
#---------------------------------------------------------------------------------------------------


#---------------------------------------------------------------------------------------------------
#
# nice
#
#---------------------------------------------------------------------------------------------------


#---------------------------------------------------------------------------------------------------
#
# renice
#
#---------------------------------------------------------------------------------------------------


#---------------------------------------------------------------------------------------------------
#
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
#---------------------------------------------------------------------------------------------------


#---------------------------------------------------------------------------------------------------
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
#---------------------------------------------------------------------------------------------------


#---------------------------------------------------------------------------------------------------
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
#---------------------------------------------------------------------------------------------------


#---------------------------------------------------------------------------------------------------
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
#---------------------------------------------------------------------------------------------------


#---------------------------------------------------------------------------------------------------
#
# fg, bg, jobs
#---------------------------------------------------------------------------------------------------


#---------------------------------------------------------------------------------------------------
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
#
#---------------------------------------------------------------------------------------------------