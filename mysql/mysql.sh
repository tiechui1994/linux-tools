#!/bin/bash

#----------------------------------------------------
# File: mysql.sh
# Contents: 运维当中mysql常见问题解决方案
# Date: 19-3-21
#----------------------------------------------------


#---------------------------------------------------------------------------------------------------
# 已知MYSQL数据库ROOT用户密码的情况下, 修改密码:
#
# shell 环境下, mysqladmin -u root -p password 'newpassword'
#
# mysql 环境下, update mysql.user set password=password('new') where user='root';
#              fulsh privileges;
#
#---------------------------------------------------------------------------------------------------


#---------------------------------------------------------------------------------------------------
# 忘记MYSQL数据库ROOT用户密码的情况下, 重置密码:
#
# service mysqld stop // 关闭mysql服务
#
# mysqld_safe --skip-grant-table &  // 安全模式启动mysqld服务
#
# mysql -u root // 登录mysql环境
#
# update mysql.user set password=password('new') where user='root';
# fulsh privileges;
#
#---------------------------------------------------------------------------------------------------