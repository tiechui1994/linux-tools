#!/bin/bash

#----------------------------------------------------
# File: ${NAME}
# Contents: root
# Date: 19-6-4
#----------------------------------------------------

# link: https://linux.die.net/man/8/iptables

#---------------------------------------------------------------------------------------------------
# Description
#
# iptables 用于在Linux内核中设置, 维护和检查IPv4数据包过滤规则表. 可以定义几个不同的表, 每个表包含许多内置链. 也可能
# 包含用户定义的链.
#
# 每个链是由一组可以匹配数据包的rule组成. 每个rule指定应当如何处理与之匹配的packet. 这被称为'target'(目标), 也可以
# 跳向到同一个表内的用户定义的链.
#
#
# Target
#
# 防火墙规则指定了packet和target匹配的条件. 如果packet不匹配, 则会使用链中的下一个rule进行匹配. 如果packet匹配, 则
# 下一条rule由链的target值指定, 该值可以是用户定义的链名, 也可以是特殊值ACCEPT, DROP, QUEUE 或 RETURN当中之一.
#
# ACCEPT 表示让packet通过.
# DROP 表示将packet丢弃.
# QUEUE 表示将packet传递给用户空间.
# RETURN 表示停止当前的链的匹配, 到前一个链的下一条rule重新开始. 如果packet到达内置链的末端或者packet匹配到target是
# RETURN的内置链中的rule, 则使用链设置的target处理此packet.
# LOG 表示让packet通过, 并在内核日志当中记录日志信息
# REJECT 表示将packet丢弃并且向源地址发送拒绝响应
#
#
# Table
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
#---------------------------------------------------------------------------------------------------


#---------------------------------------------------------------------------------------------------
# Command
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
#---------------------------------------------------------------------------------------------------


#---------------------------------------------------------------------------------------------------
# Parameter
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
#   设置当前rule跳转到的target. 可选的值ACCEPT, LOG, DROP, REJECT, QUEUE, RETURN, 或者 用户自定义链名
#
#   -g, --goto chain
#   调到某条chain中继续执行. 与--jump选项RETURN, 在此链中不会继续处理, 而是在通过--jump调用我们的链中.
#
#   -i, --in-interface [!] name
#   接收数据包的网卡名称(仅适用于进入INPUT, FORWARD和PREROUTING链的数据包).
#   如果网卡名称以"+"结尾, 则以此名称开头的任何接口都将匹配. 如果省略此选项, 则任何接口名称都将匹配.
#
#   -o, --out-interfac [!] name
#   发送数据包的网卡名称(对于进入FORWARD,OUTPUT和POSTROUTING链的数据包).
#   如果网卡名称以"+"结尾，则以此名称开头的任何接口都将匹配. 如果省略此选项, 则任何接口名称都将匹配。
#
#   [!] -f, --fragment
#
#---------------------------------------------------------------------------------------------------


#---------------------------------------------------------------------------------------------------
# Match Extensions
# iptables可以使用扩展数据包匹配模块. 它们以两种方式加载: 当指定-p或--protocol时,会隐式加载, 或使用-m或--match选项,
# 后跟匹配的模块名称; 之后, 根据具体模块, 可以使用各种额外的命令行选项. 可以在一行中指定多个扩展匹配模块. 并且在指定模块
# 后可以使用-h或--help选项来接收特定于该模块的帮助.
#
# 以下内容包含在基本包中, 其中大部分都可以在前面加上 "!" 进行取反操作.
#
# account
#
# limit
# 该模块的功能是限制单位时间内进入数据包的数量. 该模块使用token bucket过滤器以有限的速率匹配。 使用此扩展名的规则将匹配,
# 直到达到此限制（除非使用'！'标志）。
# 例如，它可以与LOG目标结合使用以提供有限的日志记录.
#
#---------------------------------------------------------------------------------------------------


#---------------------------------------------------------------------------------------------------
# Target Extensions
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