#!/bin/bash

#----------------------------------------------------
# File: memcahed.sh
# Contents: memcached安装
# Date: 19-4-15
#----------------------------------------------------

version=1.5.12
workdir=$(pwd)
installdir=/opt/local/memcached

check_user() {
    if [[ "$(whoami)" != "root" ]];then
        echo
        echo "ERROR: Please use root privileges to execute"
        echo
        exit
    fi
}

download_libevent() {
    url="https://nchc.dl.sourceforge.net/project/levent/release-2.0.22-stable/libevent-2.0.22-stable.tar.gz"

    curl -o libevent.tar.gz ${url}

    rm -rf ${workdir}/libevent && mkdir ${workdir}/libevent && \
    tar -zvxf libevent.tar.gz -C ${workdir}/libevent --strip-components 1
}

install_libevent() {
    # 安装目录
    rm -rf ${installdir} && mkdir -p ${installdir}/libevent

    # 编译
    cd  ${workdir}/libevent && \
    ./configure \
    --prefix=${installdir}/libevent \
    --exec-prefix=${installdir}/libevent

    # 安装
    cpu=$(cat /proc/cpuinfo |grep 'processor'|wc -l)
    make -j${cpu} &&  make install

    # 清理
    cd ${workdir} && rm -rf libevent*
}

download_memcached() {
    prefix="https://memcached.org/files"
    curl -o memcached-${version}.tar.gz "$prefix/memcached-$version.tar.gz"

    tar -zvxf memcached-${version}.tar.gz
}

install_memcached() {
    cd ${workdir}/memcached-${version} && \
    ./configure \
    --prefix=${installdir} \
    --exec-prefix=${installdir} \
    --with-libevent=${installdir}/libevent \
    --enable-64bit

    # 安装
    cpu=$(cat /proc/cpuinfo |grep 'processor'|wc -l)
    make -j${cpu} &&  make install
}

memcached_service() {
    # add user
    if [[ -z "$(cat /etc/group | grep -E '^memcached:')" ]]; then
       groupadd -r memcached
    fi

    if [[ -z "$(cat /etc/passwd | grep -E '^memcached:')" ]]; then
        useradd -r -g memcached -s /sbin/nologin memcached
    fi

    # make dir and copy script
    mkdir -p ${installdir}/etc && \
    mkdir -p ${installdir}/scripts && \
    mkdir -p ${installdir}/run

    cp ${workdir}/memcached-${version}/scripts/start-memcached ${installdir}/scripts

    # add conf
    cat > ${installdir}/etc/memcached.conf << 'EOF'
# memcached default config file
# 2003 - Jay Bonci <jaybonci@debian.org>
# This configuration file is read by the start-memcached script provided as
# part of the Debian GNU/Linux distribution.

# Run memcached as a daemon. This command is implied, and is not needed for the
# daemon to run. See the README.Debian that comes with this package for more
# information.
-d

# Log memcached's output to /opt/local/memcached/run/memcached.log
logfile /opt/local/memcached/run/memcached.log

# Be verbose
# -v

# Be even more verbose (print client commands as well)
# -vv

# Start with a cap of 64 megs of memory. It's reasonable, and the daemon default
# Note that the daemon will grow to this size, but does not start out holding this much
# memory
-m 64

# Default connection port is 11211
-p 11211

# Run the daemon as root. The start-memcached will default to running as root if no
# -u command is present in this config file
-u memcached

# Specify which IP address to listen on. The default is to listen on all IP addresses
# This parameter is one of the only security measures that memcached has, so make sure
# it's listening on a firewalled interface.
-l 127.0.0.1

# Limit the number of simultaneous incoming connections. The daemon default is 1024
-c 1024

# Lock down all paged memory. Consult with the README and homepage before you do this
# -k

# Return error when memory is exhausted (rather than removing items)
# -M

# Maximize core file limit
# -r
EOF

    # link
    ln -sf ${installdir}/bin/memcached /usr/bin/memcached

    # change owner
    chown -R memcached:memcached ${installdir}

    # add start script
    cat > /etc/init.d/memcached << 'EOF'
#!/bin/bash
### BEGIN INIT INFO
# Provides:            memcached
# Required-Start:      $remote_fs $syslog
# Required-Stop:       $remote_fs $syslog
# Should-Start:        $local_fs
# Should-Stop:         $local_fs
# Default-Start:       2 3 4 5
# Default-Stop:        0 1 6
# Short-Description:   Start memcached daemon
### END INIT INFO

# Usage:
# cp /etc/memcached.conf /etc/memcached_server1.conf
# cp /etc/memcached.conf /etc/memcached_server2.conf
# start all instances:
# /etc/init.d/memcached start
# start one instance:
# /etc/init.d/memcached start server1
# stop all instances:
# /etc/init.d/memcached stop
# stop one instance:
# /etc/init.d/memcached stop server1
# There is no "status" command.

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
MEMCACHED=/opt/local/memcached
DAEMON=/usr/bin/memcached
DAEMONBOOTSTRAP=${MEMCACHED}/scripts/start-memcached
DAEMONNAME=memcached
DESC=memcached

test -x ${DAEMON} || exit 0
test -x ${DAEMONBOOTSTRAP} || exit 0

set -e

. /lib/lsb/init-functions


FILES=(${MEMCACHED}/etc/memcached_*.conf)
if [ -r "${FILES[0]}" ]; then
    CONFIGS=()
    for FILE in "${FILES[@]}";
    do
        # remove prefix
        NAME=${FILE#${MEMCACHED}/etc/}
        # remove suffix
        NAME=${NAME%.conf}

        # check optional second param
        if [ $# -ne 2 ]; then
            # add to config array
            CONFIGS+=($NAME)
        elif [ "memcached_$2" == "$NAME" ]; then
            # use only one memcached
            CONFIGS=($NAME)
            break;
        fi;
    done;

    if [ ${#CONFIGS[@]} == 0 ]; then
        echo "Config not exist for: $2" >&2
        exit 1
    fi;
else
    CONFIGS=(memcached)
fi;

er_or=0
CONFIG_NUM=${#CONFIGS[@]}
for ((i=0; i < $CONFIG_NUM; i++)); do
    NAME=${CONFIGS[${i}]}
    PIDFILE="${MEMCACHED}/run/${NAME}.pid"

    case "$1" in
        start)
            echo -n "Starting $DESC: "
            start-stop-daemon --start --quiet --exec "$DAEMONBOOTSTRAP" -- ${MEMCACHED}/etc/${NAME}.conf $PIDFILE
            echo "$NAME."
            echo "$PIDFILE"
           ;;

        stop)
            echo -n "Stopping $DESC: "
            start-stop-daemon --stop --quiet --oknodo --retry 5 --pidfile $PIDFILE --exec $DAEMON
            echo "$NAME."
            rm -f $PIDFILE
            ;;

        restart|force-reload)
            echo -n "Restarting $DESC: "
            start-stop-daemon --stop --quiet --oknodo --retry 5 --pidfile $PIDFILE
            rm -f $PIDFILE
            start-stop-daemon --start --quiet --exec "$DAEMONBOOTSTRAP" -- /etc/${NAME}.conf $PIDFILE
            ;;

        status)
            status_of_proc -p $PIDFILE $DAEMON $NAME
            returnvalue=$(echo $?)
            if [ "$returnvalue" -ne "0" ]; then
                er_or=$(expr $er_or \+ 1)
            fi
            ;;

        *)
            N=/etc/init.d/$NAME
            echo "Usage: $N {start|stop|restart|force-reload|status}" >&2
            exit 1
            ;;
    esac
done;

if [ "$er_or" -ne "0" ]
then
	exit 2
else
	exit 0
fi
EOF

    chmod a+x /etc/init.d/memcached && \
    update-rc.d memcached defaults

    cd ${workdir} && rm -rf memcached-${version}*
}

do_install() {
    check_user
    download_libevent
    install_libevent
    memcached_service
}

do_install
