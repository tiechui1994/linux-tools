#!/bin/bash

#----------------------------------------------------
# File: iptables
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
# 该模块的功能是限制单位时间内进入数据包的数量. 该模块使用token bucket过滤器限制数据包匹配的速率. 使用此扩展名的规则将
# 匹配, 直到达到此限制(除非使用'!'标记). 例如, 它可以与 target LOG 组合使用以提供有限的日志记录.
#
#   --limit rate
#   最大平均匹配率: 指定为一个数字, 并带有可选的"/second", "/minute", "/hour" 或"/day"后缀; 默认值为"3/hour".
#
#   --limit-burst number
#   初始化时, 允许最多可以匹配的包, 一旦到达此值, 将使用limit设置的限制. 默认值为5
#
#   案例:
#   iptables -A INPUT -p icmp -m limit --limit 6/minute --limit-burst 5 -j ACCEPT
#   iptables -A INPUT -p icmp DROP
#   1分钟之内可以进行6次icmp包匹配 (即每10秒1次). 初始化的时候, 最多允许匹配的icmp数据包是5个. 初始化的icmp累积的包
#   一旦到达5个之后, 每10秒匹配一次, 没有匹配上的数据包丢弃.
#
#
# mac
#   --mac-source [!] address
#   匹配源MAC地址. 它必须是XX:XX:XX:XX:XX:XX的形式. 注意, 这仅适用于来自以太网设备并进入PREROUTING, FORWARD或
#   INPUT链的数据包.
#
#
# mark
#   此模块匹配与数据包关联的netfilter标记字段(可使扩展target中的MARK设置)
#
#   --mark value[/mask]
#   匹配具有给定无符号标记值的数据包(如果指定了mask, 则在比较之前与掩码进行逻辑AND运算).
#
#
# multiport
#   此模块与一组源或目标端口匹配. 最多可指定15个端口. 端口范围(port:port)计为两个端口. 它只能与-p tcp或-p udp一起
#   使用.
#
#   --source-ports [!] port,port:port
#   如果源端口是给定端口之一, 则匹配. --sports是此选项的别名.
#
#   --destination-ports [!] port,port:port
#   如果目标端口是给定端口之一, 则匹配. --dports是此选项的别名.
#
#    --ports  [!] port,port:port
#   如果源端口或目标端口等于给定端口之一, 则匹配.
#
#
# state
#   此模块与connection tracking结合使用时, 可以访问到数据包的connection tracking状态。
#
#   --state state
#   其中state是要匹配的连接状态列表. INVALID表示由于某种原因无法识别数据包, 包括内存不足和ICMP错误(与任何已知连接不对
#   应), ESTABLISHED表示已经建立链接的数据包, NEW表示开始建立新链接的数据包, 与现有的链接没有关联, RELATED表示正在
#   启动新连接的数据包, 但与现有连接相关联,例如FTP数据传输或ICMP错误.
#
#
# tcp
#   如果指定了"--protocol tcp", 则会加载这些扩展.
#
#   --source-port [!] port[:port]
#   源端口或端口范围. 这可以是服务名称或端口号, 也可以使用格式port:port指定包含范围. 如果省略第一个端口, 则假定为"0";
#   如果省略最后一个, 则假定为"65535". 如果第二个端口大于第一个端口, 它们将被交换. --sport是此选项别名.
#
#   --destination-port [!] port[:port]
#   目标端口或端口范围. --dport是此选项别名.
#
#   --tcp-flags [!] mask comp
#   匹配指定的TCP flags. 第一个参数是应该检查的标志, 写为逗号分隔列表; 第二个参数是逗号分隔的标志列表, 必须设置.
#   flag: SYN ACK FIN RST URG PSH ALL NONE.
#   案例:
#   iptables -A FORWARD -p tcp --tcp-flags SYN,ACK,FIN,RST SYN  // 它只匹配设置了SYN标志的数据包, 且ACK,
#   FIN,RST未设置的数据包
#
#   [!] --syn
#   匹配仅设置SYN位设置的TCP数据包, 并清除ACK,RST和FIN位. 等价于 --tcp-flags SYN,ACK,FIN,RST SYN
#
#   --tcp-option [!] number
#   如果TCP选项设置, 则匹配
#
#   --mss value[:value]
#   将TCP SYN或SYN/ACK数据包与指定的MSS(maximum segment size)值(或范围)匹配, 它控制该连接的最大数据包大小.
#
# cluster(配合arp使用)
# 允许部署网关和后端负载共享群集, 而无需负载均衡器. 此匹配要求所有节点都看到相同的数据包.
#
#   --cluster-total-nodes num
#   集群节点数量
#
#   [!] --cluster-local-node num
#   当前节点的id, 从1开始
#
#   [!] --cluster-local-nodemask mask
#   设置本地节点号ID掩码. 可以使用此选项替换 --cluster-local-node.
#
#   --cluster-hash-seed value
#   设置hash的初始化种子
#
#   example:
#   iptables  -t mangle  -A PREROUTING  -i eth1  -m cluster  --cluster-total-nodes 2 \
#   --cluster-local-node 1  --cluster-hash-seed 0xdeadbeef  -j MARK --set-mark 0xffff
#
#   iptables  -t mangle  -A PREROUTING  -i eth2  -m cluster  --cluster-total-nodes 2 \
#   --cluster-local-node 2  --cluster-hash-seed 0xdeadbeef  -j MARK --set-mark 0xffff
#
#   iptables -t mangle  -A PREROUTING  -i eth1  -m mark  ! --mark 0xffff  -j DROP
#
#   iptables -t mangle  -A PREROUTING  -i eth2  -m mark  ! --mark 0xffff  -j DROP
#
#   以下命令使所有节点看到相同的数据包:
#   ip maddr add 01:00:5e:00:01:01 dev eth1
#   ip maddr add 01:00:5e:00:01:02 dev eth2
#
#   arptables  -A OUTPUT  -o eth1  --h-length 6  -j mangle  --mangle-mac-s 01:00:5e:00:01:01
#   arptables  -A INPUT   -i eth1  --h-length 6  --destination-mac 01:00:5e:00:01:01  -j mangle \
#   --mangle-mac-d 00:zz:yy:xx:5a:27
#
#   arptables  -A OUTPUT  -o eth2  --h-length 6  -j mangle  --mangle-mac-s 01:00:5e:00:01:02
#   arptables  -A INPUT   -i eth2  --h-length 6  --destination-mac 01:00:5e:00:01:02  -j mangle \
#   --mangle-mac-d 00:zz:yy:xx:5a:27
#
#   在TCP连接的情况下,必须禁用拾取工具以避免将回复方向上的TCP ACK数据包标记为有效.
#   echo 0 > /proc/sys/net/netfilter/nf_conntrack_tcp_loose
#
#
# connlimit
# 允许您限制每个客户端IP地址(或客户端地址块)与服务器的并行连接数.
#
#   --connlimit-upto num
#   如果现有连接数低于或等于n, 则匹配.
#
#   --connlimit-above num
#   如果现有连接数高于n, 则匹配.
#---------------------------------------------------------------------------------------------------


#---------------------------------------------------------------------------------------------------
# Target Extensions
#
# BALANCE
#   这允许在给定范围的目标地址上以循环方式进行DNAT连接.
#
#   --to-destination ipaddr-ipaddr
#   地址范围
#
# CLUSTERIP (kernel 4.6之前使用, 之后使用扩展匹配cluster)
#   此模块允许配置一个简单的节点集群, 这些节点共享某个IP和MAC地址. 在此群集中的节点之间连接是静态分布.
#
#   --new
#   创建一个新的ClusterIP. 必须在给定ClusterIP的第一个规则上设置此项.
#
#   --hashmode mode
#   指定散列模式. 必须是sourceip, sourceip-sourceport, sourceip-sourceport-destport之一
#
#   --clustermac mac
#   指定ClusterIP MAC地址. 必须是链路层多播地址.
#
#   --total-nodes num
#   设置集群节点的数量
#
#   --local-node num
#   设置集群的本地节点数量
#
#   --hash-init rnd
#   设置hash初始化的随机种子
#
#
# LOG
#   打开匹配数据包的内核日志记录. 当为rule设置此选项时, Linux内核将通过内核日志(可以使用dmesg或syslogd读取)在所有匹
#   配的数据包(如大多数IP头字段)上记录一些信息. 这是一个"nnon-terminating target", 即当规则不匹配时会继续使用下一个
#   规则进行匹配. 因此, 如果要LOG拒绝的数据包, 请使用具有相同匹配条件的两个单独规则, 首先使用目标LOG, 然后使用DROP(或
#   REJECT).
#
#   --log-level level
#   设置日志级别, 查看syslog.conf
#
#   --log-prefix prefix
#   设置日志前缀
#
#   --log-tcp-sequence
#   记录TCP的sequence No. 有安全风险
#
#   --log-uid
#   记录生成数据包的进程的uid
#
#
# REDIRECT
#   此target仅在nat表中使用. 它通过修改数据包的目标IP为incoming interface的地址从而达到数据包的重定向的目的.
#
#   --to-ports port-port
#   这指定了要使用的目标端口或端口范围: 如果不指定, 则不会更改目标端口. 仅当rule指定了'-p tcp'或'-p udp'时, 此选项才
#   有效.
#
#
# REJECT
#   用于响应匹配的数据包发回错误数据包: 它是terminating target, 会结束rule遍历. 此target仅在INPUT, FORWARD和
# OUTPUT链以及仅从这些链调用的自定义链中有效.
#
#   --reject-with type
#   设置错误数据包的类型. 包括以下类型:
#   icmp-net-unreachable
#   icmp-host-unreachable
#   icmp-port-unreachable
#   icmp-proto-unreachable
#   icmp-net-prohibited
#   icmp-host-prohibited or
#   icmp-admin-prohibited (*)
#   返回相应的ICMP错误消息(默认为icmp-port-unreachable). 使用icmp-admin-prohibited与不支持它的内核将导致一个普
#   通的DROP而不是REJECT.
#
#
# SNAT
#   此target仅在nat表中的POSTROUTING链中有效. 它指定应修改数据包的源地址(此连接中的所有未来数据包也将被修改), 并且应
#   停止检查规则.
#
#   --to-source ipaddr[-ipaddr][:port-port]
#   它可以指定单个源IP地址或IP地址范围, 以及可选的端口范围(仅当rule还指定-p tcp或-p udp时才有效). 如果未指定端口范围,
#   则低于512的源端口将映射到512以下的其他端口; 512和1023之间的端口将映射到1024以下的端口; 其他端口将映射到1024或更高
#   的端口号.
#   可以添加多个 --to-source-选项.
#
#
# DNAT
#   此target仅在nat表中的POSTROUTING链中有效. 它指定应修改数据包的目标地址(此连接中的所有未来数据包也将被修改), 并且
#   应停止检查规则
#
#   --to-destination ipaddr[-ipaddr][:port-port]
#
#---------------------------------------------------------------------------------------------------