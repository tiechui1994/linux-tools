#!/bin/bash

#----------------------------------------------------
# File: ${FILE}
# Contents: 
# Date: 8/16/19
#----------------------------------------------------


#---------------------------------------------------------------------------------------------------
# 构建rpm包
#
# 目录结构:
# rpmbuild
#   |- BUILD
#   |- RPMS
#   |- SOURCES
#   |- SPECS
#   |- SRPMS
#
# 目录        宏代码          默认位置                名称和用途
# SPECS      %_specdir      ~/rpmbuild/SPECS       Spec文件目录, 保存RPM包配置(.spec)文件
# SOURCES    %_sourcedir    ~/rpmbuild/SOURCES     源代码目录, 保存源代码包(如.tar包)和所有patch补丁
# BUILD      %_builddir     ~/rpmbuild/BUILD       构建目录,  源代码被解压缩至此, 并在该目录的子目录完成编译
# BUILDROOT  %_buildrootdir ~/rpmbuild/BUILDROOT   最终安装目录, 保存%install阶段安装的文件
# RPMS       %_rpmdir       ~/rpmbuild/RPMS        标准RPM包目录, 生成/保存二进制RPM包
# SRPMS      %_srpmdir      ~/rpmbuild/SRPMS       源代码RPM包目录, 生成/保存源码RPM包(SRPM)
#
#
# 打包流程:
# - 源代码放到`%_sourcedir`中.
# - 编译, 编程过程再 `%_builddir` 中完成, 所以需要先把源代码复制到此目录下, 一般情况下, 源代码是压缩包格式, 那么就解
# 压过来即可.
# - 安装, 类似预先组装软件包, 把软件包应该包含的内容(比如二进制文件, 配置文件, man文档等)复制到 `%_buildrootdir`中,
# 并按照安装后的目录结构组装.
# - 配置一些必要的工作. 实际安装前, 安装后, 卸载前, 卸载后的脚本
# - 检查软件是否正常运行(可选操作)
# - 生成RPM包放置到 `%_rpmdir`, 源码包放置到 `%_srpmdir`
#
#---------------------------------------------------------------------------------------------------


#---------------------------------------------------------------------------------------------------
# SPEC文件
#
# 构建阶段说明:
# 阶段       读取的目录      写入的目录        动作
# %prep     %_sourcedir    %_builddir      读取%_sourcedir目录的源代码. 之后解压至%_builddir的子目录
# %build    %_builddir     %_builddir      编译位于%_builddir构建目录下的文件. 通过指向类似于./configure && make的命令实现
# %install  %_builddir     %_buildrootdir  读取%_builddir构建目录下的文件并将其安装至%buildrootdir目录. 这些文件就是用户安装RPM后, 最终得到的文件. 通过类似make install的命令实现.
# %check    %_builddir     %_builddir      检查软件是否正常运行. 通过执行类似make test的命令实现.(可选的)
# bin       %_buildrootdir %_rpmdir        读取%_buildrootdir最终安装目录下的文件, 以便最终再%_rpmdir目录下创建RPM包
# src       %_sourcedir    %_srpmdir       创建源码RPM包(SRPM, 以.src.rpm为后缀名), 并保存至%_srpmdir目录.
#
#
# Name: hello                  // 软件包名, 应该与SPEC文件名一致.
# Version: 2.10                // 版本号
# Release: 1                   // 发型版本
# Summary: Summary             // 剪短介绍. 请勿在结尾使用标点"!"
# License: License             // 授权协议, 必须是开源许可证. GPLv2+, BSD
# Source: %{name}-%{version}.tar.gz    // 软件源码包的URL地址. 文件名用于查找SOURCES目录. 建议使用 %{name}和%{version}替换URL中的名称/版本
# URL: http://www.url.com              // 软件包的项目主页. 注意: 源码包URL请使用Source0指定
# BuildArch: amd64                     // 架构
# BuildRequires: gettext               // 编译软件包所需的依赖列表
# Requires:                            // 安装软件包所需的依赖包列表
#
# %description                         // 程序详细描述
# description
#
# %prep                                // 打包准备阶段执行一些命令
# %autosetup -n %{name}
#
# %build                               // 包含构建阶段执行的命令
# %configure
# make %{?_smp_mflags}
#
# %install                             // 包含安装阶段执行的命令
# make install DESTDIR=%{buildroot}
# %find_lang %{name}
# rm -f %{buildroot}/%{_infodir}/dir
#
# %check                               // 包含测试阶段执行的命令
#
# %clean                               // 清理安装目录的命令
# rm -rf %{buildroot}
#
# %files -f %{name}.lang               // 需要被打包/安装的文件列表.
# %doc   AUTHORS ChangeLog README      // %doc用于列出%{_builddir}内, 但不复制到%{buildroot}中的文档. 通常包括README和INSTALL等. 它们会保存至/usr/share/doc下适当的目录中,不需要声明/usr/share/doc的所有权限
# %{_mandir}/*
# %{_infodir}/*
# %{_bindir}/hello
#
#
# 说明:
# %prep 描述解压源码包的方法. 一般而言, 其中包含%autosetup命令. 另外, 还可以使用%setup和%patch命令来指定操作Source0
# Patch0等标签文件.
#
# - %autosetup命令用于解压源码包.
#  "-n name", 如果源码包解压后的目录名称与RPM名称不通,次选择用于指定正确的目录名称. 例如, 如果tarball解压目录为FOO,
#  则使用"%autosetup -n FOO"
#  "-c name", 如果源码包解压后包含多个目录, 而不是单个目录时, 此选项可以创建名为name的目录, 并在其中解压.
#
# - %setup, 通常使用-q抑制不必要的输出.
#
# - %patch
#
#
# %build 读解压到%_builddir下的源码进行编译阶段, 整个过程在该目录下完成.
# 许多程序使用GNU configure进行配置. 默认情况下, 文件会安装到前缀为"/usr/local"的路径下. 然而,打包时需要修改前缀为
# "/usr". 共享库路径视架构而定, 安装至/usr/lib 或者 /usr/lib64目录.
# %configure
# make %{?_smp_mflags} //
# make %{?_smp_mflags} CFLAGS="%{optflags}" BINDIR=%{_bindir} //
#
#
# %install 安装
# #自动安装
# %install
# rm -rf %{buildroot}
# make install DESTDIR=%{buildroot}
#
# #手动执行安装
# %install
# rm -rf %{buildroot}
# mkdir -p %{buildroot}%{_bindir}/
# cp -p command %{buildroot}%{_bindir}/
#
#
# %files, 列出了需要被打包的文件和目录
# %files基础:
#    %defattr用于设置默认文件权限, 通常可以再%files的开头看到. 注意, 如果不修改权限, 则不需要使用它. 格式为:
# %defattr(<文件权限>, <用户>, <用户组>, <目录权限>). 常规用法为 %defattr(-,root,root,-), 其中 "-" 表示默认权限.
#
# 配置文件保存再/etc中, 一般会这样指定(确保用户的修改不会再更新时被覆盖):
# %config(noreplace)  %{_sysconfdir}/foo.conf
#
# 如果更新的配置文件无法与之前的配置兼容, 这样指定:
# %config  %{_sysconfdir}/foo.conf
#
# 如果包含特定语言编写的文件, 请使用%lang来标注:
# %lang(de)  %{_datadir}/locale/de/LC_MESSAGES/tcsh*
#
# 使用区域语言(Locale)文件的程序应遵循i18n文件的建议方法:
# - 在%install步骤中找到文件名: %find_lang ${name}
# - 添加必要的编译依赖: BuildRequires: gettext
# - 使用找到的文件名: %files -f ${name}.lang
#
# 宏列表:
# %{_sysconfdir}  /etc
# %{_prefix}      /usr
#
# %{_includedir}  %{_prefix}/include
# %{_datarootdir} %{_prefix}/share
# %{_datadir}     %{_datarootdir}
#
# %{_exec_prefix} %{_prefix}
# %{_bindir}      %{_exec_prefix}/bin
# %{_libdir}      %{_exec_prefix}/lib
# %{_libexecdir}  %{_exec_prefix}/libexec
# %{_sbindir}     %{_exec_prefix}/sbin
#
# %{_var}      /var
# %{_tmppath}  %{_var}/tmp
#
# %{_usr}     /usr
# %{_usrsrc}  %{_usr}/src
#
# %{_sharedrootdir}  /var/lib
#
# %{_infodir}        /usr/share/info
# %{_mandir}         /usr/share/man
# %{_localstatedir}  /usr/share/info
#
# %{buildroot}      %{_buildrootdir}/%{name}-%{version}-%{release}.%{_arch}
#
#
# 安装/卸载脚本. 如果在脚本片段中执行任何程序, 就必须以Requires(CONTXT), 例如: Requires(post) 的形式列出所有依赖
# 在软件安装之前(%pre) 或 之后(%post)执行
# 在软件卸载之前(%preun) 或 之后 (%postun) 执行
#
#---------------------------------------------------------------------------------------------------

#---------------------------------------------------------------------------------------------------
# 构建 SRPM 和 RPM 包:
# rpmbuild -ba hello.spec
#
# 重新从%install阶段开始编译:
# rpmbuild -bi --short-circuit hello.spec
#
# 只构建 RPM 包
# rpmbuild -bb hello.spec
#
# 只构建 SRPM 包
# rpmbuild -bs hello.spec
#---------------------------------------------------------------------------------------------------