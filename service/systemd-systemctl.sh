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
#   在运行时设置指定的单元属性, 以支持此属性. 这允许在运行时更改配置参数属性, 例如资源控制设置. 并非所有属性都可以在运行
#   时更改, 但许多资源控制设置(主要是systemd.resource-control中的设置)可能. 更改将立即应用, 并存储在磁盘上以供将来
#   引导, 除非使用--runtime参数, 在这种情况下, 设置仅适用运行时. 属性赋值的语法和unit文件中赋值的语法相同.
#
#   Example: systemctl set-property foobar.service CPUShares=777
#
#   如果指定的单元处于非活动状态, 则更改将仅存储在磁盘上, 它们将会在未来的启动中生效.
#   注意: 此命令允许同时更改多个属性, 这比单独设置它们更可取. 与单元文件配置设置一样, 将空列表分配给列表参数将重置列表.
#
#   reset-failed [PATTERN]
#   重置指定unit的"failed"状态, 或者如果没有传递unit名称, 则重置所有unit的状态. 当某个unit因为某种方式失败时(即进程
#   退出时出现非零错误代码,异常终止或超时)它将自动进入"failed"状态, 并记录其退出代码和状态, 以供管理员自省直至服务使用
#   此命令重新启动或重置.
#
#   list-dependencies [NAME]
#   显示指定unit required 和 wanted by的unit. 这将递归地列出Requires=, Requisite=, ConsistsOf=, Wants=,
#   BindsTo= 之后的unit. 如果未指定unit, 则隐含使用default.target.
#
#   默认情况下, 仅递归扩展目标unit. 当--all传递时, 所有其他单元也会递归展开.
#
#
# Unit File Commands:
#
#   list-unit-files [PATTERN]
#   列出已安装的unit文件及其启用状态(由is-enabled报告). 如果指定了一个或多个PATTERN, 则仅显示匹配的文件名(仅路径的最
#   后一个组件)
#
#
#   enable NAME...
#   enable一个或多个unit文件或unit文件实例. 这将创建在unit文件的"[Install]"部分中编码的多个符号链接.创建符号链接后,
#   将重新加载systemd配置(以与daemon-reload相同的方式), 以确保更改立即应用到account. 如果需要,可以--now参数,或者
#   必须为该unit调用另外的启动命令. 注意, 在实例启用的情况下, 在安装位置创建名称与实例相同的符号链接, 但它们都指向相同
#   的模板单元文件.
#
#   不应将启用unit与启动(激活[activating])单元混淆. 启用和启动单元是正交的: 可以启用单元而无需启动和启动单元而不启用.
#   启用只需将设备挂钩到各种指定的位置(例如,在启动时或插入特定类型的硬件时自动启动设备). 启动实际上会生成守护进程(如果是
#   服务单元), 或者绑定套接字(如果是套接字单元),依此类推.
#
#   在屏蔽单元上使用启用会导致错误.
#
#
#   disable NAME...
#   类似enable, 做的事情是删除链接文件.
#
#
#   reenable NAME...
#   reenable一个或多个单元文件, 如命令行中所指定. 这是disbale和enable的组合, 用于将单元启用的符号链接重置为单元文件
#   的"[Install]"部分中配置的默认值.
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


