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
# Upstart job Config
#
# 任务支持的语法关键字
#
# - Process Definition:
# exec, script, pre-start, post-start, pre-stop, post-stop
#
# - Event Definition:
# start on, stop on, manual
#
# - job Environment:
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
# start on EVENT [[KEY=]VALUE] ... [and|or...]
# 每个事件EVENT都由其名称给出. 使用运算符"and","or"运行多个事件. 并且可以使用括号执行复杂表达式.
# 还可以通过知道KEY和预期的VALUE来匹配事件中包含的环境变量.
#
# VALUE 可能包含通配符. 并且可能会扩展使用env section定义的任何变量的值.
#
# 在KEY和VALUE之间使用 "!=" 表示否定.
# 注: 如果job已经启动并且不是instance job. 如果启动条件为true(再次), 则不会采取进一步操作.
#
# start on startup // 系统启动
# start on foo or bar
#
# 如果没有通过KEY指定环境变量来限制匹配, 则条件将匹配指定事件的所有实例.
#
# - normal start
# start on (local-filesystems and net-device-up IFACE!=lo)
# start on runlevel [2345]
#
# 是否使用更通用的"runlevel" 或 更明确的local-filesystems和 net-device-up 事件的差异应该以job行为为指导.
# 如果service没有使用具体的网络接口(例如,它绑定到0.0.0.0, 或使用setsockopt SO_FREEBIND), 那么runlevel是更好的选择.
# 因为这样service将提前start并且可以使用并行的方式启动.
#
# 但是, 如果service要求使用非环回网卡(即, 它没有广播功能就无法启动), 那么就需要明确指定条件.
#
# - depends on another service
# start on started other-service
#
# - start must precede(优先) another service
# start on starting other-service
#
# example: memcached.conf
# start on starting apache2
# stop on stopping apache2
# exec /usr/sbin/memcached
#
#
# stop on: 事件, 停止任务, 与 start on 类似
# stop on shutdown // 系统停止
#
#
# task
# 从概念说, task只是一项短暂的job.
# 如果没有 task 关键字, 一旦job是started状态, job启动的事件都将异步执行, 即, 当job 触发了 starting event之后, 执
# 行 pre-start脚本, 开始执行job的 script/exec 和 post-start, 并且触发 started event.
#
# 使用task关键字, job的 starting event 到 started event 之间是阻塞执行的.
#
#===================================================================================================
# respawn
# 如果没有此section, 无论job的主进程以何种方式退出, job的主进程的状态都会变为stop/waiting状态.
# 当使用此section, 当主 script/exec 退出的时候, 如果没有将job的状态改为stop, 当前的job将会重新启动. 这包括执行 pre-start
# post-start, post-stop. 注意: 不会执行 pre-stop
#
#
# respawn limit COUNT INTERVAL | unlimited
# respawn limit与respawn不同, 设置 respawn limit 并不意味着设置了 respawn.
# respawn的目标是limit. 如果在 INTERVAL 秒内重启 job 超过 COUNT 次, 则会认为该job存在更深层次的问题, 并将其停止掉.
# 默认的 COUNT 是10, 默认是 INTERVAL 是5
#
# respawn limit 15 3  // 服务异常, 每隔3秒启动一次, 最多启动15次(不太起作用)
#
#
# instance: 定义实例的名字, 可以通过命令给任务传递参数
# instance $TTY
# exec /sbin/gettty -8 38300 $TTY
#
# # 传递参数
# start mytest $TTY=tty1
#
#===================================================================================================
# kill timeout: 命令, Upstart在终止进程之前将等待的秒数. 默认值为5秒.
# kill timeout 5
# 注: kill timeout命令是正常退出, 不会被respawn重启
#
# kill signal
# 设置stopping signal, 默认是SIGTERM. 当一个job的主进程接收到该信号后会停止运行的job
#
# kill signal INT
# kill signal SIGINT
#
#
# console: 命令, 控制输出, 支持4种操作, log|output|owner|none
#
# console log, 将standard input连接到/dev/null,  standard output和standard err 连接到 /var/log/upstart/$job.log (
# System job), $HOME/.cache/upstart (Session job)
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
# 指定job配置文件生成的事件(直接或间接通过子进程). 对于每个发出的事件, 可以多次指定此section. 此section也可以使用以下
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
# Upstart将追踪它认为属于job的进程ID. 如果job使用了instance section,  则Upstart将跟踪该job的每个唯一实例的PID.
#
# 如果未指定expect section, Upstart将跟踪它在exec或script section中执行的第一条命令的PID. 但是,大多数Unix服务都
# 是daemonize, 这意味着它们将创建一个新进程(使用fork), 这是初始进程的子进程. 通常, 服务将 "double fork" 以确保它们
# 与初始过程无任何关联. (注意, 没有服务会fork 2次以上, 这样做没有额外的好处)
#
# 在这种情况下, Upstart必须有一种方法来跟踪它, 所以可以使用expect fork,或者 expect daemon, 从而允许Upstart使用
# ptrace来"count forks".
#
# export fork, 执行的进程只调用一次fork.  一些守护进程在接收到SIGHUP信号时fork出一个新副本, 这意味着当使用Upstart的
# reload命令时, Upstart将失去对该守护进程的跟踪. 在这种情况下，expect fork不能使用.
#
# export daemon, 执行的进程只调用两次fork.
#
# export stop, job的主进程会挂起SIGSTOP信号以表明自己已准备就绪(spawned). init接收到SIGSTOP信号后:
# - 立即发送 SIGCONT 信号给该进程, job主进程继续执行.
# - 执行 job 的 post-start script(如果有)
#
# 只有这样, Upstart才会确认当前的job处于running状态.
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
# manual
# 告知 Upstart 忽略当前 job 的 start on/stop on section. 它有助于在系统上保持job的逻辑和功能, 而不会在启动时自动
# 启动.
#
# normal exit
# 用于改变 Upstart 对 "normal" 退出状态。 通常, 进程以状态0(zero)退出以表示成功, 而非零以表示失败.
# 如果应用程序退出状态13并且希望Upstart将其视为正常(成功)退出, 那么可以这样指定:
# normal exit 0 13
#
# 也可以使用Signal.
# normal exit 0 13 SIGUSR1 SIGWINCH
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