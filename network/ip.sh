#!/bin/bash


#---------------------------------------------------------------------------------------------------
#
# ip [ OPTIONS ] OBJECT { COMMAND }
#
# OPTIONS:
#    -V, -Version    版本信息
#    -s, -stats      带有统计色彩
#    -d, -details    详细信息
#    -h, -human
#
#    -f, -family { inet | inet6 | ipx | dnet | mpls | bridge | link }
#    -I => -family ipx
#    -D => -family dnet
#    -B => -family bridge
#    -M => -family mpls
#    -0 => -family link
#    -4 => -family inet
#    -6 => -family inet6
#
#    -o, -online    每条记录输出为一行
#    -t, -timestamp  使用 monitor 命令时显示当前时间
#    -ts, -tshort
#    -b, -batch [filename]  从文件或者标准输出中读取命令并执行
#    -rc, -rcvbuf [size]
#
#    -n, -netns name      将ip切换到指定的网络命名空间NETNS, 简化操作:
#        ip netns exec NETNS ip [ OPTIONS ] OBJECT { COMMAND }  简化前
#
#        ip -netns NETNS [ OPTIONS ] OBJECT { COMMAND } 简化后
#
#    -a, -all  对所有的对象执行特定命令
#    -c, -collor 颜色控制
#
# OBJECT:
#    link       网络设备(network device)
#    address    设备ip地址(protocol (IP or IPv6) address on a device)
#    addrlabel  协议地址选择的标签配置
#    route      路由表条目(routing table entry)
#    rule       路由策略数据库中的规则
#    token      网卡设置
#
#    netns      管理网络命名空间(manage network namespaces)
#    netconf    管理网络配置
#
#    neighbor   管理ARP缓存条目
#    ntable     管理邻居缓存的操作
#
#    tunnel    ip隧道
#    12tp      IP隧道以太网(L2TPv3)
#    tuntap    管理 TUN/TAP 设备
#
#    maddress  组播地址
#    mroute    组播路由缓存条目
#    mrule     组播路由策略数据库中的规则
#
#    monitor   监听netlink消息
#    xfrm      管理IPSec策略
#
#    tcp_metrics  TCP链接策略
#
#---------------------------------------------------------------------------------------------------

#---------------------------------------------------------------------------------------------------
# ip address {add|change|replace} IFADDR dev IFNAME [ LIFETIME ] [ CONFFLAG-LIST ]
# ip address del IFADDR dev IFNAME [mngtmpaddr]
# ip address {show|save|flush} [ dev IFNAME ] [ scope SCOPE-ID ]
#                              [ to PREFIX ] [ FLAG-LIST ] [ label LABEL ] [up]
# ip address {showdump|restore}
#
# IFADDR := PREFIX | ADDR peer PREFIX
#          [ broadcast ADDR ] [ anycast ADDR ]
#          [ label IFNAME ] [ scope SCOPE-ID ]
#
# SCOPE-ID := [ host | link | global | NUMBER ]
#
# FLAG-LIST := [ FLAG-LIST ] FLAG
#
# FLAG  := [ permanent | dynamic | secondary | primary |
#           [-]tentative | [-]deprecated | [-]dadfailed | temporary |
#           CONFFLAG-LIST ]
#
# CONFFLAG-LIST := [ CONFFLAG-LIST ] CONFFLAG
#
# CONFFLAG  := [ home | nodad | mngtmpaddr | noprefixroute | autojoin ]
#
# LIFETIME := [ valid_lft LFT ] [ preferred_lft LFT ]
#
# LFT := forever | SECONDS
#
#---------------------------------------------------------------------------------------------------

#---------------------------------------------------------------------------------------------------
# 添加virtual link
# ip link add [link DEV] [ name ] NAME
#             [ txqueuelen PACKETS ] # 传输队列的长度
#             [ address LLADDR ]
#             [ broadcast LLADDR ]
#             [ mtu MTU ]
#             [index IDX ] # 索引数
#             [ numtxqueues QUEUE_COUNT ] [ numrxqueues QUEUE_COUNT ] #传输队列数和接收队列数
#             type TYPE [ ARGS ]
#
# ip link delete { DEVICE | dev DEVICE | group DEVGROUP } type TYPE [ ARGS ]
#
# ip link set { DEVICE | dev DEVICE | group DEVGROUP } [ { up | down } ]
#              [ arp { on | off } ]
#              [ dynamic { on | off } ]
#              [ multicast { on | off } ]
#              [ allmulticast { on | off } ]
#              [ promisc { on | off } ]
#              [ trailers { on | off } ]
#              [ txqueuelen PACKETS ]
#              [ name NEWNAME ]
#              [ address LLADDR ]
#              [ broadcast LLADDR ]
#              [ mtu MTU ]
#              [ netns PID ]
#              [ netns NAME ]
#              [ link-netnsid ID ]
#              [ alias NAME ]
#              [ vf NiiUM [ mac LLADDR ]
#                   [ vlan VLANID [ qos VLAN-QOS ] ]
#                   [ rate TXRATE ] ]
#                   [ spoofchk { on | off} ] ]
#                   [ query_rss { on | off} ] ]
#                   [ state { auto | enable | disable} ] ]
#              [ master DEVICE ]
#              [ nomaster ]
#              [ addrgenmode { eui64 | none } ]
#              [ protodown { on | off } ]
#
# ip link show [ DEVICE | group GROUP ] [up] [master DEV] [type TYPE]
#
# ip link help [ TYPE ]
#
# TYPE := { vlan | veth | vcan | dummy | ifb | macvlan | macvtap |
#          bridge | bond | ipoib | ip6tnl | ipip | sit | vxlan |
#          gre | gretap | ip6gre | ip6gretap | vti | nlmon |
#          bond_slave | ipvlan | geneve | bridge_slave | vrf }
#
# TYPE 介绍
#   bridge - Ethernet Bridge device(网桥)
#   bond - Bonding device can - Controller Area Network interface
#   dummy - Dummy network interface(虚拟网络接口)
#   macvlan - Virtual interface base on link layer address (MAC)(基于链路层地址(MAC)的虚拟接口)
#   vcan - Virtual Controller Area Network interface(虚拟控制器区域网络接口)
#   veth - Virtual ethernet interface(虚拟以太网接口)
#   vlan - 802.1q tagged virtual LAN interface
#   vxlan - Virtual eXtended LAN
#   ipip - Virtual tunnel interface IPv4 over IPv4(虚拟隧道接口IPv4 over IPv4)
#   sit - Virtual tunnel interface IPv6 over IPv4(虚拟隧道接口IPv6 over IPv4)
#   gre - Virtual tunnel interface GRE over IPv4(虚拟隧道接口GRE over IPv4)
#   vti - Virtual tunnel interface(虚拟隧道接口)
#   nlmon - Netlink monitoring device(Netlink监控设备)
#
#
#
#
#---------------------------------------------------------------------------------------------------

# 获取公网IP方法

curl http://members.3322.org/dyndns/getip

#或者

wget http://members.3322.org/dyndns/getip