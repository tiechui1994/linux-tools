#!/bin/bash

#----------------------------------------------------
# File: systemd.sh
# Contents: systemd架构
# Date: 18-11-9
#----------------------------------------------------

# systemd架构:
#
#+---------------------------------------------------------------------------------------------------------------------+
#| systemd Utilities                                                                                                   |
#| +===========+ +===========+ +===========+ +===========+ +===========+ +===========+ +===========+ +===========+     |
#| | systemctl | |journalctl | |  notify   | |  analyze  | |   cgls    | |   cgtop   | |  loginctl | |   nspawn  |     |
#| +===========+ +===========+ +===========+ +===========+ +===========+ +===========+ +===========+ +===========+     |
#+---------------------------------------------------------------------------------------------------------------------+
#| +-------------------------+ +-------------------------------------------------------------------------------------+ |
#| | systemd Daemons         | | systemd Targets                                                                     | |
#| | +=======+               | | +========+ +======+ +--------------------+ +----------------+ +-------------------+ | |
#| | |systemd|               | | |bootmode| |basic | |     multi-user     | |    graphical   | |  user-session     | | |
#| | +=======+               | | +========+ +======+ | +====+ +=========+ | | +============+ | | +===============+ | | |
#| | +========+ +========+   | | +========+ +======+ | |dbus| |telephony| | | |user-session| | | |display service| | | |
#| | |journald| |networkd|   | | |shutdown| |reboot| | +====+ +=========+ | | +============+ | | +===============+ | | |
#| | +========+ +========+   | | +========+ +======+ | +====+ +=========+ | +----------------+ | +===============+ | | |
#| | +======+ +============+ | |                     | |dlog| |  logind | |                    | | tizen service | | | |
#| | |logind| |user session| | |                     | +====+ +=========+ |                    | +===============+ | | |
#| | +======+ +============+ | |                     +--------------------+                    +-------------------+ | |
#| +-------------------------+ +-------------------------------------------------------------------------------------+ |
#+---------------------------------------------------------------------------------------------------------------------+
#| systemd Core                                                                                                        |
#| +=======+ +--------------------------------------+ +-----------------------+ +=========+ +=========+                |
#| |manager| |             unit                     | |         login         | |namespace| |   log   |                |
#| +=======+ | +========+ +=====+ +======+ +======+ | | +=========+ +=======+ | +=========+ +=========+                |
#| +=======+ | |service | |timer| |mount | |target| | | |multiseat| |inhibit| | +=========+ +=========+                |
#| |systemd| | +========+ +=====+ +======+ +======+ | | +=========+ +=======+ | |  cgroup | |   dbus  |                |
#| +=======+ | +========+ +=====+ +======+ +======+ | | +=========+ +=======+ | +=========+ +=========+                |
#|           | |snapshot| |path | |socket| | swap | | | | session | |  pam  | |                                        |
#|           | +========+ +=====+ +======+ +======+ | | +=========+ +=======+ |                                        |
#|           +--------------------------------------+ +-----------------------+                                        |
#+---------------------------------------------------------------------------------------------------------------------+
#| systemd Libraries                                                                                                   |
#| +=============+ +=============+ +=============+ +=============+ +=============+ +=============+ +=============+     |
#| |   dbus-1    | |    libpam   | |   libcap    | |libcryptsetup| | tcpwrapper  | |  libaudit   | |  libnotify  |     |
#| +=============+ +=============+ +=============+ +=============+ +=============+ +=============+ +=============+     |
#+---------------------------------------------------------------------------------------------------------------------+
#|                               +================+    +================+    +================+                        |
#| Linux Kernel                  |    cgroups     |    |     autofs     |    |     kdbus      |                        |
#|                               +================+    +================+    +================+                        |
#+---------------------------------------------------------------------------------------------------------------------+
#
# systemctl是systemd的主命令, 用于管理系统.
# sudo systemctl reboot
# sudo systemctl poweroff 关闭系统
# sudo systemctl halt    cpu停止工作
# sudo systemctl suspend  暂停系统
# sudo systemctl hybrid-sleep 交互式休眠
#
#
# systemd-analyze 查看启动耗时
# systemd-analyze blame 查看每个服务的启动耗时
# systemd-analyze critical-chain 查看启动过程流
#
#
# hostnamectl 查看当前主机的信息
# hostnamectl set-hostname xx 设置主机名称
#
#
# localectl 查看本地化设置
#
#
# timedatectl 查看当前时区设置
#
#
# loginctl 查看当前登录的用户
# loginctl list-seeions 列出当前的Session
# loginctl list-users 列出当前登录的用户
#
#=======================================================================================================================
#
# Unit 资源单位
# 常用的资源:
#   service 服务
#   target 多个Unit构成的一个组, 运行级别
#   device 设备
#   mount 挂载
#   slice 进程组
#   swap swap文件
#   socket 进程通信的socket
#
# systemctl list-units [OPTIONS] 查询系统的Unit
#
# Unit状态:
# systemctl status [NAME] // NAME可以是具体的资源, 比如 user.slice
# systemctl is-active NAME // 某个Unit是否正在运行
# systemctl is-failed NAME // 某个Unit是否处于启动失败状态
# systemctl is-enabled NAME // 某个Unit是否建立了启动链接
#
# 管理Unit:
# sudo systemctl start|stop|kill|reload UNIT
# sudo systemctl daemon-reload 重新加载所有修改过的配置文件
#
# sudo systemctl show UNIT  显示Unit所有底层参数
# sudo systemctl show -p PARAM UNIT 显示Unit的具体参数
# sudo systemctl set-property UNIT PARAM=VALUE 设置属性
#
# 依赖关系:
# systemctl list-dependcies [UNIT]
#
#=======================================================================================================================
#
# Unit的配置文件
# systemd默认从目录/etc/systemd/system/读取配置文件. 但是里面大部分文件都是符号链接, 指向目录/usr/lib/systemd/system/
#
# systemctl enable UNIT 用于在上面的两个目录之间,建立符号链接关系
#
#
# 配置文件状态:
# systemctl list-unit-files [--type=TYPE]
#   enabled: 已经建立启动链接
#   disabled: 没有建立启动链接
#   static: 该配置文件没有[Install]部分(无法执行), 只能作为其他配置文件的依赖
#   masked: 该配置文件被禁止建立启动链接
#
#
# 配置文件格式:
# systemctl cat UNIT  查看UNIT配置文件的内容
#
# [Unit]
#   Requires: 当前Unit依赖其他Unit, 强依赖
#   Wants: 弱依赖
#   Before: 如果该字段指定的Unit也要启动,那么必须在当前Unit之后启动
#   After: 如果该字段指定的Unit也要启动,那么必须在当前Unit之前启动
#   Condition: 当前Unit运行满足的条件
# [Install]
#   WantedBy: 一个或多个Target, 当前Unit激活时符号链接会放入/etc/systemd/system目录下以Target名+.wants后缀构成的子目录
#   RequiredBy: 强依赖
# [Service]
#   Type: 启动时进程的行为. simple(默认值),执行ExecStart指定的命令,启动主进程. forking, 以fork的方式从父进程创建子进程,创建后
#         父进程会立即退出. oneshot,一次性进程,systemd会等当前服务退出,再继续往下执行. dbus, 当前服务通过D-Bus启动. notify,当
#         前服务启动玩吧,会通知systemd,再继续往下执行. idle, 若其他任务执行完毕, 当前服务才会执行.
#   ExecStart: 启动当前服务的命令
#   ExecStartPre: 启动当前服务之前执行的命令
#   ExecStartPost: 启动当前服务之后执行的命令
#   ExecReload: 重启服务时执行的命令
#   ExecStop: 停止当前服务时执行的命令
#   RestartSec: 自动重启当前服务间隔的秒数
#   Restart: 定义何种情况下systemd会自动重启当前服务. always, on-success, on-failure, on-abnormal, on-abort, on-watchdog
#   TimeoutSec: 定义systemd停止当前服务之前等待的秒数
#   Environment: 指定环境变量
#
#=======================================================================================================================
#
# 日志管理:
# journalctl 查看所有的日志(内核日志和应用日志)
#
# sudo journalctl -k 查看内核日子
# sudo journalctl -b 查看系统本次启动的日志
#
# sudo journalctl _PID=PID 查看指定进程的日志
# sudo journalctl SCRIPT 查看指定脚本的日志
# sudo journalctl -u UNIT 查看UNIT的日志
#
# sudo journalctl -n NUM  尾部最新NUM行日志
#
# sudo journalctl -f  实时显示最新日志