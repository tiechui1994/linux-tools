#!/bin/bash

#----------------------------------------------------
# File: ${NAME}
# Contents: root
# Date: 19-6-4
#----------------------------------------------------


#---------------------------------------------------------------------------------------------------
# description
#
# iptables 用于在Linux内核中设置, 维护和检查IPv4数据包过滤规则表. 可以定义几个不同的表, 每个表包含许多内置链. 也可能包
# 含用户定义的链.
#
# 每个链是由一组可以匹配数据包的rule组成, 每个rule定义了如何处理匹配的数据包. 这被称为'target', 可以可跳转到同一个表中的
# 用户定义链.
#
#
# target
#
# 防火墙规则指定了packet和target匹配的条件. 如果packet不匹配, 则会使用链中的下一个rule进行匹配. 如果packet匹配, 则下一
# 条rule由target的值指定, 该值可以是用户定义的链的名称, 也可以是特殊值ACCEPT, DROP, QUEUE 或 RETURN当中之一.
#
# ACCEPT表示让packet通过. DROP表示将packet丢弃. QUEUE表示将数据包传递给用户空间. RETURN表示停止遍历当前的链并继续前
# 一个(calling)链的下一条rule. 如果packet到达内置链的末尾 或者 packet匹配目标RETURN的内置链中的规则, 则链policy指定
# 的target将决定packet的结果.
#
#
# table
#
# 目前内置的table有5个.
#
# -t, --table TABLE
#   此选项指定命令应对其执行的packet匹配表. 如果内核配置了自动模块加载, 则会尝试加载该表的相应模块(如果该表尚不存在).
#   表格如下:
#       filter, 这是默认表(如果没有指定-t选项). 它提供的内置链: INPUT, FORWARD 和 OUTPUT
#
#       nat, 当数据包是建立新连接时, 会查询此表. 它提供的内置链: PREROUTING, OUTPUT 和 POSTROUTING
#
#       mangle, 该表用于专门的数据包更改. 它由五个内置链组成: PREROUTING, OUTPUT, INPUT, FORWARD 和 POSTROUTING.
#
#       raw, 该表主要用于配置与NOTRACK目标相结合的连接跟踪豁免. 它在具有更高优先级的netfilter hooks中注册, 在
#   ip_conntrack 或 任何其他IP table之前调用. 它提供的内置链: PREROUTING, OUTPUT.
#
#       security, 此表用于MAC网络规则, 例如由 SECMARK 和 CONNSECMARK 目标启用的规则. MAC由Linux安全模块(如SELinux)
#   实现. 在filter表之后调用security表, 允许filter表中的任何DAC规则在MAC规则之前生效. 它提供的内置链: INPUT, OUTPUT
#   和 FORWARD.
#
#
#
# command
#   -A, --append chain rule
#
#   -I, --insert chain rule
#
#   -D, --delete chain ruleno
#
#   -R, --replace chain ruleno rule
#
#   -L, --list [chain]
#   列出所选chain的所有rule
#
#   -S, --list-rules [chain]
#   打印所选chain的所有rule. 打印类似iptables-save
#
#   -C, --check chain rule
#   检查所选链中是否存在rule.
#
#   -F, --flush [chain]
#   清空所选chain的所有rule
#
#   -Z, --zero [chain [ruleno]]
#   将所选chain中的数据包和字节计数器归零.
#
#   -N, --new-chain chain
#
#   -X, --delete-chain chain
#
#   -E, --rename-chain old-chain new-chain
#
#   -P, --policy chain target
#
#---------------------------------------------------------------------------------------------------