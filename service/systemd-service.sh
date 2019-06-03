#!/bin/bash

#----------------------------------------------------
# File: ${NAME}
# Contents: root
# Date: 19-6-1
#----------------------------------------------------

#---------------------------------------------------------------------------------------------------
# Linux内核为用户空间提供了许多不同的通信方式.
#
# /sys 用于向用户暴露内核设备,驱动程序和其他内核信息
# /proc 用于向用户暴露内核设置, 进程和其他内核信息
# /dev 用于向用户暴露内核的设备节点
# /run 本地用户空间的socket和files
# /tmp 本地用户空间临时文件系统对象
#
# /sys/fs/cgroup 将内核控制组层次结构暴露给用户
# /sys/kernel/security, /sys/kernel/debug, /sys/kernel/config 将特殊的内核对象暴露给用户
# /sys/fs/selinux 将SELinux安全数据暴露给用户
# /sys/fs/fuse/connections 用于将内核FUSE连接暴露给用户
# /sys/firmware?efi/efivars 用于将固件变量暴露给用户
#
# /dev/shm 用户空间的共享内存对象
# /dev/pts 将内核的伪TTY设备节点暴露给用户
# /dev/mqueue 用于将mqueue IPC对象暴露给用户
# /dev/hugepages 用户空间的API, 用于分配"巨大"内存页
#
# /proc/sys/fs/binfmt_misc 用于在内核中注册二进制格式
#
#---------------------------------------------------------------------------------------------------

#---------------------------------------------------------------------------------------------------
# 单元的概念
# 系统初始化需要做是事情非常多. 需要启动后台服务, 比如启动sshd服务; 需要做配置工作, 比如挂载文件系统. 这个过程中的每一步
# 都被Systemd抽象为一个配置单元, 即Unit. 可以认为一个服务是一个配置单元; 一个挂载点是一个配置单元; 一个交换分区的配置
# 是一个配置单元; 等等. Systemd将配置单元归纳为以下不同的类型.
#
# - service: 代表一个后台进程, 比如mysqld. 这是最常用的一类.
#
# - socket: 此类配置单元封装系统和互联网中的一个套接字. 当下, Systemd支持流式,数据报和连续包的AF_INET, AF_INET6,
# AF_UNIX socket. 每一个套接字配置单元都有一个相应的服务配置单元. 相应的服务在第一个"连接"进入套接字时就会启动. 例如,
# nscd.socket在有新的连接后便启动nscd.service.
#
# - device: 此类配置单元封装一个存在于Linux设备树中的设备. 每一个使用udev规则标记的设备都将会在Systemd中作为一个设备
# 配置单元出现.
#
# - mount: 此类配置单元封装文件系统结构层次中的一个挂载点. Systemd将对这个挂载点进行监控和管理. 比如可以在启动时自动将
# 其挂载; 可以在某些条件下自动卸载. Systemd会将/etc/fstab中的条目都转换为挂载点, 并在开机时处理.
#
# - automount: 此类配置单元封装系统结构层次中的一个自挂载点. 每一个自挂载配置单元对应一个挂载配置单元, 当该自动挂载点
# 被访问时, Systemd执行挂载点中定义的挂载行为.
#
# - swap: 和挂载配置单元类似, 交换配置单元用来管理交换分区. 用户可以用交换配置单元来定义系统中的交换分区, 可以让这些交
# 换分区在启动时被激活.
#
# - target: 此类配置单元为其他配置单元进行逻辑分组. 它们本身实际上并不做什么, 只是引用其他配置单元而已. 这样便可以对配
# 置单元做一个统一的控制. 这样就可以实现大家都已经非常熟悉的运行级别概念. 比如想让系统进入图形化模式, 需要运行许多服务和
# 配置命令, 这些操作由一个个的配置单元表示, 将所有这些配置单元组合为一个目标(target), 就表示需要将这些配置单元全部执行
# 一遍便进入target所代表的系统运行状态. 例如multi-user.target 相当于SysV系统中运行级别5
#
# - timer: 定时器配置单元用来定时触发用户定义的操作. 这类配置单元取代了atd, crond等传统的定时服务.
#
# - snapshot: 与target配置单元类似, 快照的一组配置单元. 它保存了系统当前的运行状态.
#
#===================================================================================================
# Systemd 目录
# Unit文件按照Systemd约定, 应该被放置指定的三个系统目录之一中. 这三个目录是有优先级的, 如下所示, 越靠上的优先级越高. 因此,
# 在三个目录中有同名文件的时候, 只有优先级最高的目录里的那个文件会被使用.
#
# - Load path when running in system mode (--system)
#
# /etc/systemd/system 系统或用户自定义的配置文件
# /run/systemd/system 软件运行时生成的配置文件
# /usr/lib/systemd/system 系统或第三方软件安装时添加的配置文件. CentOS7, Unit文件指向此目录; Ubuntu16, 文件被移动
# 到了/lib/systemd/system下.
#
# Systemd默认从目录/etc/systemd/system读取配置文件. 但是, 里面存放的大部分文件都是符号链接, 指向目录真正的配置文件存放
# 的目录/usr/lib/systemd/system (/lib/systemd/system)
#
#
# - Load path when runing in user mode (--user)
#
# $XDG_CONFIG_HOME/systemd/user  用户配置(只有$XDG_CONFIG_HOME设置生效)
# $HOME/.config/systemd/user     用户配置(只有$XDG_CONFIG_HOME未设置生效)
# /etc/systemd/user              本地配置
# $XDG_RUNTIME_DIR/systemd/user  运行中的Unit(只有$XDG_RUNTIME_DIR设置生效)
# /run/systemd/user              运行中的Unit
# $XDG_DATA_HOME/systemd/user     包的Unit(只有$XDG_DATA_HOME设置生效)
# $HOME/.local/share/systemd/user 包的Unit(只有$XDG_DATA_HOME未设置生效)
# /usr/lib/systemd/user           包的Unit
#
#===================================================================================================
# Unit 和 Target
#
# Unit是Systemd管理系统资源的基本单位, 可以认为每个系统资源就是一个Unit, 并使用一个Unit文件定义. 在Unit文件中需要包含相
# 应服务的描述, 属性以及需要启动的命令.
#
# Target是Systemd中用于指定系统资源启动组的方式, 相当于SysV-init当中的运行级别.
#
#
# Unit文件结构
# 案例:
# [Unit]
# Description=Hello World
# After=docker.service
# Requires=docker.service
#
# [Service]
# TimeoutStartSec=0
# ExecStartPre=-/usr/bin/docker kill busybox1
# ExecStartPre=-/usr/bin/docker rm busybox1
# ExecStartPre=-/usr/bin/docker pull busybox
# ExecStart=/usr/bin/docker run --name busybox1 busybox /bin/sh -c "while true; do echo Hello World; sleep 1; done"
# ExecStop=/usr/bin/docker stop busybox1
# ExecStopPost=/usr/bin/docker rm busybox1
#
# [Install]
# WantedBy=multi-user.target
#
# Systemd服务的Unit文件可以分为三个配置区段:
# - Unit和Install, 所有Unit文件通用, 用于配置服务的描述, 依赖和随系统启动的方式
# - Service, 服务Service类型的Unit文件(后缀.service)特有的, 用于定义服务的具体管理和操作方法
#
#
# Unit选项
#
# - Description: 描述Unit文件的信息
#
# - Documentation: 指定服务的文档, 可以是一个或多个文档的URL路径
#
# - Requires: 依赖的其他Unit列表, 列在其中的Unit模板会在这个服务启动时的同时被启动. 并且, 如果其中任意一个服务启动失败,
# 这个服务也会被终止.
#
# - Wants: 与Requires相似, 但只是在被配置的这个Unit启动时,触发启动列出的每个Unit模板, 而不考虑这些模板启动成功与否
#
# - After: 与Requires相似, 但是在列出的所有模板全部启动完成以后, 才启动当前的服务.
#
# - Before: 与After相反, 在启动列出的任意一个模板的时候, 首先需要确保当前的服务已经启动
#
# - BindsTo: 与Requires相似, 失败时失败, 成功时成功, 但是在这些模板中有任意一个出现意外结束或重启时, 这个服务也会跟着
# 终止或重启.
#
# - PartOf: 一个Binds To作用的子集, 仅在列出的任务模板失败或重启时,终止或重启当前服务, 而不会随列出模板的启动而启动.
#
# - OnFailure: 当这个模板启动失败时, 会自动启动列出的每个模板
#
# - Conflicts: 与这个模板有冲突的模板, 如果列出的模板中有已经运行的, 这个服务就不能启动, 反之亦然.
#---------------------------------------------------------------------------------------------------

#---------------------------------------------------------------------------------------------------
# Service Template
#
# 隐式依赖关系
# - 使用 "Type=dbus" 的Service会自动获取dbus.socket上 "Requires=xxx" 和 "After=xxx" 类型的依赖关系.
# - 套接字激活Service在激活 ".socket" 单元后根据 "After=xxx" 依赖进行自动排序. Service还通过 "Wants=xxx" 和
# "After=xxx" 依赖项拉取在
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#---------------------------------------------------------------------------------------------------