#!/bin/bash

#----------------------------------------------------
# File: update.sh
# Contents: mysql update
# Date: 7/4/19
#----------------------------------------------------

#---------------------------------------------------------------------------------------------------
# Single-table
#
# UPDATE [LOW_PRIORITY] [IGNORE] table_refer
#   SET assignment_list
#   [WHERE where_condition]
#   [ORDER BY ...]
#   [LIMIT row_count]
#
#
# assignment_list:
#   assignment [, assignment] ...
#
# assignment:
#   col_name = value
#
# value:
#   { expr | DEFAULT }
#
#---------------------------------------------------------------------------------------------------

#---------------------------------------------------------------------------------------------------
# Multiple-table
#
# UPDATE [LOW_PRIORITY] [IGNORE] table_refer
#   SET assignment_list
#   [WHERE where_condition]
#
# 注意: 该table_refer子句列出了连接中涉及的表.
#---------------------------------------------------------------------------------------------------


#---------------------------------------------------------------------------------------------------
# UPDATE语句支持以下修饰符：
#
# - 使用LOW_PRIORITY关键字, UPDATE的将被延迟执行, 直到没有其他客户端从表中读取. 这仅影响仅使用表级锁定的存储引擎(例
# 如MyISAM, MEMORY和MERGE).
#
# - 使用IGNORE关键字, 即使更新期间发生错误, update语句也不会中止. 在唯一键值上发生重复键冲突的行不会更新. 行更新为可能
# 导致数据转换错误的值将更新为最接近的有效值.
#
#
# IGNORE关键字和严格SQL模式的比较:
# IGNORE关键字(将错误降级位警告)和严格SQL模式(将警告升级为错误)的语句的执行效果.
#
# 操作模式                   当语句默认是错误                         当语句默认是警告
# 没有IGNORE或严格的SQL模式    错误                                  警告
# IGNORE                    警告                                  警告(与没有IGNORE或严格的SQL模式相同)
# 采用严格SQL模式             错误(与没有IGNORE或严格的SQL模式相同)     错误
# 采用IGNORE的严格SQL模式      警告                                  警告
#
# IGNORE对语句执行的影响:
#
# MySQL中的几个语句支持一个可选的IGNORE关键字. 此关键字会导致服务器降级某些类型的错误, 并生成警告. 对于多行语句,
# IGNORE会导致语句跳到下一行而不是终止.
#
# 支持IGNORE关键字的语句, 包括如下:
# CREATE TABLE ... SELECT: IGNORE不适用CREATE TABLE或SELECT声明的部分, 但是要插入到所产生的行的表SELECT. 丢弃
# 在唯一键值上复制现有行的行.
# DELETE: IGNORE导致MySQL在删除行的过程忽略错误.
# INSERT: 与IGNORE, 在唯一键值上复制现有行将被丢弃. 将设置为导致数据转换错误的值设置为最接近的有效值.
# LOAD DATA, LOAD XML: INGORE将丢弃在唯一键值上复制现有行的行.
# UPDATE: 与IGNORE, 在唯一键值上发生重复键冲突的行不会更新. 行更新为可能导致数据转换错误的值将更新为最接近的有效值.
#
# 严格SQL模式对语句执行的影响:
# MySQL服务器可以在不同的SQL模式下运行, 并且可以根据sql_mode系统变量的值对不同客户端应用不同的模式. 在严格SQL模式下,
# 服务器将某些警告升级位错误.
#
# 严格SQL模式适用以下的语句, 在某些情况下某些值可能超出范围, 或者在表中插入或删除无效行:
# ALTER TABLE
# CREATE TABLE
# CREATE TABLE ... SELECT
# DELETE
# INSERT
# LOAD DATA
# LOAD XML
# SELECT SLEEP()
# UPDATE
#---------------------------------------------------------------------------------------------------
