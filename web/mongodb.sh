#!/bin/bash

#----------------------------------------------------
# File: mongodb.sh
# Contents: 安装mongodb服务
# Date: 19-1-18
#----------------------------------------------------

version=3.6.9
workdir=$(pwd)
installdir=/opt/local/mongodb

SUCCESS=0
CMAKE_FAIL=1
MAKE_FAIL=2
INSTALL_FAIL=3
DECOMPRESS_FAIL=4
DOWNLOAD_FAIL=5
INIT_FAIL=6
SERVICE_FAIL=7

# log
log_error(){
    red="\033[97;41m"
    reset="\033[0m"
    msg="[E] $@"
    echo -e "$red$msg$reset"
}
log_warn(){
    yellow="\033[90;43m"
    reset="\033[0m"
    msg="[W] $@"
    echo -e "$yellow$msg$reset"
}
log_info() {
    green="\033[97;42m"
    reset="\033[0m"
    msg="[I] $@"
    echo -e "$green$msg$reset"
}

common_download() {
    name=$1
    url=$2
    cmd=$3

    if [[ -d "$name" ]]; then
        log_info "$name has exist !!"
        return ${SUCCESS} #1
    fi

    if [[ -f "$name.tar.gz" && -n $(file "$name.tar.gz" | grep -o 'POSIX tar archive') ]]; then
        rm -rf ${name} && mkdir ${name}
        tar -zvxf ${name}.tar.gz -C ${name} --strip-components 1
        if [[ $? -ne 0 ]]; then
            log_error "$name decopress failed"
            rm -rf ${name} && rm -rf ${name}.tar.gz
            return ${DECOMPRESS_FAIL}
        fi

        return ${SUCCESS} #2
    fi

    log_info "$name url: $url"
    log_info "begin to donwload $name ...."
    rm -rf ${name}.tar.gz
    command_exists "$cmd"
    if [[ $? -eq 0 && "$cmd" == "axel" ]]; then
        axel -n 10 --insecure --quite -o "$name.tar.gz" ${url}
    else
        curl -C - --insecure --silent ${url} -o "$name.tar.gz"
    fi

    if [[ $? -ne 0 ]]; then
        log_error "download file $name failed !!"
        rm -rf ${name}.tar.gz
        return ${DOWNLOAD_FAIL}
    fi

    log_info "success to download $name"
    rm -rf ${name} && mkdir ${name}
    tar -zxf ${name}.tar.gz -C ${name} --strip-components 1
    if [[ $? -ne 0 ]]; then
        log_error "$name decopress failed"
        rm -rf ${name} && rm -rf ${name}.tar.gz
        return ${DECOMPRESS_FAIL}
    fi

    return ${SUCCESS} #3
}

command_exists() {
	command -v "$@" > /dev/null 2>&1
}

check_user() {
    if [[ "$(whoami)" != "root" ]]; then
        log_error "please use root privileges to execute"
        exit
    fi
}

download_mongodb() {
    url="https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-${version}.tgz"
    common_download "mongodb" ${url} axel
    return $?
}

add_service() {
    # mkdir
    rm -rf ${installdir} && \
    mkdir -p ${installdir}/conf && \
    mkdir -p ${installdir}/data && \
    mkdir -p ${installdir}/logs

    # mongo conf
    read -r -d '' conf <<-'EOF'
#pid file
pidfilepath=$dir/logs/mongodb.pid

#log file
logpath=$dir/logs/mongodb.log

#log append
logappend=true

#run as deamon
fork=true

#port
port=27017

#data dir
dbpath=$dir/data

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

    regex='$dir'
    repl="$installdir"
    printf "%s" "${conf//$regex/$repl}" > ${installdir}/conf/mongodb.cnf

    # mongo start script
    read -r -d '' conf <<-'EOF'
#!/bin/bash

### BEGIN INIT INFO
# Provides:          mongodb
# Required-Start:    $local_fs $syslog
# Required-Stop:     $local_fs $syslog
# Should-Start:      $named
# Should-Stop:
# Default-Start:     2
# Default-Stop:      0 1  3 4 5 6
# Short-Description: An object/document-oriented database
# Description:       MongoDB scripts
### END INIT INFO

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
DAEMON=$dir/bin/mongod
DESC=database

# Default defaults.  Can be overridden by the /etc/default/$NAME
NAME=mongodb
CONF=$dir/conf/mongodb.conf
RUNDIR=$dir/data
PIDFILE=$dir/logs/${NAME}.pid
ENABLE_MONGODB=yes

# Include mongodb defaults if available
if [ -f /etc/default/${NAME} ] ; then
	. /etc/default/${NAME}
fi

# Handle NUMA access to CPUs (SERVER-3574)
# This verifies the existence of numactl as well as testing that the command works
NUMACTL_ARGS="--interleave=all"
if which numactl >/dev/null 2>/dev/null && numactl ${NUMACTL_ARGS} ls / >/dev/null 2>/dev/null
then
    NUMACTL="`which numactl` -- $NUMACTL_ARGS"
    DAEMON_OPTS=${DAEMON_OPTS:-"--config $CONF"}
else
    NUMACTL=""
    DAEMON_OPTS="-- "${DAEMON_OPTS:-"--config $CONF"}
fi

if test ! -x ${DAEMON}; then
    echo "Could not find $DAEMON"
    exit 0
fi

if test "x$ENABLE_MONGODB" != "xyes"; then
    exit 0
fi

. /lib/lsb/init-functions

STARTTIME=1
DIETIME=10                   # Time to wait for the server to die, in seconds
                            # If this value is set too low you might not
                            # let some servers to die gracefully and
                            # 'restart' will not work

DAEMONUSER=${DAEMONUSER:-mongodb}
DAEMON_OPTS=${DAEMON_OPTS:-"--unixSocketPrefix=$RUNDIR --config $CONF run"}

set -e

running_pid() {
# Check if a given process pid's cmdline matches a given name
    pid=$1
    name=$2
    [ -z "$pid" ] && return 1
    [ ! -d /proc/${pid} ] &&  return 1
    cmd=`cat /proc/${pid}/cmdline | tr "\000" "\n"|head -n 1 |cut -d : -f 1`
    # Is this the expected server
    [ "$cmd" != "$name" ] &&  return 1
    return 0
}

running() {
# Check if the process is running looking at /proc
# (works for all users)

    # No pidfile, probably no daemon present
    [ ! -f "$PIDFILE" ] && return 1
    pid=`cat ${PIDFILE}`
    running_pid ${pid} ${DAEMON} || return 1
    return 0
}

start_server() {
            test -e "$RUNDIR" || install -m 755 -o mongodb -g mongodb -d "$RUNDIR"
# Start the process using the wrapper
            start-stop-daemon --background --start --quiet --pidfile ${PIDFILE} \
                        --make-pidfile --chuid ${DAEMONUSER} \
                        --exec ${NUMACTL} ${DAEMON} ${DAEMON_OPTS}
            errcode=$?
	return ${errcode}
}

stop_server() {
# Stop the process using the wrapper
            start-stop-daemon --stop --quiet --pidfile ${PIDFILE} \
                        --retry 300 \
                        --user ${DAEMONUSER} \
                        --exec ${DAEMON}
            errcode=$?
	return ${errcode}
}

force_stop() {
# Force the process to die killing it manually
	[ ! -e "$PIDFILE" ] && return
	if running ; then
		kill -15 ${pid}
	# Is it really dead?
		sleep "$DIETIME"s
		if running ; then
			kill -9 ${pid}
			sleep "$DIETIME"s
			if running ; then
				echo "Cannot kill $NAME (pid=$pid)!"
				exit 1
			fi
		fi
	fi
	rm -f ${PIDFILE}
}


case "$1" in
  start)
	log_daemon_msg "Starting $DESC" "$NAME"
        # Check if it's running first
        if running ;  then
            log_progress_msg "apparently already running"
            log_end_msg 0
            exit 0
        fi
        if start_server ; then
            # NOTE: Some servers might die some time after they start,
            # this code will detect this issue if STARTTIME is set
            # to a reasonable value
            [ -n "$STARTTIME" ] && sleep ${STARTTIME} # Wait some time
            if  running ;  then
                # It's ok, the server started and is running
                log_end_msg 0
            else
                # It is not running after we did start
                log_end_msg 1
            fi
        else
            # Either we could not start it
            log_end_msg 1
        fi
	;;
  stop)
        log_daemon_msg "Stopping $DESC" "$NAME"
        if running ; then
            # Only stop the server if we see it running
			errcode=0
            stop_server || errcode=$?
            log_end_msg ${errcode}
        else
            # If it's not running don't do anything
            log_progress_msg "apparently not running"
            log_end_msg 0
            exit 0
        fi
        ;;
  force-stop)
        # First try to stop gracefully the program
        $0 stop
        if running; then
            # If it's still running try to kill it more forcefully
            log_daemon_msg "Stopping (force) $DESC" "$NAME"
			errcode=0
            force_stop || errcode=$?
            log_end_msg ${errcode}
        fi
	;;
  restart|force-reload)
        log_daemon_msg "Restarting $DESC" "$NAME"
		errcode=0
        stop_server || errcode=$?
        # Wait some sensible amount, some server need this
        [ -n "$DIETIME" ] && sleep ${DIETIME}
        start_server || errcode=$?
        [ -n "$STARTTIME" ] && sleep ${STARTTIME}
        running || errcode=$?
        log_end_msg ${errcode}
	;;
  status)

        log_daemon_msg "Checking status of $DESC" "$NAME"
        if running ;  then
            log_progress_msg "running"
            log_end_msg 0
        else
            log_progress_msg "apparently not running"
            log_end_msg 1
            exit 1
        fi
        ;;
  # MongoDB can't reload its configuration.
  reload)
        log_warning_msg "Reloading $NAME daemon: not implemented, as the daemon"
        log_warning_msg "cannot re-read the config file (use restart)."
        ;;

  *)
	N=/etc/init.d/${NAME}
	echo "Usage: $N {start|stop|force-stop|restart|force-reload|status}" >&2
	exit 1
	;;
esac

exit 0
EOF

    regex='$dir'
    repl="$installdir"
    printf "%s" "${conf//$regex/$repl}" > /etc/init.d/mongod

    # chmode
    chmod a+x /etc/init.d/mongod && update-rc.d mongod defaults
    if [[ $? -ne 0 ]]; then
        log_error "update-rc failed"
        return ${SERVICE_FAIL}
    fi

    # start
    systemctl daemon-reload && service mongod start
    if [[ $? -ne 0 ]]; then
        log_error "service start mongod failed"
        return ${SERVICE_FAIL}
    fi

    # 测试
    if [[ $(pgrep mongod) ]]; then
        log_info "mongodb install successfully !"
        return ${SUCCESS}
    fi

    return ${SERVICE_FAIL}
}

clean_file() {
    rm -f ${workdir}/mongodb.tar.gz
    rm -f ${workdir}/mongodb
}

do_install() {
    check_user
    if [[ $? -ne ${SUCCESS} ]]; then
        return
    fi

    download_mongodb
    if [[ $? -ne ${SUCCESS} ]]; then
        return
    fi

    add_service
    if [[ $? -ne ${SUCCESS} ]]; then
        return
    fi

    clean_file
}

do_install