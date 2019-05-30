#!/bin/bash

#----------------------------------------------------
# File: upstart-service
# Contents: Upstart Service Config
# Date: 19-5-30
#----------------------------------------------------


#---------------------------------------------------------------------------------------------------
# Upstart Event State:
#
# waiting: initial state.
# starting: job is about to start.
# pre-start: running pre-start section.
# spawnded: about to run script or exec section.
# post-start: running post-start section.
# running: interim state set after post-start section processed denoting job is running(But it may have no associated PID!)
# pre-stop: running pre-stop section.
# stopping: interim(temp) state set after pre-stop section processed.
# killed: job is about to be stopped.
# post-stop: running post-stop section.
#
#---------------------------------------------------------------------------------------------------


#---------------------------------------------------------------------------------------------------
# Upstart Job Config
#
# 任务支持的语法关键字
#
# - Process Definition:
# exec, script, pre-start, post-start, pre-stop, post-stop
#
# - Event Definition:
# start on, stop on, manual
#
# - Job Environment:
# env, export
#
# - Services, Tasks and Respawning:
# normal exit, respawn limit, task
#
# - Instances:
# instance
#
# - Documentation:
# description, author, version, emits, usage
#
# - Process Environment:
# console none, console log, console output, console owner, nice, chrooot, chdir, oom score, setuid,
# setgid, umask
#
# - Process Control:
# except fork, except daemon, except stop, kill signal, kill timeout
#
# - 过期关键字:
# service, daemon, pid
#
#---------------------------------------------------------------------------------------------------


#---------------------------------------------------------------------------------------------------
# 语法介绍
#
# exec: 执行命令, 在script块或者单独使用
# script: 脚本块, 包括运行脚本
# script
#   exec printf "hello"
# end script
#
# pre-start: 脚本块, 在主脚本之前执行的脚本
# pre-start script
#   exec printf "pre-start"
# end script
#
# post-start: 脚本块, 在主脚本之后, running状态前执行
# post-start script
#   exec printf "post-start"
# end script
#
# pre-stop: 脚本块, 在执行stop之前执行
# pre-stop script
#   exec printf "pre-stop"
# end script
#
# post-stop: 脚本块, 在主脚本被杀死之后运行
# post-stop script
#   exec printf "post-stop"
# end script
#
#===================================================================================================
# start on: 事件, 启动任务.
# start on startup // 系统启动
#
# stop on: 事件, 停止任务
# stop on shutdown // 系统停止
#
# respawn: 命令, 设置服务异常停止后自动重启
# respawn
#
# respawn limit: 命令, 设置服务异常停止后启动次数及时间间隔
# respawn limit 15 3  // 服务异常, 每隔3秒启动一次, 最多启动15次(不太起作用)
#
# instance: 定义实例的名字, 可以通过命令给任务传递参数
# instance $TTY
# exec /sbin/gettty -8 38300 $TTY
#
# # 传递参数
# start mytest $TTY=tty1
#
#===================================================================================================
# kill timeout: 命令, 在到达指定的事件后, 停止应用
# kill timeout 5
# 注: kill timeout命令是正常退出, 不会被respawn重启
#
#
# console: 命令, 控制输出, 支持4种操作, log|output|owner|none
#
# console log, 将standard input连接到/dev/null,  standard output和standard err 连接到 /var/log/upstart/$JOB.log (
# System Job), $HOME/.cache/upstart (Session Job)
#
# console none, 将 standard input, standard output, standard err 连接到 /dev/null
#
# console output, 将 standard input, standard output, standard err 连接到 console device
#
# console owner, 类似 console output
#
# console output
# script
#   logger "Hello";
# end script
# 注: logger 是系统的日志命令
#
#
# emits <value>
# 指定Job配置文件生成的事件(直接或间接通过子进程). 对于每个发出的事件, 可以多次指定此section. 此section也可以使用以下
# shell通配符来简化规范:
# - "*"
# - "?"
# - "[" 和 "]"
#
# emits *-devcie-*
# emits foo-event bar-event hello-event
#
#
# expect
# Upstart将追踪它认为属于Job的进程ID. 如果Job使用了instance section,  则Upstart将跟踪该Job的每个唯一实例的PID.
#
# 如果未指定expect section, Upstart将跟踪它在exec或script section中执行的第一条命令的PID. 但是,大多数Unix服务都
# 是daemonize, 这意味着它们将创建一个新进程(使用fork), 这是初始进程的子进程. 通常, 服务将 "double fork" 以确保它们
# 与初始过程无任何关联. (注意, 没有服务会fork 2次以上, 这样做没有额外的好处)
#
# 在这种情况下, Upstart必须有一种方法来跟踪它, 所以可以使用expect fork,或者 expect daemon, 从而允许Upstart使用
# ptrace来"count forks".
#
#===================================================================================================
# env KEY[=VALUE]: 变量, 设置任务的环境变量
#
# umask: 变量, 设置任务的文件权限的掩码
#
# nice: 变量, 设置任务调度的优先级
#
# limit: 变量,设置任务的资源限制
# limit nproc 10 10
#
# chroot: 变量, 设置任务的根目录
#
# chdir: 变量, 设置任务的工作目录
#
#---------------------------------------------------------------------------------------------------


#---------------------------------------------------------------------------------------------------
# Upstart 控制命令
#
# initctl check-config  检测无法访问的job/event
# initctl show-config 查看job的emits, start on, stop on的细节
# initctl emit 手动emit一个事件
# initctl list 列出已知的job
# initctl reload-configuration 重新加载配置
#
# initctl usage job参数
# initctl reload 发送HUP Signal给job
# initctl restart 重启job
# initctl start 启动job
# initctl status  查询job状态
# initctl stop  停止job
#
#---------------------------------------------------------------------------------------------------