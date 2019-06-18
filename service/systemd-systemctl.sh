#!/bin/bash

#----------------------------------------------------
# File: systemd-systemctl.sh
# Contents: systemctl
# Date: 6/18/19
#----------------------------------------------------


#---------------------------------------------------------------------------------------------------
# systemctl
# systemd下服务的管理和控制工具.
#
# OPTIONS:
#
#   -t, --type=
#   unit类型列表(使用逗号分割), 例如service, socket等.
#
#   --state=
#   Unit的LOAD,ACTIVE,SUB的状态列表(使用逗号分割), state包括: loaded, active, failed, plugged, running,
#   mounted, waiting, exited, listening
#
#   -r, --recursive
#   当列出unit时, 还会显示本地容器的unit. 本地容器的unit将以容器名称为前缀, 用单个冒号字符(":")分隔.
#
#   --reverse
#   显示unit反向依赖的units. 例如, 依赖的类型WantedBy=, RequiredBy=, PartOf=, BoundBy= .
#
#   -s, --signal=
#   与kill一起使用时, 选择要发送到所选进程的信号. 默认为SIGTERM.
#
#   -f, --force
#   与enable一起使用时, 覆盖任何有冲突的符号链接.
#
#   当与halt,poweroff, restart或kexec一起使用时, 执行所选操作而不关闭所有单元. 但是, 所有进程都将被强制终止, 并且
#   所有文件系统都是以只读方式卸载或重新装入的. 因此, 这是一个要求立即重启的但相对安全的选择.  如果为这些操作指定了两次
#   --force, 它们将立即执行, 而不会终止任何进程或卸载任何文件系统. 警告: 使用任何这些操作指定--force两次可能会导致数
#   据丢失.
#
#   --message=
#   与halt, poweroff, reboot或kexec一起使用时, 设置一条说明操作原因的简短消息. 该消息将与默认关闭消息记录在一起.
#
#   --now
#   与enable一起使用时, unit将会启动. 与disable或mask一起使用时, unit也将会停止.  仅在相应的enable或disable操
#   作成功时才执行启动或停止操作.
#
#   --root=
#   与enable/disbale/is-enabled(以及相关命令)一起使用时, 指定查找unit文件时使用的"备用根路径".
#
#   --runtime
#   与enable, disbale, edit(以及相关命令)一起使用时, 仅临时进行更改, 在下次重新启动时丢失修改的内容. 这将导致不会在
#   /etc的子目录中进行更改, 而是在/run中进行更改, 但具有即时效果, 但是, 由于后者在重新引导时丢失修改的内容, 因此相应的
#   更改也会丢失. 同样, 与set-property一起使用时, 只能暂时进行更改, 在下次重新引导时丢失
#
#
# COMMANDS:
#
# Unit Commands:
#
#   list-units [PATTERN]
#   list-sockets [PATTERN]
#   list-timers [PATTERNS]
#
#   start PATTERN
#   stop  PATTERN
#   restart PATTERN
#
#   reload PATTERN
#   要求命令行中列出的所有单元重新加载其配置. 注意, 这将重新加载特定于服务的配置, 而不是systemd的单元配置文件. 如果希望
#   systemd重新加载单元的配置文件, 使用daemon-reload命令. 例如, 对于nginx执行reload操作, 将会重新加载nginx.conf
#   而不是nginx.service单元文件.
#
#   try-restart PATTERN
#   尝试重启
#
#   reload-or-restart PATTERN
#   try-reload-or-restart PATTERN
#
#   isolate NAME
#   启动命令行中指定的单元及其依赖项, 并停止所有其他单元. 如果给出没有扩展名的单位名称, 则将假定扩展名为".target".
#   这类似于在传统的init系统中更改运行级别. isolate命令将立即停止新单元中未启用的进程, 可能包括您当前使用的图形环境或终
#   端.
#
#   kill PATTERN
#
#   is-active PATTERN
#   is-failed PATTERN
#
#   status [PATTERN|PID]
#
#   set-property NAME VALUE
#
#   list-dependencies [NAME]
#   
#
#---------------------------------------------------------------------------------------------------


