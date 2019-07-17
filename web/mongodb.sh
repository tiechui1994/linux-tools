#!/bin/bash

#----------------------------------------------------
# File: mongodb.sh
# Contents: 安装mongodb服务
# Date: 19-1-18
#----------------------------------------------------

version=3.6.9
workdir=$(pwd)
installdir=/opt/share/local/mongodb

command_exists() {
	command -v "$@" > /dev/null 2>&1
}

check_param() {
    if [[ "$(whoami)" != "root" ]]; then
        echo
        echo "ERROR: Please use root privileges to execute"
        echo
        exit
    fi

    if ! command_exists axel; then
        apt-get update && apt-get install axel -y
    fi
}

download_binary() {
    http="https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-${version}.tgz"
    axel -n 100 "${http}" -o mongodb-${version}.tgz

    # 解压源文件
    rm -rf ${installdir} && \
    rm -rf ${workdir}/mongodb && \
    mkdir -p ${workdir}/mongodb

    # 构建mongodb
    mkdir ${workdir}/mongodb-${version} && \
    tar -zvxf mongodb-${version}.tgz -C ${workdir}/mongodb --strip-components 1 && \
    mv ${workdir}/mongodb ${installdir}
}

mongodb_service() {
    # 创建必要的目录
    mkdir -p ${installdir}/conf && \
    mkdir -p ${installdir}/data && \
    mkdir -p ${installdir}/logs

    # 添加conf配置
    cat > ${installdir}/conf/mongodb.conf << EOF
#pid file
pidfilepath=${installdir}/logs/mongodb.pid

#log file
logpath=${installdir}/logs/mongodb.log

#log append
logappend=true

#run as deamon
fork=true

#port
port=27017

#data dir
dbpath=${installdir}/data

#record cpu use
cpu=true

#是否以安全认证方式运行，默认为非安全模式，不进行认证
noauth=true
#auth = true

#详细记录输出
verbose=true

#Enable db quota management
quota=true

# Set oplogging level where n is
#   0=off (default)
#   1=W
#   2=R
#   3=both
#   7=W+some reads
#diaglog=0

#Diagnostic/debugging option 动态调试项
#nocursors=true
#
#Ignore query hints 忽略查询提示
#nohints=true
#
#禁用http界面，默认为localhost:28017
#nohttpinterface=true
#
#关闭服务器端脚本，这将极大的限制功能
#noscripting=true
#
#关闭扫描表，任何查询将会是扫描失败
#notablescan=true
#
#关闭数据文件预分配
#noprealloc=true
#
#为新数据库指定.ns文件的大小,单位:MB
#nssize=
#
#Replication Options 复制选项
#replSet=setname
#
#maximum size in megabytes for replication operation log
#oplogSize=1024
#
#指定存储身份验证信息的密钥文件的路径
#keyFile=/path/to/keyfile
#
EOF

    # 添加service
     cat > /etc/init.d/mongod <<- 'EOF'
#!/bin/sh

### BEGIN INIT INFO
# Provides:   mongod
# Required-Start:    $local_fs $remote_fs $syslog $network ${NAME}d
# Required-Stop:     $local_fs $remote_fs $syslog $network ${NAME}d
# Default-Start:     2 3 4
# Default-Stop:      0 1 5 6
# Short-Description: starts the mongod server
# Description:       starts mongod using start-stop-daemon
### END INIT INFO

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
DAEMON=/opt/share/local/mongodb/bin/mongod
CONF=/opt/share/local/mongodb/conf/mongodb.conf
PID=/opt/share/local/mongodb/logs/mongodb.pid
NAME=mongod
DESC=mongod

test -x ${DAEMON} || exit 0

. /lib/init/vars.sh
. /lib/lsb/init-functions

# Try to extract mongodb pidfilepath
PID=$(cat ${CONF} | grep -Ev '^\s*#' | awk '{ split($0, arr, "="); if ( arr[1]=="pidfilepath" ) print arr[2] }' | head -n1)
if [ -z "${PID}" ]; then
    PID=/run/mongodb.pid
fi

#
# Function that starts the daemon/service
#
do_start()
{
    # Return
    #   0 if daemon has been started
    #   1 if daemon was already running
    #   2 if daemon could not be started
    DAEMON_OPTS="-f ${CONF}"
    start-stop-daemon --start --quiet --pidfile ${PID} --exec ${DAEMON} --test > /dev/null \
        || return 1
    start-stop-daemon --start --quiet --pidfile ${PID} --exec ${DAEMON} -- \
        ${DAEMON_OPTS} 2>/dev/null \
        || return 2
}

#
# Function that stops the daemon/service
#
do_stop()
{
    # Return
    #   0 if daemon has been stopped
    #   1 if daemon was already stopped
    #   2 if daemon could not be stopped
    #   other if a failure occurred
    start-stop-daemon --stop --quiet --retry=TERM/30/KILL/5 --pidfile ${PID} --name ${NAME}
    RETVAL="$?"

    sleep 1

    if [ "${RETVAL}" = "0" ] || [ "${RETVAL}" = "1" ]; then
        if [ -e "${PID}" ]; then
            rm -f ${PID}
        fi
    fi

    return "${RETVAL}"
}

#
# Function that sends a SIGHUP to the daemon/service
#
do_reload() {
    start-stop-daemon --stop --signal HUP --quiet --pidfile ${PID} --name ${NAME}
    return 0
}

case "$1" in
    start)
        [ "${VERBOSE}" != no ] && log_daemon_msg "Starting ${DESC}" "${NAME}"
        do_start
        case "$?" in
            0|1) [ "${VERBOSE}" != no ] && log_end_msg 0 ;;
            2) [ "${VERBOSE}" != no ] && log_end_msg 1 ;;
        esac
        ;;
    stop)
        [ "${VERBOSE}" != no ] && log_daemon_msg "Stopping ${DESC}" "${NAME}"
        do_stop
        case "$?" in
            0|1) [ "${VERBOSE}" != no ] && log_end_msg 0 ;;
            2) [ "${VERBOSE}" != no ] && log_end_msg 1 ;;
        esac
        ;;
    restart)
        log_daemon_msg "Restarting ${DESC}" "${NAME}"

        do_stop
        case "$?" in
            0|1)
                do_start
                case "$?" in
                    0) log_end_msg 0 ;;
                    1) log_end_msg 1 ;; # Old process is still running
                    *) log_end_msg 1 ;; # Failed to start
                esac
                ;;
            *)
                # Failed to stop
                log_end_msg 1
                ;;
        esac
        ;;
    reload)
        log_daemon_msg "Reloading ${DESC} configuration" "${NAME}"
        do_reload
        log_end_msg $?
        ;;
    status)
        status_of_proc -p ${PID} "${DAEMON}" "${NAME}" && exit 0 || exit $?
        ;;
    *)
        echo "Usage: ${NAME} {start|stop|restart|reload|status}" >&2
        exit 3
        ;;
esac

:
EOF

    # 权限
    chmod a+x /etc/init.d/mongod && \
    update-rc.d mongod defaults && \
    update-rc.d mongod disable $(runlevel | cut -d ' ' -f2)

    # 启动
    service mongod start

    # 测试
    if [[ $(pgrep mongod) ]]; then
        echo
        echo "INFO: MongoDB install successfully"
        echo
    fi
}

clean_file() {
    rm -f ${workdir}/mongodb-${version}.tgz
}

do_install() {
    check_param
    download_binary
    mongodb_service
    clean_file
}

do_install