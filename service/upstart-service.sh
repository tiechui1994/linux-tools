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
#
# 语法介绍
#
# exec: 执行命令, 在script块当中使用
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
#
# kill timeout: 命令, 在到达指定的事件后, 停止应用
# kill timeout 5
# 注: kill timeout命令是正常退出, 不会被respawn重启
#
#
# console: 命令, 控制输出, 支持4种操作, logged|output|owner|none
#
# env: 变量, 设置任务的环境变量
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