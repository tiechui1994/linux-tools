#!/usr/bin/env bash

#----------------------------------------------------
# File: run.sh
# Contents: 
# Date: 11/13/20
#----------------------------------------------------

NAME="ptest"
EXEC="./ptest"

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

start_daemon () {
    local force pidfile OPTIND
    force=""
    pidfile=/dev/null

    OPTIND=1
    while getopts fn:p: opt ; do
        case "$opt" in
            f)  force="force";;
            p)  pidfile="$OPTARG";;
        esac
    done

    shift $(($OPTIND - 1))
    if [[ "$1" = '--' ]]; then
        shift
    fi

    exec="$1"; shift
    args="--start --background --quiet --oknodo"
    if [[ "$force" ]]; then
        /sbin/start-stop-daemon ${args} --chdir "$PWD" \
        --startas ${exec} --pidfile /dev/null -- "$@"
    elif [[ "$pidfile" ]]; then
        /sbin/start-stop-daemon ${args} --chdir "$PWD" \
        --exec ${exec} --pidfile ${pidfile} -- "$@"
    else
        /sbin/start-stop-daemon ${args} --chdir "$PWD" \
        --exec ${exec} -- "$@"
    fi
}

stop_daemon() {
    local force pid signal
    force=""

    OPTIND=1
    while getopts fn:p: opt ; do
        case "$opt" in
            f)  force="force";;
            p)  pid="$OPTARG";;
            s)  signal="$OPTARG";;
        esac
    done

    shift $(($OPTIND - 1))
    if [[ "$1" = '--' ]]; then
        shift
    fi

    name="$1"; shift

    if [[ "$pid" =~ ^[0-9]+$ ]]; then
        let pid=pid
    elif [[ -e ${pid} ]]; then
        let pid=$(cat ${pid})
    else
        return 1
    fi

    args="--stop --quiet"
    if [[ "$force" ]]; then
        /sbin/start-stop-daemon ${args} --retry=TERM/30/KILL/5 \
        --pid ${pid} --name ${name}
    elif [[ "$signal" ]]; then
       /sbin/start-stop-daemon ${args} --signal ${signal} \
       --pid ${pid} --name ${name}
    else
       /sbin/start-stop-daemon ${args} --signal QUIT \
       --pid ${pid} --name ${name}
    fi

    sleep 1
}

start() {
    log_info "staring $NAME ..."
    start_daemon -f ${EXEC} 2>&1

    pids=($(pgrep "$NAME"))
    if [[ ${#pids[@]} > 1 || ${#pids[@]} = 1 ]]; then
        log_info "$NAME started success"
    else
        log_warn "$NAME started failed"
    fi
}

stop() {
   pids=($(pgrep "$NAME"))
   for pid in ${pids[@]}; do
      if [[ -n $(ps -p ${pid} | grep -o '?') ]]; then
        log_info "stop $NAME of pid: $pid"
 	    stop_daemon -f -p ${pid} ${NAME}
      fi
   done
}

log_info "start $NAME job ...."

pids=($(pgrep "$NAME"))
if [[ ${#pids[@]} = 0 ]]; then
    start
else
    stop
    start
fi
