#!/bin/bash

#----------------------------------------------------
# File: ${NAME}
# Contents: root
# Date: 19-6-4
#----------------------------------------------------


#---------------------------------------------------------------------------------------------------
# description
#
# iptables 用于在Linux内核中设置, 维护和检查IPv4数据包过滤规则表. 可以定义几个不同的表, 每个表包含许多内置链. 也可能
# 包含用户定义的链.
#
# 每个链是由一组可以匹配数据包的rule组成. 每个rule指定应当如何处理与之匹配的packet. 这被称为'target'(目标), 也可以
# 跳向到同一个表内的用户定义的链.
#
#
# target
#
# 防火墙规则指定了packet和target匹配的条件. 如果packet不匹配, 则会使用链中的下一个rule进行匹配. 如果packet匹配, 则
# 下一条rule由链的target值指定, 该值可以是用户定义的链名, 也可以是特殊值ACCEPT, DROP, QUEUE 或 RETURN当中之一.
#
# ACCEPT 表示让packet通过.
# DROP 表示将packet丢弃.
# QUEUE 表示将数据包传递给用户空间.
# RETURN 表示停止当前的链的匹配, 到前一个链的下一条rule重新开始. 如果packet到达内置链的末端或者packet匹配到target是
# RETURN的内置链中的rule, 则使用链设置的target处理此packet.
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
#   删掉指定的用户自定义的链. 这个链必须没有被引用, 如果被引用, 在删除之前必须删除或替换与之相关的rule.
#
#   -E, --rename-chain old-chain new-chain
#
#   -P, --policy chain target
#   设置chain的target. 只有内置(非用户定义)链才能拥有policy, 内置链和用户定义链都不能作为策略的target
#
#
#
# parameter
#
#   -p, --protocol [!] protocol
#   指定packet的协议. 可选值: tcp, udp, icmp, all, 或者是一个数字. 在/etc/protocols空可以查看到所有支持的协议
#
#   -s, --source [!] address[/mask]
#   指定源地址. address可以是主机名(可以被DNS解析), ip地址(可以带掩码)
#
#   -d, --destination [!] address[/mask]
#   指定目标地址, 同源地址
#
#   -j, --jump target
#   设置rule的target. 可选的值ACCEPT, DROP, QUEUE, RETURN, 或者 用户自定义链名
#
#   -g, --goto chain
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