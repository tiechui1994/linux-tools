#!/bin/bash

#----------------------------------------------------
# File: memcahed.sh
# Contents: memcached安装
# Date: 19-4-15
#----------------------------------------------------

version=1.5.12
workdir=$(pwd)
installdir=/opt/local/memcached

declare -r success=0
declare -r failure=1

# log
log_error(){
    red="\033[31;1m"
    reset="\033[0m"
    msg="[E] $@"
    echo -e "$red$msg$reset"
}
log_warn(){
    yellow="\033[33;1m"
    reset="\033[0m"
    msg="[W] $@"
    echo -e "$yellow$msg$reset"
}
log_info() {
    green="\033[32;1m"
    reset="\033[0m"
    msg="[I] $@"
    echo -e "$green$msg$reset"
}

download() {
    name=$1
    url=$2
    cmd=$3
    decompress=$4

    declare -A extends=(
        ["tar"]="application/x-tar"
        ["tgz"]="application/gzip"
        ["tar.gz"]="application/gzip"
        ["tar.bz2"]="application/x-bzip2"
        ["tar.xz"]="application/x-xz"
    )

    extend="${name##*.}"
    filename="${name%%.*}"
    temp=${name%.*}
    if [[ ${temp##*.} = "tar" ]]; then
         extend="${temp##*.}.${extend}"
         filename="${temp%%.*}"
    fi

    # uncompress file
    if [[ -f "$name" ]]; then
        if [[ ${decompress} && ${extends[$extend]} && $(file -i "$name") =~ ${extends[$extend]} ]]; then
            rm -rf ${filename} && mkdir ${filename}
            tar -xf ${name} -C ${filename} --strip-components 1
            if [[ $? -ne 0 ]]; then
                log_error "$name decopress failed"
                rm -rf ${filename} && rm -rf ${name}
                return ${failure}
            fi
        fi

        return ${success} #2
    fi

    # download
    log_info "$name url: $url"
    log_info "begin to donwload $name ...."
    rm -rf ${name}

    command -v "$cmd" > /dev/null 2>&1
    if [[ $? -eq 0 && "$cmd" == "axel" ]]; then
        axel -n 10 --insecure --quite -o ${name} ${url}
    else
        curl -C - --insecure  --silent --location -o ${name} ${url}
    fi
    if [[ $? -ne 0 ]]; then
        log_error "download file $name failed !!"
        rm -rf ${name}
        return ${failure}
    fi

    log_info "success to download $name"

    # uncompress file
    if [[ ${decompress} && ${extends[$extend]} && $(file -i "$name") =~ ${extends[$extend]} ]]; then
        rm -rf ${filename} && mkdir ${filename}
        tar -xf ${name} -C ${filename} --strip-components 1
        if [[ $? -ne 0 ]]; then
            log_error "$name decopress failed"
            rm -rf ${filename} && rm -rf ${name}
            return ${failure}
        fi

        return ${success} #2
    fi
}

check_user() {
    if [[ "$(whoami)" != "root" ]];then
        echo
        echo "ERROR: Please use root privileges to execute"
        echo
        exit
    fi
}

download_libevent() {
    url="https://github.com/libevent/libevent/releases/download/release-2.0.22-stable/libevent-2.0.22-stable.tar.gz"
    download "libevent.tar.gz" "$url" curl 1

    return $?
}

install_libevent() {
    # 安装目录
    rm -rf ${installdir} && \
    mkdir -p ${installdir}/libevent

    # 编译
    cd ${workdir}/libevent
    ./configure \
    --prefix=${installdir}/libevent \
    --exec-prefix=${installdir}/libevent

    # 安装
    cpu=$(cat /proc/cpuinfo | grep 'processor' | wc -l)
    make -j${cpu}
    if [[ $? -ne 0 ]]; then
        log_error "build fail"
        return ${failure}
    fi

    make install
    if [[ $? -ne 0 ]]; then
        log_error "install failed"
        return ${failure}
    fi
}

download_memcached() {
    prefix="https://memcached.org/files/memcached-$version.tar.gz"
    download "memcached.tar.gz" "$url" curl 1

    return $?
}

install_memcached() {
    cd ${workdir}/memcached

    ./configure \
    --prefix=${installdir} \
    --exec-prefix=${installdir} \
    --with-libevent=${installdir}/libevent \
    --enable-64bit
    if [[ $? -ne 0 ]]; then
        log_error "configure fail"
        return ${failure}
    fi

    # 安装
    cpu=$(cat /proc/cpuinfo | grep 'processor' | wc -l)
    make -j${cpu}
    if [[ $? -ne 0 ]]; then
        log_error "build fail"
        return ${failure}
    fi

    make install
    if [[ $? -ne 0 ]]; then
        log_error "install failed"
        return ${failure}
    fi
}

add_service() {
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

    # set dir mode
    chown -R memcached:memcached ${installdir}

    cp ${workdir}/memcached/scripts/start-memcached ${installdir}/scripts

    # add conf
    read -r -d '' startup <<- 'EOF'
# memcached default config file
# 2003 - Jay Bonci <jaybonci@debian.org>
# This configuration file is read by the start-memcached script provided as
# part of the Debian GNU/Linux distribution.

# Run memcached as a daemon. This command is implied, and is not needed for the
# daemon to run. See the README.Debian that comes with this package for more
# information.
-d

# Log memcached's output to /opt/local/memcached/run/memcached.log
logfile $dir/run/memcached.log

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
    regex='$dir'
    repl="$installdir"
    printf "%s" "${startup//$regex/$repl}" > ${installdir}/etc/memcached.conf

    # add start script
    read -r -d '' startup <<- 'EOF'
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

MEMCACHED=$dir
DAEMON=$dir/bin/memcached
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
    regex='$dir'
    repl="$installdir"
    printf "%s" "${startup//$regex/$repl}" > /etc/init.d/memcached

    chmod a+x /etc/init.d/memcached && update-rc.d memcached defaults
    if [[ $? -ne 0 ]]; then
        log_error "update-rc failed"
        return ${failure}
    fi

    # start up
    service memcached start
    if [[ $? -ne 0 ]]; then
        log_error "service start memcached failed"
        return ${failure}
    fi

    # test
    if [[ $(pgrep memcached) ]]; then
        log_info "memcached install successfully !"
        return ${success}
    fi

    return ${failure}
}

clean() {
    rm -rf ${workdir}/memcached
    rm -rf ${workdir}/memcached.tar.gz
    rm -rf ${workdir}/libevent
    rm -rf ${workdir}/libevent.tar.gz
}

do_install() {
    check_user
    if [[ $? -ne ${success} ]]; then
        return
    fi

    download_libevent
    if [[ $? -ne ${success} ]]; then
        return
    fi

    install_libevent
    if [[ $? -ne ${success} ]]; then
        return
    fi

    download_memcached
    if [[ $? -ne ${success} ]]; then
        return
    fi

    install_memcached
    if [[ $? -ne ${success} ]]; then
        return
    fi

    add_service
    if [[ $? -ne ${success} ]]; then
        return
    fi

    clean
}

do_install
