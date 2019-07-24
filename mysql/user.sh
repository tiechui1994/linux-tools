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
#---------------------------------------------------------------------------------------------------


#---------------------------------------------------------------------------------------------------
# CREATE USER Overview
#   Authentication: 使用 default_authentication_plugin 参数配置的plugin
#   SSL/TLS: NONE
#   Resource limits: Unlimited
#   Password management: PASSWORD EXPIRE DEFAULT
#   Account locking: ACCOUNT UNLOCK
#
#
# CREATE USER Authentication Options
#   plugin:
#       mysql_native_password   based on native password hashing methoda. 对于server, 默认是内置的. 对于
#       client, 内置在libmysqlclient库当中. 在MySQL5.7当中默认的插件.
#
#       sha256_password   basic SHA-256 authentication.
#       注意: 为了使用sha256_password plugin, 必须使用TLS加密连接, 或者支持使用RSA密钥对进行密码交换的非加密连接.
#       对于server, 默认是内置的. 对于client, 内置在libmysqlclient库当中.
#
#       - 对于Server, 系统变量sha256_password_private_key_path和sha256_password_public_key_path提供了RSA
#       密钥对的文件路径
#
#       - 对于Server, 系统变量sha256_password_auto_generate_rsa_keys决定是否自动生成RSA密钥对文件.
#
#       - Rsa_public_key状态变量, 显示了 sha256_password 身份验证插件使用的RSA公钥值.
#
#       - 对于使用 sha256_password 和 基于RSA公钥对的密码交换进行身份验证的帐户的连, Server 会根据需要将RSA公钥发
#       送到Client. 但是, 如果Client主机上有公钥的副本, 则Client可以使用它来保存 C/S 协议中的往返:
#           - 对于这些命令的客户端, 使用--server-public-key-path选项指定RSA公钥文件. mysql, mysqltest,
#           mysqladmin, mysqlbinlog, mysqlcheck, mysqldump, mysqlimport, mysqlpump, mysqlshow,
#           mysqlslap,
#
#           - 对于slaves, 基于RSA密钥对的密码交换不能用于连接到使用sha256_password插件进行身份认证的账号的master
#           服务器. 对于此类账户, 只能使用SSL安全连接.
#
#       caching_sha2_password   SHA-256 authentication, but uses caching on server side. 在MySQL8.0当
#       中默认的插件.
#       注意: 在MySQL5.7当中, caching_sha2_password 插件只能限制为Client使用, 而其Server没有实现此插件(因此,在
#       MySQL5.7当中Server不支持使用此插件).
#
#---------------------------------------------------------------------------------------------------