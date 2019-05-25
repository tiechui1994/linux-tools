#!/bin/bash

#----------------------------------------------------
# File: sudoers.sh
# Contents: suoders 文件配置
# Date: 19-3-24
#----------------------------------------------------

#---------------------------------------------------------------------------------------------------
# sudo授权
#
# sudo 允许已经授权用户按照指定的安全策略, 以root用户(或者其他用户角色)权限来执行某个命令.
#
# 1. sudo 读取和解析 /etc/sudoers 文件, 查找调用命令的用户及其权限
# 2. 提示调用该命令的用户输入密码(通常是用户密码, 但也可能是目标用户的密码, 或者也可以通过
# NOPASSWD 标志来跳过密码验证).
# 3. sudo 创建一个子进程, 调用setuid() 来切换到目标用户.
# 4. 在上述子进程中执行参数给定的shell脚本或命令.
#
#
# 结论: 通过修改sudoers文件来配置sudo命令的行为.
#
#---------------------------------------------------------------------------------------------------


#---------------------------------------------------------------------------------------------------
# suoder 文件配置策略
#
# Defaults项的类型:
#
# Defaults                parameter,   parameter_list     # 对任意主机登录的所有用户起作用
# Defaults@Host_List      parameter,   parameter_list     # 对指定主机登录的所有用户起作用
# Defaults:User_List      parameter,   parameter_list     # 对指定用户起作用
# Defaults!Cmnd_List      parameter,   parameter_list     # 对指定命令起作用
# Defaults>Runas_List     parameter,   parameter_list     # 对以指定目标用户运行命令起作用
#
# 说明: parameter参数可以是标记(flag), 整数值, 或者列表(list).
#
# 标记(flag)是指布尔类型值, 可以使用! 操作符来进行取反
# 列表(list) 有两个赋值运算符: += (添加到列表) 和 -= (从列表中移除)
#
# Defaults     parameter   # 布尔值, flag
# Defaults     !parameter  # 布尔值, flag
# Defaults     parameter=value    # 整数
# Defaults     parameter -=value  # 列表
# Defaults     parameter +=value  # 列表
#
#---------------------------------------------------------------------------------------------------

#---------------------------------------------------------------------------------------------------
# Defaults 案例
#
# 1. 安置一个安全的PATH环境变量
# 该 PATH 环境变量应用于每个通过 sudo 执行的命令, 注意两点:
#   (1) 当系统管理员不信任 sudo 用户, 便可以设置一个安全的 PATH 环境变量
#   (2) 该设置将 root 的 PATH 和用户的 PATH分开, 只有在 exempt_group 组的用户不受该设置的影响
#
# Defaults secure_path="/usr/local/sbin:/usr/local/bin"
#
#
# 2. 允许tty用户会话使用sudo
# 该设置允许在一个真实的tty中运行调用sudo, 但不允许通过 cron 或者 cgi-bin脚本等方法来调用.
#
# Defaults requiretty
#
#
# 3. 创建sudo日志文件
# 默认情况下, sudo通过syslog来记录到日志, 但是可以通过 logfile 参数来设置一个自定义的日志文件.
#
# Defaults logfile="/var/log/sudo.log"
#
#
# 4. 为sudo用户提示命令用法
# 使用lecture参数可以在系统中为sudo用户提示命令的用法:
# 参数属性值有三个选择:
#   always - 一直提示
#   once - 用户首次运行sudo时提示(默认值)
#   never - 从不提示
#
# Defaults  lecture="always"
#
# 使用 lecture_file 参数指定自定义提示的内容, 在指定的文件中输入适当的提示内容.
#
# Defaults lecture_file=""
#
#
# 5. 输入错误的sudo密码时显示自定义信息
# 通过参数 badpass_message 参数修改错误密码的提示信息.
#
# Defaults badpass_message="Password is wrong, please try again"
#
#
# 6. 增加sudo密码尝试限制次数
# passwd_tries 参数用于指定用户尝试输入密码的次数. 默认是3
#
# Defaults  passwd_tries=3
#
# 使用 passwd_timeout 参数设置密码超时. 默认为5分钟
#
# Defaults  passwd_timeout=3
#
#
# 7. 跨终端sudo
# 如果不想每次启动新终端都重新输入密码, 在配置文件中禁止tty_tickets即可.
# 警告: 此举使得所有进程都使用同一个sudo任务.
#
# Defaults !tty_tickets
#
#
# 8. 修改visudo的编辑器
# 默认情况下, visudo使用vi编辑器. 可以通过editor和env_editor修改
#
# Defaults  editor="/usr/bin/vim", !env_editor
#
#
# 9. 不询问某个用户的密码
# 警告: 任何以设置的用户运行的程序可以无需密码就执行sudo
#
# Defaults:User  !authenticate
#
#---------------------------------------------------------------------------------------------------

#---------------------------------------------------------------------------------------------------
# sudoers导致的问题
#
# SSH TTY问题:
# 远程执行命令时SSH默认不会分配tty. 没有tty, sudo就无法在获取密码时关闭回显. 使用-tt选项强制SSH分配tty.
# 此外, sudoers中的Defaults选项requiretty要求只有拥有tty的用户才能使用sudo. 可以禁用这个选项.
#
#---------------------------------------------------------------------------------------------------


#---------------------------------------------------------------------------------------------------
# Alias配置:
#
# Alias_Type NAME = item, item, ...
# Alias_Type NAME = item, item : NAME = item, item
#
# Alias_Type(别名类型), 包括以下四种类型:
#   Host_Alias 主机别名, item可以是ip地址(单个或整段), 掩码等
#   User_Alias 用户别名, item可以是用户, 用户组(前面要加%), UID(前面要加#)
#   Cmnd_Alias 命令别名, item必须是绝对路径, 可以使用通配符
#   Runas_Alias 定义runas别名, 这个别名指定的是"目的用户", 即sudo允许切换的用户
#
#
# 案例:
#
#   Host_Alias host=localhost, 192.168.1.0/24, 255.255.255.0
#
#   User_Alias user=root, %wheel
#
#   Cmnd_Alias cmd=/usr/bin/git, /usr/bin/passwd [A-Za-z]*
#
#---------------------------------------------------------------------------------------------------


#---------------------------------------------------------------------------------------------------
# 授权规则:
#
# 针对上述的别名或者是系统用户进行授权. 格式如下:
# USER     HOST=CMD
#
# 注: 这三个要素缺一不可, 但在动作之前也可以指定切换到特定用户下, 在这里指定切换的用户需要使用括号括起来,
# (省略的情况下默认是切换到root用户下执行), 如果不需要密码直接运行命令的, 应该加上"NOPASSWD"参数
#
#
# 案例:
#
# mysql ALL=(root) /bin/chown,/bin/chmod
# mysql ALL=(root) PASSWD:/bin/chown,/bin/chmod # 和上面的是等价的
#
# admin ALL=(root) NOPASSWD:/bin/chown # 不需要密码
#
# admin ALL=(root:%wheel) NOPASSWD:/bin/chmod
#
#---------------------------------------------------------------------------------------------------