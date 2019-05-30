#!/bin/bash

#----------------------------------------------------
# File: upstart.sh
# Contents: upstart.sh
# Date: 19-5-26
#----------------------------------------------------

#---------------------------------------------------------------------------------------------------
# Upstart
#
# Upstart 基于事件机制, 比如U盘插入USB接口后, udev得到内核通知, 发现该设备, 这就是一个新的事件. Upstart在感知该事件
# 之后触发相应的等待任务, 比如处理/etc/fstab中存在的挂载点. 采用这种事件驱动从模式, Upstart完美地解决了即插即用设备带
# 来的新的问题.
#
# 此外, 采用事件驱动机制带来了其他有益的变化, 比如加快的系统启动时间. Sysvinit 运行是同步阻塞的. 一个脚本运行的时候,
# 后续脚本必须等待. 这意味着所有初始化步骤都是串行执行的, 而实际上很多服务彼此并不相关, 完全可以并行启动, 从而减小系统的
# 启动时间.
#
# Chrome OS 使用的是Upstart
#
# Debian7 使用的是 Upstart; Debian8 开始使用 Systemd
#
# Ubuntu 10.04, 12.04, 14.04 使用的是Upstart; Ubuntu 14.10开始使用Systemd
#
# Fedora9 开始使用Upstart; Fedora15 开始使用Systemd
#
# RHEL6 使用Upstart; RHEL7 开始使用Systemd
#
# openSUSE12.1 开始使用Systemd.
#
#
#
# Upstart的特点
#
# Upstart解决了Sysvinit的缺点. 采用事件驱动模型, Upstart可以:
# - 更快地启动系统
# - 当硬件被发现时动态启动服务
# - 硬件被拔除时动态停止服务
#
#---------------------------------------------------------------------------------------------------


#---------------------------------------------------------------------------------------------------
# Upstart概念和术语
#
# Upstart主要的概念是job和event. Job是一个工作单元, 用来完成一件工作, 比如启动一个后台服务, 或者运行一个配置命令. 每
# 个Job都等待一个或多个事件, 一旦事件发生, Upstart就会触发该Job完成相应的工作.
#
#
# Job
#
# Job就是一个工作的单元, 一个任务或者一个服务. 可以理解为Sysvinit中的一个服务脚本. 有三种类型的Job:
# - task job
# - service job
# - abstract job
#
# task job 代表在一定时间内会执行完毕的任务, 比如删除一个文件;
#
# service job 代表后台服务进程, 比如nginx. 这里进程一般不会退出, 一旦开始运行就成为一个后台进程, 由init进程管理, 如
# 果这类进程退出, 由init进程重新启动, 它们只能由init进程发送信号停止. 它们的停止一般也是由于所依赖的停止事件而触发的,不
# 过Upstart也提供命令行工具, 让管理人员手动停止某个服务.
#
# abstract job 仅由Upstart内部使用,仅对理解Upstart内部机理有所帮助.
#
#
# Job 生命周期
#
# Upstart为每个工作都维护了一个生命周期. 一般来说, 工作有开始, 运行和结束这几种状态. 为了更精细地描述工作的变化,Upstart
# 还引入了一些其他的状态. 比如, 开始就有开始之前(pre-start), 即将开始(starting) 和 已经开始(started)几种不同的状态,
# 这样可以更加精确地描述工作的当前状态.
#
# 工作从某种初始状态开始, 逐渐变化, 或许要经历几种不同的状态, 最终进入另外一种状态, 形成一个状态机. 在这个过程中, 当工作
# 的状态即将发生变化的时候, init进程会发出相应的事件(event)
#
# 状态         说明
# waiting     初始化状态
# starting    Job即将开始
# pre-start   执行pre-start段, 即任务开始之前应该完成的工作
# spawned     准备执行script或者exec段
# post-start  执行post-start动作
# running     interim(临时的) state set after 'post-start' section processed denoting(表示) job is running (But it may have no associated PID!)
# pre-stop    执行pre-stop段
# stopping    interim(临时的) state set after 'pre-stop' section processed
# killed      任务即将被停止
# post-stop   执行post-stop段
#
#
#           waiting                                            pre-stop
# kllied -> post-stop -> starting -> pre-start -> spawned -> post-started -> running -> stopping
#    \                                                                                     |
#     \____________________________________________________________________________________|
#
#
# starting
# pre-start
# spawned     --> stopping ---> killed --> post-stop --> waitting
# post-start
# running
# pre-stop
#
#
# 其中有四个状态会引起init进程发送相应的事件, 表明该工作的相应变化:
# - starting
# - started
# - stopping
# - stopped
#
#
#
# Event
#
# 事件Event下Upstart中以通知消息的形式存在. 一旦某个事件发生了, Upstart会向整个系统发送一个消息. 没有任何手段可以阻止事件
# 被Upstart的其他部分知晓, 即, 事件一旦发生, 整个Upstart系统中所有Job都会得到通知.
#
# Event可以分为三类: signal, methods, hooks
#
# - signal: 事件是非阻塞的, 异步的. 发送一个信号之后控制权立即返回.
#
# - method: 事件是阻塞的, 同步的.
#
# - hooks: 事件是阻塞的, 同步的, 介于signal和method之间, 调用发出hooks事件的进程必须等待事件完成才可以得到控制权, 但不
# 检查事件是否成功.
#
#
#
# Job配置文件
#
# 任何一个Job都是由一个Job配置文件定义的. 这个文件是一个文本文件, 包含一个或多个小节(section). 每个小节是一个完整的定义模
# 块,定义了Job的一个方面. Job配置文件存在在/etc/init下面, 是以.conf作为文件后缀的文件.
#
#---------------------------------------------------------------------------------------------------