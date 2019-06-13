#!/bin/bash

#----------------------------------------------------
# File: ${NAME}
# Contents: root
# Date: 6/12/19
#----------------------------------------------------


#---------------------------------------------------------------------------------------------------
#
# auto eth0
# 以"auto"开头的行用于标识使用-a选项运行ifup时要启动的物理接口. (此选项由系统引导脚本使用.) 物理接口名称应在同
# 一行上的"auto"后面. 可以有多个"auto"节. ifup按所列顺序启动命名接口.
#
# allow-hotplug eth1
# 以"allow-"开头的行用于标识由各种子系统自动启动的接口. 这可以使用诸如"ifup --allow=hotplug eth0 eth1"之类的命
# 令来完成, 如果它在"allow-hotplug"行中列出, 则只会显示eth0或eth1. 请注意, "allow-auto"和"auto"是同义词.
#
# no-auto-down
# 以"no-auto-down"开头的行用于标识不应被命令"ifdown -a"关闭的接口. 它的主要用途是防止在系统关闭期间关闭接口, 例如,
# 如果根文件系统是网络文件系统, 那么网络接口应该一直保持. 请注意, 仍然可以通过明确指定接口名称来关闭接口.
#
# no-scripts
# 以"no-scripts"开头的行用于标识当这些接口启动或关闭时不应运行/etc/network/if-*.d/中的脚本的接口.
#
# source interfaces.d/machine-dependent
# 以"source"开头的行用于包含来自其他文件的节, 因此可以将配置拆分为多个文件. "source"后跟要获取的文件路径. 可以使用
# Shell通配符.
#---------------------------------------------------------------------------------------------------


#---------------------------------------------------------------------------------------------------
# iface
#
# interface template:
#   iface ethernet inet static
#       mtu 1500
#       hwaddress 11:22:33:44:55:66
#
#
#   iface eth0 inet static inherits ethernet
#       address 192.168.1.2/24
#
#
#
# vlan and bridge interface:
#   为了简化VLAN interface的配置, interface名称中包含"."的配置为802.1q标记的VLAN interface.
#   例如, interface eth0.1是具有eth0作为物理网卡的虚拟 interface, VLAN ID为1.
#
#   为了与bridge-utils软件包兼容. 如果指定了bridge_ports选项, 则不执行VLAN interface配置.
#
#
# iface option:
#   以下"command"选项适用于每个family和method. 这些选项中的每一个都可以在一个节中多次给出, 在这种情况下, 命令按照它
# 们在节中出现的顺序执行.(可以通过使用"||true"后缀来确保命令永不失败.)
#
#   pre-up command 在启动interface之前运行命令. 如果此命令失败, 则ifup将中止, 并打印错误消息, 并以状态0退出.
#
#   up command
#
#   post-up command  启动interface后运行命令. 如果此命令失败, 则ifup中止, 不会将interface标记为已配置(即使它已
#   真正配置), 打印错误消息, 并退出状态0.
#
#   pre-down command 停止interface前运行命令. 如果此命令失败, 则ifdown中止, 将interface标记为未配置(即使它已真
#   正配置), 打印错误消息, 并退出状态0.
#
#   down command
#
#   post-down command 停止interface后运行命令. 如果此命令失败, 则ifdown中止, 将interface标记为未配置. 打印错误
#   消息, 并退出状态0.
#
#   对于上述每个选项, 在选项执行之后, 在目录/etc/network/if-<option>.d/的script会被运行(没有参数). 请注意, 由于
#   post-up和pre-down是别名, 改用if-up.d和if-down.d目录替代.
#
#   所有这些命令都可以访问以下环境变量.
#   IFACE  正在处理的接口的物理名称
#   LOGICAL  正在处理的接口的逻辑名称
#   METHOD interface的方法, 例如: static
#
#
# INET address family:
#   lookback Method: 该方法可用于定义IPv4环回接口.
#
#   static Method: 此方法可用于定义具有静态分配的IPv4地址的以太网接口.
#       address addr                本地ip地址, 必须
#       network addr                网络地址
#       netmask mask                网络掩码
#       broadcast broadcast_addr    广播地址
#       metric  metric              默认网关的路由数量(整数)
#       gateway addr                网关地址
#       pointopoint addr
#       harddress hardaddr          MAC地址或"random"
#       mtu size                    MTU(最大传输单元), 一般是1500
#
#   manual Method: 此方法可用于定义默认情况下不进行任何配置的接口. 可以通过up和down命令或/etc/network/if-*.d脚本
#   手动配置此类接口.
#       harddress hardaddr          MAC地址或"random"
#       mtu size                    MTU(最大传输单元), 一般是1500
#
#   dhcp Method: 此方法可用于通过DHCP使用其他工具获取地址: dhclient, pump, udhcpc, dhcpcd. (它们已按其优先顺序
#   列出). 如果你有一个复杂的DHCP设置, 你应该注意到其中一些客户端使用自己的配置文件, 并且不通过ifup获取DHCP配置信息.
#       hostname hostnam            主机名称(针对工具pump,dhcpd,udhcpc)
#       metric metric               默认网关的路由数量(整数)(dhclient)
#       leasehours  leasehours      租赁的时间(小时)(pump)
#       leasetime  leasetime        租赁的时间(秒)(dhcpcd)
#       vendor  vendor              供应商类标识符(dhcpcd)
#       client  client              客户端标识符(dhcpcd)
#       harddress hardaddr          MAC地址
#
#   bootp Method: 该方法可用于通过bootp获得地址.
#       bootfile file               告诉server使用file作为引导文件.
#       server  address             使用IP地址与服务器通
#       hwaddr  addr                使用addr作为硬件地址而不是实际的硬件地址.
#
#   tunnel Method: 此方法用于创建GRE或IPIP隧道. 需要从iproute package中获得ip二进制文件. 对于GRE隧道, 需要加载
#   ip_gre模块, 对于IPIP隧道, 需要加载ipip模块.
#       address addr                本地ip地址, 必须
#       mode type                   隧道模式(GRE,IPIP), 必须
#       endpoint addr               其他隧道endpoint的地址, 必须
#       dstaddr addr                远程地址(隧道内的远程地址)
#       local addr                  本地endpoint地址
#       metric metric               默认网关的路由数量(整数)
#       gateway addr                网关地址
#       ttl time
#       mtu size
#---------------------------------------------------------------------------------------------------

#---------------------------------------------------------------------------------------------------
# 案例:
# auto eth0
# iface eth0 inet static
#     address 192.168.1.42/25
#     up route add -net 192.168.1.128 netmask 255.255.255.128 gw 192.168.1.2
#     up route add default gw 192.168.1.200
#     down route del default gw 192.168.1.200
#     down route del -net 192.168.1.128 netmask 255.255.255.128 gw 192.168.1.2
#
#---------------------------------------------------------------------------------------------------