#!/bin/bash

#----------------------------------------------------
# File: service.sh
# Contents: service操作命令
# Date: 18-11-8
#----------------------------------------------------

# check system init
check_init() {
    if [[ $(/sbin/init --version) =~ upstart ]]; then
        echo upstart
    elif [[ $(systemctl) =~ -\.mount ]]; then
        echo systemd
    elif [[ -f /etc/init.d/cron && ! -h /etc/init.d/cron ]]; then
        echo sysv-init
    else
        echo null
    fi
}


#---------------------------------------------------------------------------------------------------
# 在ubuntu系列中, 服务相关的命令包括:
# service, update-rc.d, init, invoke-rc.d, systemctl
#---------------------------------------------------------------------------------------------------


#---------------------------------------------------------------------------------------------------
# service: 服务查看
# 
# service --status-all 查看所有的服务的状态
# 
# service SERVICE  COMMAND|--full-restart
#     SERVICE: /etc/init.d/ 目录下的service脚本
#     COMMAND: 依赖于SERVICE脚本的值, 常用的有'start', 'stop', 'status'等. --full-restart等价于先
#              stop后start
#
#---------------------------------------------------------------------------------------------------


#---------------------------------------------------------------------------------------------------
# chkconfig: centos中服务的运行级别设置
#
# chkconfig --list [--type <type>] [name] 列出服务, type: 'sysv', 'xinetd', name:服务名称
# chkconfig --add <name> 添加服务
# chkconfig --del <name> 删除服务
# chkconfig --override <name> 服务覆盖
# chkconfig [--level <levels>] [--type <type>] <name> <on|off|reset>  服务操作
#
#---------------------------------------------------------------------------------------------------


#---------------------------------------------------------------------------------------------------
# update-rc.d: 建立或者删除System-V风格的init脚本链接
# 
# update-rc.d [-n] [-f] SERVICE remove  移除一个服务
# update-rc.d [-n] [-f] SERVICE defaults 设置默认的运行级别, 并建立链接
# 
# update-rc.d [-n] SERVICE disable|enable [S|2|3|4|5] 增加停止/启动服务脚本的连接
# 
#     -f 强制删除对/etc/init.d/SERVICE的符号链接
#     -n 只是显示, 不做任何操作
#
#---------------------------------------------------------------------------------------------------

#---------------------------------------------------------------------------------------------------
# systemd: systemd是Linux操作系统的系统和服务管理器. 当在引导时作为第一个进程运行时(
#     作为PID 1),它充当启动和维护用户空间服务的init系统.
#     对于具有SysV的相容性,如果systemd称为init和一个PID不是1,则执行使用telinit和传
#     递所有的命令行参数不变.
# 
# systemd [OPTIONS...]
# 
# OPTIONS:
#     --test 确定启动顺序,转储它并退出
#     --uint=UNIT 设置资源类别
#     --system 系统实例
#     --user  用户实例
# 
#     --crash-vt=NR
#     --crash-reboot[=BOOL]
#     --crash-shell[=BOOL]
#
#---------------------------------------------------------------------------------------------------