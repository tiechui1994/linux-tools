#!/bin/bash

#----------------------------------------------------
# File: systemd-journalctl.sh
# Contents: journalctl
# Date: 19-6-5
#----------------------------------------------------

#---------------------------------------------------------------------------------------------------
# journal.conf
#
# Storage=
# 在哪里存储日志文件. "volatile" 表示仅保存在内存中, 也就是保存在/run/log/journal目录中(将会被自动按需创建).
# "persistent" 表示优先保存在磁盘上, 也就是保存在/var/log/journal目录中(将会被自动按需创建), 但若失败(例如在系统启
# 动早期/var尚未挂载), 则转而保存在/run/log/journal目录中(将会被自动按需创建). "auto" 与 "persistent" 类似, 但
# 不自动创建/var/log/journal目录, 因此可以根据该目录的存在与否决定日志保存位置. "none", 表示不保存任何日志. 默认值是
# "auto"
#
# SplitMode=
# 设置是否按照每个用户分割日志文件, 以实现对日志的访问控制. 分割策略: "uid" 表示每个用户都有自己专属的日志文件, 但系统
# 用户的日志依然记录到系统日志中. 这是默认值. "none"表示不对日志文件按用户进行分割, 而是将所有的日志都记录到系统日志中.
# 注意: 仅分割持久保存的日志(/var/log/journal), 永不分割内存中的日志(/var/run/journal)
#
# RateLimitIntervalSec=, RateLimitBurst=
# 限制日志的生成速度(0表示不做限制). RateLimitIntervalSec设置一个时间段, 默认是30秒. RateLimitBurst设置一个正整数,
# 表示消息条数, 默认值是1000条. 表示在RateLimitIntervalSec时间内,每个服务最多允许产生RateLimitBurst数量(条数)的日
# 志. 在同一个时间段内, 超出数量限制的日志将被丢弃, 直到下一个时间段再次开始记录. 对于所有被丢弃的日志消息, 仅用一条类似
# "xxx条消息被丢弃"的消息来替代. RateLimitIntervalSec时间单位: "ms", "s", "min", "h", "d"
#
# SystemMaxUse=, SystemKeepFree=, SystemMaxFileSize=, SystemMaxFiles=
# RuntimeMaxUse=, RuntimeKeepFree=, RuntimeMaxFileSize=, RuntimeMaxFiles=
# 限制日志文件的大小上下限. 以"System" 开头的选项用于限制磁盘使用量. 即/var/log/journal的使用量. 以"Runtime"开头的
# 选项用于限制内存使用量, 即/run/log/journal的使用量.
# 以"System"开头的选项仅在/var/log/journal目录确实存在且可写时才有意义. 以"Runtime"开头的选项永远有意义.
# SystemMaxUse= 与 RuntimeMaxUse= 限制全部日志文件加在一起最多可以占用的空间. SystemKeepFree= 与 RuntimeKeepFree=
# 表示除日志文件之外, 至少保留多少空间给其他用途. systemd-journald会同时考虑两个因素, 并且尽量限制日志文件的总大小, 以
# 同时满足这两个条件.
# SystemMaxUse= 与 RuntimeMaxUse= 的默认值是10%空间与4G两者中较小者. SystemKeepFree= 与 RuntimeKeepFree= 的
# 默认值是15%空间与4G两者中较大者. 如果在systemd-journald启动时, 文件系统即将被填满并且已经超越了SystemKeepFree=
# 或 RuntimeKeepFree= 的限制, 那么日志记录将被暂停.
# SystemMaxFileSize= 与 RuntimeMaxFileSize= 限制单个文件的最大体积, 到达此限制后日志文件将会自动回滚. 默认值是对
# 应的SystemMaxUse= 与 RuntimeMaxUse值的1/8.
# SystemMaxFiles= 与 RuntimeMaxFiles= 限制最多允许同时存在多少个日志文件, 超出此限制后, 最老的文件将被删除. 默认是
# 100
#
# SyncIntervalSec=
# 向磁盘刷写日志文件的时间间隔, 默认是5min. 刷写之后, 日志文件将处于离线(OFFLINE)状态. 注意, 当收到CRIT, ALERT,
# EMERG级别的日志消息后, 将会无条件的立即刷写日志文件. 因此该设置仅对ERR, WARNING, NOTICE, INFO, DEBUG级别的日志
# 消息有意义.
#
# ForwardToSyslog=, ForwardToKMsg=, ForwardToConsole=, ForwardToWall=,
# ForwardToSyslog= 表示是否将接收到的日志消息转发给syslog守护进程, 默认值是"no"
# ForwardToKMsg= 表示是否将接收到的消息转发给内核日志缓冲区(kmsg), 默认值是"no"
# ForwardToConsole= 表示是否将接收到的消息转发给系统控制台, 默认值是"no". 设置成yes需要指定TTYPath= 指定转发目标
# ForwardToWall= 表示是否将接收到的消息转发给所有已登录用户 默认值是"yes"
#
# TTYPath=
# 指定 ForwardToConsole=yes 时所使用的控制台TTY, 默认值是 /dev/console
#---------------------------------------------------------------------------------------------------


#---------------------------------------------------------------------------------------------------
# journalctl
# systemd启动方式下的日志
#
#   --no-full, --full
#   默认是--full, 显示完整字段. --no-full表示允许内容被truncated(超过一定长度,会被截断)
#
#   -f, --follow
#   仅显示最新的日志分录, 并在将新添加到日志当中的记录打印出来[日志监控].
#
#   -e, --page-end
#   立即跳到日志文件的末尾.
#
#   -n, --lines=num
#   显示最新的num条日志记录. 如果使用--follow, 则隐含此选项. 参数是正整数或"全部"以禁用行限制. 如果没有给出参数,
#   则默认值为10.
#
#   -r, --reverse
#   反向输出, 以便首先显示最新的条目.
#
#   -o, --output=
#   设置显示的日志记录的格式. 采取以下选项之一:
#   - short 默认值,该输出与经典系统日志文件的格式大致相同, 每个日志记录显示一行.
#   - short-iso 类似short, 只是时间使用ISO 8601格式
#   - short-precise 类似short, 只是时间精确到毫秒
#   - cat (查看日志推荐使用) 生成一个非常简洁的输出, 只显示每个日记条目的实际消息,没有元数据,甚至没有时间戳.
#
#   -k, --dmesg
#   仅显示内核消息. 这意味着-b并添加匹配"_TRANSPORT=kernel".
#
#   -t, --identifier=SYSLOG_IDENTIFIER
#   显示指定的syslog标识符SYSLOG_IDENTIFIER的消息. 可以多次指定此参数.
#
#   -u, --unit=UNIT|PATTERN
#   显示指定系统单元UNIT(例如服务单元)或PATTERN匹配的任何单元的消息. 如果指定了模式, 则会将日志中找到的UNIT名称列表与
#   指定的模式进行比较, 并使用所有匹配项. 对于每一个匹配的项, 隐式使用 "_SYSTEMD_UNIT=UNIT"选项
#
#   参数可以多次使用.
#
#   --user-unit=UNIT
#   显示指定用户的session unit日志. 隐式使用参数 "_SYSTEMD_USER_UNIT=UNIT" 和 "_UID=UID"
#
#   -p, --priority=
#   按日志优先级或优先级范围进行过滤. 采用数字或字符串日志级别(即介于0/"emerg" 和 7/"debug"之间), 或采用FROM..TO的
#   格式设置日志的级别. 例如: "2..7" 或者 "crit..debug"
#   日志级别是syslog中记录的常见syslog日志级别, 即"emerg"(0), "alert"(1), "crit"(2), "err"(3), "warning"(4)
#   "notice"(5), "info"(6), "debug"(7). 如果指定了单个日志级别, 则会显示具有此日志级别和低于此日志级别的所有消息.
#   如果指定了范围, 则会显示该范围内的所有消息, 包括范围的开始值和结束值. 这将为指定的优先级添加"PRIORITY="匹配.
#
#
#   -S, --since=, -U, --until=
#   日期规格的格式应为"2012-10-30 18:17:16". 如果省略时间部分, 则假定为"00:00:00". 如果仅省略秒部分,则假定为0秒.
#   如果省略日期部分, 则假定当前日期. 或者, 可以理解字符串"yesterday", "today", "tomorrow", 它们分别指当前一天,
#   当前日期或后一天. "now"是指当前时间. 最后, 可以指定相对时间, 前缀为"-"或"+", 分别指当前时间之前或之后的时间.
#
#   --system, --user
#   显示来自系统服务和内核的消息(使用--system). 显示当前用户服务的消息(使用--user). 如果未指定, 则显示用户可以看到的
#   所有消息.
#
#   --sync
#   要求日志守护程序将所有未写入的日志数据写入备份文件系统并同步所有日志. 在同步操作完成之前, 此调用不会返回. 此命令保证
#   在调用之前写入的任何日志消息在返回时安全地存储在磁盘上.
#
#   --flush
#   如果启用了持久存储, 则要求日志后台程序将存储在/run/log/journal中的日志数据flush到/var/log/journal中. 在操作完
#   成之前, 此调用不会返回.
#   请注意, 此调用是幂等的: 在系统运行期间, 数据仅从/run/log/journal刷新到/var/log/journal一次, 并且如果已经发生
#   此命令, 则此命令将退出而不执行任何操作. 此命令有效地保证在返回时将所有数据刷新到/var/log/journal.
#
#   --rotate
#   要求日志守护程序切割日志文件. 在切割操作完成之前, 此调用不会返回. (默认是128M进行切割)
#
#   --disk-usage
#   显示所有日志文件的当前磁盘使用情况. 这显示了所有已存档和活动日志文件的磁盘使用情况的总和.
#
#   --vacuum-size=, --vacuum-time=, --vacuum-files=
#   删除已归档的日志文件, 直到它们使用的磁盘空间低于指定的大小(单位是"K","M","G"和"T"), 或者所有日志文件都不包含早于
#   指定时间跨度的数据(单位是"s", "min", "h", "days", "months", "week"和"years"), 或者不超过指定数量的日志文件.
#
#   请注意, 运行'--vacuum-size=' 仅对 '--disk-usage' 显示的输出产生间接影响, 因为后者包括活动日志文件, 而清理操作
#   仅对归档日记文件执行操作.
#   同样 '--vacuum-files=' 实际上可能不会将日志文件的数量减少到指定的数量以下, 因为它不会删除活动的日志文件.
#
#   '--vacuum-size=', '--vacuum-time=' 和 '--vacuum-files=' 可以在一次调用中组合, 以对存档的日志文件强制执行
#   大小,时间和文件数量限制的任意组合. 将这三个参数中的任何一个指定为零等效于不强制执行特定限制, 因此是多余的.
#
#---------------------------------------------------------------------------------------------------