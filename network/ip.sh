#!/usr/bin/env bash


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
#    link       网络设备
#    address    设备ip地址
#    addrlabel  协议地址选择的标签配置
#    route      路由表条目
#    rule       路由策略数据库中的规则
#    token      网卡设置
#
#    netns      管理网络命名空间
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

# 获取公网IP方法

curl http://members.3322.org/dyndns/getip

#或者

wget http://members.3322.org/dyndns/getip