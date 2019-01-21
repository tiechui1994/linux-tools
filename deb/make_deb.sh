#!/bin/bash

#----------------------------------------------------
# File: make_deb.sh
# Contents: Created by root on 19-1-21.
# Date: 19-1-21
#----------------------------------------------------

#
# deb包的文件结构:
#   deb包里面的结构, DEBIAN目录和具体安装目录(模拟安装目录, 如etc, usr, opt, tmp等).
#
#   在DEBIAN目录至少有control文件, 还可能有postinst(postinstallation),
#   postrm(postremove), preinst(preinstallation), prerm(preremove), copyright(版权),
#   changelog(修订目录) 和 conffiles等.
#
#   control文件: 描述软件包的名称(Package), 版本(Version), 描述(Description)等. 是deb包必须
#   具备的描述性文件, 以便于软件的安装和索引.
#       Package: 软件名称
#       Version: 软件版本
#       Description: 软件描述
#       Section: 申明软件的类别, 常见的有 'utils', 'net', 'mail', 'text', 'x11'等
#       Priority: 申明软件对于系统的重要程度, 'required', 'standard', 'optional', 'extra'等.
#       Essential: 申明是否是系统最基本的软件包(选项为yes/no).
#       Architecture: 软件包结构. 'i586', 'amd64', 'powerpc'等.
#       Source: 软件包的源代码名称.
#       Depends: 软件所依赖的其他软件包和库文件. 如果是依赖多个软件包和库文件, 彼此之间采用逗号隔开.
#       Pre-Depends: 软件安装前必须安装,配置依赖性的软件饱和库文件, 它常常用于必须的预运行脚本需求.
#       Recommends: 推荐安装的其他软件包和库文件.
#       Suggests: 建议安装的其他软件和库文件.
#       Install-Size: 安装大小
#       Maintainer: 联系人邮箱
#       Provides: 提供商
#
#
# 案例:
# Package: software
# Version: 1.8.10
# Section: free
# Priority: optional
# Depends: libssl.0.0.so, libstdc++2.10-glib2.2
# Suggests: Openssl
# Architecture: i386
# Install-Size: 10240
# Maintainer: sun
# Provides: Sun
# Description: test openssl
#            (此处必须空一行再结束)
#
#
#   postinst文件: 包含了软件在正常目录拷贝到系统后,所需要执行的配置工作
#   prerm: 软件卸载前需要执行的脚本.
#   postrm: 软件卸载后需要执行的脚本.
#
#
# 文件目录:
#   software
#   |----DEBIAN
#        |----control
#        |----postinst
#        |----postrm
#   |----xxx
#        |----binary-sofware
#
#
#   xxx 表示安装后的文件的目录, software目录对应文件的根目录.