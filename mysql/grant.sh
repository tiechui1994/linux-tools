#!/bin/bash

#----------------------------------------------------
# File: grant
# Contents: mysql grant
# Date: 7/23/19
#----------------------------------------------------


#---------------------------------------------------------------------------------------------------
# GRANT SYNTAX
#
# GRANT privilege_type [(column_list)], privilege_type [(column_list)]...
#       ON [object_type] privilege_level
#       TO user [auth_option], user [auth_option]...
#       [REQUIRE {NONE | tls_option [[AND] tls_option] ...}]
#       [WITH {GRANT OPTION | resource_option} ...]
#
#
# GRANT PROXY ON user
#       TO user user, user ...
#       [WITH GRANT OPTION]
#
# privilege_type:
#   ALL [PRIVILLEGES]
#   INSERT   levels: global, database, table, column
#   UPDATE   levels: global, database, table, column
#   SELECT   levels: global, database, table, column
#   CREATE   levels: global, database, table
#   DELETE   levels: global, database, table
#
#   ALTER    ALTER TABLE. levels: global, database, table
#   DROP     levels: global, database, table
#   INDEX    levels: global, database, table
#   EVENT    Event Scheduler. levels: global, database
#   EXECUTE  execute stored routines. levels: global, routine
#   FILE     server read and write files. levels: global
#   PROXY    proxying. level: from user to user
#   RELOAD   FLUSH operations.  level: global
#   SUPPER   admin. level: global
#
#
# object_type:
#   { TABLE | FUNCTION | PROCEDURE }
#
# privilege_level:
#   { * | *.* | db_name.* | db_name.tb_name | tb_name | db_name_routine_name }
#
# auth_option:
#   { IDENTIFIED BY 'auth_string'
#       | IDENTIFIED WITH auth_plugin
#       | IDENTIFIED WITH auth_plugin BY 'auth_string'
#       | IDENTIFIED WITH auth_plugin AS 'auth_string'
#       | IDENTIFIED BY PASSWORD 'auth_string'
#   }
#
# tls_option:
#   { SSL | X509 | CIPHER 'cipher' | ISSUER 'issuer' | SUBJECT 'subject' }
#
# resource_option:
#   { MAX_QUERIES_PER_HOUR count
#       | MAX_UPDATES_PER_HOUR count
#       | MAX_CONNECTIONS_PER_HOUR count
#       | MAX_USER_CONNECTIONS count
#   }
#
#
# 注意: column_list, 只有当privilege_type是column级别的权限的时候,才可能会出现.
#      object_type, 默认是TABLE
#
#---------------------------------------------------------------------------------------------------
