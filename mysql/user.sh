#!/bin/bash

#----------------------------------------------------
# File: user.sh
# Contents: mysql create user
# Date: 7/23/19
#----------------------------------------------------

#---------------------------------------------------------------------------------------------------
# CREATE USER SYNTAX
#
# CREATE USER [IF NOT EXISTS]
#   user [auth_option], user [auth_option] ...
#   [REQUIRE {NONE | tls_option [[AND] tls_option] ...}]
#   [WITH resouce_option resource_option ...]
#   [password_option | lock_option ] ...
#
# user:
#   格式: 'user_name'@'host_name'
#   a) 'user_name' <==> 'user_name'@'%'
#   b) user_name是区分大小写的, host_name是不区分大小写的
#   c) user_name是非空格值, 如果user_name是空字符串, 则与任何用户名匹配. 如果user_name是空格值, 则该账号是匿名用户.
#   要在SQL语句当中指定匿名用户, 请使用带引号的空格用户名, 例如: ''@'localhost'
#   d) user_name 和 host_name可以采用多种形式, 并允许使用通配符.
#      host_name使用子网掩码, 格式是 host_ip/netmask, 其中host_ip 是网络地址, 例如 '192.168.10.0/255.255.255.0'
#
#
# auth_option:
#  {  IDENTIFIED BY 'auth_string'
#   | IDENTIFIED WITH auth_plugin
#   | IDENTIFIED WITH auth_plugin BY 'auth_string'
#   | IDENTIFIED WITH auth_plugin AS 'auth_string'
#   | IDENTIFIED BY PASSWORD 'auth_string'
#  }
#
# tls_option:
#  { SSL | X509 | CIPHER 'cipher' | ISSUER 'issuer' | SUBJECT 'subject' }
#
# resource_option:
#  {  MAX_QUERIES_PER_HOUR count
#   | MAX_UPDATES_PER_HOUR count
#   | MAX_CONNECTIONS_PER_HOUR count
#   | MAX_USER_CONNECTIONS count
#  }
#
# password_option:
#  {  PASSWORD EXPIRE
#   | PASSWORD EXPIRE DEFAULT
#   | PASSWORD EXPIRE NEVER
#   | PASSWORD EXPIRE INTERVAL N DAY
#  }
#
# lock_option:
#  {  ACCOUNT_LOCK | ACCOUNT_UNLOCK }
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