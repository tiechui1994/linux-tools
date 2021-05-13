#!/bin/bash

#----------------------------------------------------
# File: redis.sh
# Contents: 安装redis服务
# Date: 18-12-10
#----------------------------------------------------

declare -r version=4.0.0
declare -r workdir=$(pwd)
declare -r installdir=/opt/share/local/redis

declare -r success=0
declare -r failure=1

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
        log_info "$name has exist"
        return ${success} #1
    fi

    if [[ -f "$name.tar.gz" && -n $(file "$name.tar.gz" | grep -o 'POSIX tar archive') ]]; then
        rm -rf ${name} && mkdir ${name}
        tar -zvxf ${name}.tar.gz -C ${name} --strip-components 1
        if [[ $? -ne 0 ]]; then
            log_error "$name decopress failed"
            rm -rf ${name} && rm -rf ${name}.tar.gz
            return ${failure}
        fi

        return ${success} #2
    fi

    log_info "$name url: $url"
    log_info "begin to donwload $name ...."
    rm -rf ${name}.tar.gz

    command -v "$cmd" > /dev/null 2>&1
    if [[ $? -eq 0 && "$cmd" == "axel" ]]; then
        axel -n 10 --insecure --quite -o "$name.tar.gz" ${url}
    else
        curl -C - --insecure --silent ${url} -o "$name.tar.gz"
    fi

    if [[ $? -ne 0 ]]; then
        log_error "download file $name failed !!"
        rm -rf ${name}.tar.gz
        return ${failure}
    fi

    log_info "success to download $name"
    rm -rf ${name} && mkdir ${name}
    tar -zxf ${name}.tar.gz -C ${name} --strip-components 1
    if [[ $? -ne 0 ]]; then
        log_error "$name decopress failed"
        rm -rf ${name} && rm -rf ${name}.tar.gz
        return ${failure}
    fi
}

check_user() {
    if [[ "$(whoami)" != "root" ]]; then
        log_error "Please use root privileges to execute"
        exit
    fi
}

download_redis() {
    url="https://codeload.github.com/antirez/redis/tar.gz/$version"
    common_download "redis" ${url}
    return $?
}

build() {
    rm -rf ${installdir} && mkdir -p ${installdir}

    cpu=$(cat /proc/cpuinfo | grep 'processor' | wc -l)
    cd ${workdir}/redis && make -j ${cpu}
    if [[ $? -ne 0 ]]; then
        log_error "build fail"
        return ${failure}
    fi

    make PREFIX=${installdir} install
    if [[ $? -ne 0 ]]; then
        log_error "install failed"
        return ${failure}
    fi
}

add_service() {
    # mkdir
    mkdir ${installdir}/data && \
    mkdir ${installdir}/logs && \
    mkdir -p ${installdir}/conf

    # copy conf
    cp redis.conf ${installdir}/conf && \
    cp sentinel.conf ${installdir}/conf

    # change redis.conf
    sed -i \
    -e "s|^daemonize.*|daemonize yes|g" \
    -e "s|^supervised.*|supervised auto|g" \
    -e "s|^pidfile.*|pidfile $installdir/logs/redis_6379.pid|g" \
    -e "s|^logfile.*|logfile $installdir/logs/redis.log|g" \
    -e "s|^dir.*|dir $installdir/data/|g" \
    ${installdir}/conf/redis.conf
    if [[ $? -ne 0 ]]; then
        log_error "update redis.conf failed"
        return ${failure}
    fi


    # service
    read -r -d '' startup <<- 'EOF'
#!/bin/bash

### BEGIN INIT INFO
# Provides:          redis
# Required-Start:    $local_fs $syslog
# Required-Stop:     $local_fs $syslog
# Default-Start:     2
# Default-Stop:      0 1 3 4 5 6
# Description:       redis service daemon
### END INIT INFO

REDISPORT=6379
EXEC=$dir/bin/redis-server
CLIEXEC=$dir/bin/redis-cli

PIDFILE=$dir/logs/redis_${REDISPORT}.pid
CONF=$dir/conf/redis.conf

. /lib/lsb/init-functions

case "$1" in
    start)
        if [[ -f ${PIDFILE} ]]
        then
                log_failure_msg "${PIDFILE} exists, process is already running or crashed"
        else
                log_begin_msg "Starting Redis server..."
                $EXEC ${CONF}
        fi
        ;;
    stop)
        if [[ ! -f ${PIDFILE} ]]
        then
                log_failure_msg "${PIDFILE} does not exist, process is not running"
        else
                PID=$(cat ${PIDFILE})
                log_begin_msg "Stopping ..."

                ${CLIEXEC} -p ${REDISPORT} shutdown
                if [[ -e ${PIDFILE} ]];then
                    rm -rf ${PIDFILE}
                fi

                while [[ -x /proc/${PID} ]]
                do
                    log_begin_msg "Waiting for Redis to shutdown ..."
                    sleep 1
                done
                log_success_msg "Redis stopped"
        fi
        ;;
    *)
        log_failure_msg "Please use start or stop as first argument"
        ;;
esac
EOF

    regex='$dir'
    repl="$installdir"
    printf "%s" "${startup//$regex/$repl}" > /etc/init.d/redis

    # mode
    chmod a+x /etc/init.d/redis && update-rc.d redis defaults
    if [[ $? -ne 0 ]]; then
        log_error "update-rc failed"
        return ${failure}
    fi

    # link
    ln -sf ${installdir}/bin/redis-cli /usr/local/bin/redis-cli && \
    ln -sf ${installdir}/bin/redis-server /usr/local/bin/redis-server

    # start
    systemctl daemon-reload && service redis start
    if [[ $? -ne 0 ]]; then
        log_error "service start nginx failed"
        return ${failure}
    fi

    # test
    if [[ -n $(netstat -an|grep '127.0.0.1:6379') ]];then
        log_info "redis installed successful !"
        return ${success}
    fi

    return ${failure}
}

clean_file() {
    rm -rf ${workdir}/redis
    rm -rf ${workdir}/redis.tar.gz
}

do_install() {
    check_user
    download_redis
    if [[ $? -ne ${success} ]]; then
        return
    fi

    build
    if [[ $? -ne ${success} ]]; then
        return
    fi

    add_service
    if [[ $? -ne ${success} ]]; then
        return
    fi

    clean_file
}

do_install
