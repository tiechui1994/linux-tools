#!/bin/bash

#----------------------------------------------------
# File: mysql.sh
# Contents: mysql 常用命令
# Date: 19-3-26
#----------------------------------------------------


#---------------------------------------------------------------------------------------------------
# ALTER TABLE
#
# ALTER TABLE tb_name
#       [alter_specification, alter_specification ...]
#
#
# alter_specification:
#       table_options
#
#       ADD [COLUMN] colnum column_define [FIRST | AFTER column] // 添加一列
#
#       ADD [COLUMN] (column column_define, ...) // 添加多列
#
#       CHANGE [COLUMN] old_column new_column column_define [FIRST | AFTER column] // 修改一列
#       MODIFY [COLUMN] column column_define [FIRST | AFTER column] // 修改一列
#       ALTER  [COLUMN] column {SET DEFAULT literal | DROP DEFAULT}
#
#       ADD {INDEX|KEY} [index_name]
#           [index_type] (key_part, ...) [index_option] // 添加索引或者主键
#
#       ADD {FULLTEXT|SPATIAL} [INDEX|KEY] [index_name]
#           (key_part, ...) [index_option]
#
#       ADD [CONSTRAINT symbol] PRIMARK KEY
#           [index_type] (key_part, ...) [index_option]
#
#       ADD [CONSTRAINT symbol] UINQUE [INDEX|KEY] [index_name]
#           [index_type] (key_part, ...) [index_option]
#
#       ADD [CONSTRAINT symbol] FOREIGN KEY [index_name]
#           [column, ...) reference_define
#
#       ADD CHECK (expr)
#
#       ALGORITHM [=] {DEFAULT|INPLACE|COPY}
#
#       DEFAULT CHARACTER SET [=] charset [COLUMN [=] collation]
#
#       CONVERT TO CHARACTER SET [=] charset [COLUMN [=] collation]
#
#       {DISABLE|ENABLE} KEYS
#
#       DROP [COLUMN] column
#       DROP {INDEX|KEY} index_name
#       DROP PRIMARY KEY
#       DROP FROEIGN KEY symbol
#
#       RENAME  {INDEX|KEY} old_index TO new_index
#       RENAME  [TO|AS] new_table
#
#       ORDER BY column, ...
#
#
#   key_part:
#       column [(length)] [ASC|DESC]
#
#   index_type:
#       USING {BTREE | HASH}
#
#   index_option:
#       KEY_BLOCK_SIZE [=] value | index_type | COMMENT 'string'
#
#   table_options:
#       [table_option, table_option, ...]
#
#   table_option:
#       AUTO_INCREMENT [=] value  // 设置自增的开始值(当前计数器的值)
#
#       AVG_ROW_LENGTH [=] value
#
#       [DEFAULT] CHARACTER SET [=] charset // 设置字符编码, utf8, latin1
#
#       [DEFAULT] COLLATE [=] collation
#
#       COMPRESSION [=] {'ZLIB' | 'LZ4' | 'NONE'}
#
#       ENGINE [=] engine
#
#       INSERT_METHOD [=] {NO | FIRST | LAST }
#
#---------------------------------------------------------------------------------------------------


#---------------------------------------------------------------------------------------------------
# ALTER TABLE的性能和空间需求
#
# ALTER TABLE 操作使用下面其中之一的算法进行处理:
#   COPY: 对原始表进行备份操作, 并从原始表的数据逐行复制到新表. 不允许并发DML.
#
#   INPLACE: 可以避免复制表数据, 但可能需要在适当的位置重建表. 可以在操作的准备和执行期间对表的元数据加
#   互斥锁. 通常,支持并发DML.
#
#   ALGORITHM子句是可选的. 如果省略ALGORITHM子句, MySQL将 "ALGORITHM = INPLACE" 用于存储引擎, 并
#   使用支持它的ALTER TABLE子句. 否则, 使用"ALGORITHM = COPY".
#
#---------------------------------------------------------------------------------------------------


#---------------------------------------------------------------------------------------------------
# CHANGE,MODIFY和ALTER子句允许更改现有列的名称和定义, 区别如下:
#
#   CHANGE: 可以对一个列进行重命名或者修改其定义;
#           具有比MODIFY更多的功能, 但是以某些操作的便利性为代价. 如果不重命名, CHANGE需要将列重命名两次;
#           使用FIRST和AFTER可以控制列的位置;
#
#   MODIFY: 可以对一个列的定义进行修改但是不能进行重命名;
#           使用FIRST和AFTER可以控制列的位置;
#
#   ALTER: 只能用来修改列的默认值
#
#---------------------------------------------------------------------------------------------------