#!/bin/bash

#----------------------------------------------------
# File: mongodb.sh
# Contents: 安装mongodb服务
# Date: 19-1-18
#----------------------------------------------------

declare -r version=4.2.14
declare -r workdir=$(pwd)
declare -r installdir=/opt/local/mongodb

declare -r SUCCESS=0
declare -r FAILURE=1

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

common_download_tgz() {
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
            return ${FAILURE}
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
        return ${FAILURE}
    fi

    log_info "success to download $name"
    rm -rf ${name} && mkdir ${name}
    tar -zxf ${name}.tar.gz -C ${name} --strip-components 1
    if [[ $? -ne 0 ]]; then
        log_error "$name decopress failed"
        rm -rf ${name} && rm -rf ${name}.tar.gz
        return ${FAILURE}
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

install() {
    apt-get update && \
    apt-get install libssl-dev -y

    getent passwd mongodb >/dev/null 2>&1
    if [[ $? -ne ${SUCCESS} ]]; then
        adduser --system --no-create-home mongodb
        addgroup --system mongodb
        adduser mongodb mongodb
    fi
    if [[ "${version}" > "4.2" ]]; then
        url="https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-ubuntu1804-${version}.tgz"
        common_download_tgz "mongodb" ${url}
    else
        url="https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-${version}.tgz"
        common_download_tgz "mongodb" ${url} axel
    fi

    if [[ $? -ne ${SUCCESS} ]]; then
        return $?
    fi

    rm -rf ${installdir} && \
    mkdir -p ${installdir}/conf && \
    mkdir -p ${installdir}/data && \
    mkdir -p ${installdir}/logs
    cp -r ${workdir}/mongodb/* ${installdir}/
}

add_service() {
    # mongo conf
    read -r -d '' conf <<-'EOF'
# for documentation of all options, see:
#   http://docs.mongodb.org/manual/reference/configuration-options/

# Where and how to store data.
storage:
  dbPath: $dir/data
  directoryPerDB: true
  journal:
    enabled: true
    #engine:
    #mmapv1:
    #wiredTiger:

# where to write logging data.
systemLog:
  destination: file
  logAppend: true
  path: $dir/logs/mongodb.log

# network interfaces
net:
  port: 27017
  bindIp: 127.0.0.1
  unixDomainSocket:
    enabled: true

# how the process runs
processManagement:
  timeZoneInfo: /usr/share/zoneinfo
  fork: true
  pidFilePath: $dir/logs/mongodb.pid

#security:

#operationProfiling:

#replication:

#sharding:

## Enterprise-Only Options:

#auditLog:

#snmp:
EOF

    regex='$dir'
    repl="$installdir"
    printf "%s" "${conf//$regex/$repl}" > ${installdir}/conf/mongodb.conf

    # mongo start script
    read -r -d '' conf <<-'EOF'
#!/bin/bash

### BEGIN INIT INFO
# Provides:          mongodb
# Required-Start:    $local_fs
# Required-Stop:     $local_fs
# Should-Start:      $named
# Default-Start:     2
# Default-Stop:      0 1  3 4 5 6
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
DIETIME=10      # Time to wait for the server to die, in seconds
                # If this value is set too low you might not
                # let some servers to die gracefully and
                # 'restart' will not work

DAEMONUSER=${DAEMONUSER:-mongodb}
DAEMON_OPTS=${DAEMON_OPTS:-"--unixSocketPrefix=$RUNDIR --config $CONF"}

set -e

running_pid() {
    # Check if a given process pid's cmdline matches a given name
    pid=$1
    name=$2
    [ -z "$pid" ] && return 1
    [ ! -d /proc/${pid} ] && return 1
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
    logger "parent pid: $pid"
    running_pid ${pid} ${DAEMON} || return 1
    return 0
}

start_server() {
    test -e "$RUNDIR" || install -m 755 -o mongodb -g mongodb -d "$RUNDIR"
    logger "test status: $?"
    # Start the process using the wrapper
    logger "cmd: ${NUMACTL} ${DAEMON}, args: ${DAEMON_OPTS}"
    start-stop-daemon --background --start --pidfile ${PIDFILE} --make-pidfile \
        --exec ${NUMACTL} ${DAEMON} ${DAEMON_OPTS}
    errcode=$?
    logger "start-stop-daemon status: $errcode"
	return ${errcode}
}

stop_server() {
    # Stop the process using the wrapper
    start-stop-daemon --stop --pidfile ${PIDFILE} \
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
            logger "apparently already running"
            log_end_msg 0
            exit 0
        fi
        if start_server ; then
            logger "start_server $DESC" "$NAME"
            # NOTE: Some servers might die some time after they start,
            # this code will detect this issue if STARTTIME is set
            # to a reasonable value
            logger "sleep: $STARTTIME"
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
        return ${FAILURE}
    fi

    # start
    systemctl daemon-reload > /dev/null 2>/dev/null && \
    service mongod start
    if [[ $? -ne 0 ]]; then
        log_error "service start mongod failed"
        return ${FAILURE}
    fi

    # 测试
    if [[ $(pgrep mongod) ]]; then
        log_info "mongodb install successfully !"
        return ${SUCCESS}
    fi

    return ${FAILURE}
}

clean_file() {
    rm -f ${workdir}/mongodb.tar.gz
    rm -rf ${workdir}/mongodb
}

do_install() {
    check_user
    if [[ $? -ne ${SUCCESS} ]]; then
        return
    fi

    install
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
