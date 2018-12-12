#!/bin/bash

#----------------------------------------------------
# File: nginx.sh
# Contents: 安装nginx服务
# Date: 18-12-12
#----------------------------------------------------


version=1.14.0
workdir=$(pwd)/nginx-${version}
installdir=/opt/local/nginx

command_exists() {
	command -v "$@" > /dev/null 2>&1
}

check_user() {
    if [[ "$(whoami)" != "root" ]];then
        echo
        echo "ERROR: Please use root privileges to execute"
        echo
        exit
    fi
}

download_src_and_install_dep() {
    # 安装下载工具
    if ! command_exists curl; then
        apt-get update && apt-get install axel -y
    fi

    # 安装依赖的包
    apt-get update && \
    apt-get install zlib1g-dev openssl libssl-dev libpcre3 libpcre3-dev libxml2 libxml2-dev libxslt-dev perl libperl-dev -y

    # 获取源代码
    echo http://nginx.org/download/nginx-${version}.tar.gz
    axel -n 20 -o nginx-${version}.tar.gz http://nginx.org/download/nginx-${version}.tar.gz

    # 解压文件
    tar -zvxf nginx-${version}.tar.gz && cd nginx-${version}
}


build_sorce_code() {
    # 创建目录
    rm -rf  ${installdir} && \
    mkdir -p ${installdir} && \
    mkdir -p ${installdir}/tmp/client && \
    mkdir -p ${installdir}/tmp/proxy && \
    mkdir -p ${installdir}/tmp/fcgi && \
    mkdir -p ${installdir}/tmp/uwsgi && \
    mkdir -p ${installdir}/tmp/scgi

    # 创建用户组并修改权限
    if [[ -z "$(cat /etc/group | grep -E '^www:')" ]]; then
        groupadd -r www
    fi

    if [[ -z "$(cat /etc/password | grep -E '^www:')" ]]; then
        useradd -r www -g www
    fi

    # 编译
    ${workdir}/configure \
    --user=www  \
    --group=www \
    --prefix=${installdir} \
    --with-poll_module \
    --with-threads \
    --with-file-aio \
    --with-http_ssl_module \
    --with-http_realip_module \
    --with-http_addition_module \
    --with-http_xslt_module=dynamic \
    --with-http_sub_module \
    --with-http_dav_module \
    --with-http_flv_module \
    --with-http_mp4_module \
    --with-http_gzip_static_module \
    --with-http_slice_module \
    --with-http_stub_status_module \
    --with-http_perl_module \
    --with-mail \
    --with-mail_ssl_module \
    --with-stream \
    --with-pcre \
    --with-debug \
    --http-client-body-temp-path=${installdir}/tmp/client \
    --http-proxy-temp-path=${installdir}/tmp/proxy \
    --http-fastcgi-temp-path=${installdir}/tmp/fcgi \
    --http-uwsgi-temp-path=${installdir}/tmp/uwsgi \
    --http-scgi-temp-path=${installdir}/tmp/scgi

    # 安装
    cpu=$(cat /proc/cpuinfo |grep 'processor'|wc -l)
    make -j${cpu} && sudo make install
}

add_config_file() {
    # 启动
    chown -R www:www ${installdir}

    # 添加启动文件
    cat > /etc/init.d/nginx <<-'EOF'
#!/bin/sh

### BEGIN INIT INFO
# Provides:   nginx
# Required-Start:    $local_fs $remote_fs $network $syslog ${NAME}d
# Required-Stop:     $local_fs $remote_fs $network $syslog ${NAME}d
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: starts the nginx web server
# Description:       starts nginx using start-stop-daemon
### END INIT INFO

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
DAEMON=/opt/local/nginx/sbin/nginx
CONF=/opt/local/nginx/conf/nginx.conf
PID=/opt/local/nginx/logs/nginx.pid
NAME=nginx
DESC=nginx


# Include nginx defaults if available
if [ -r /etc/default/nginx ]; then
    . /etc/default/nginx
fi

test -x ${DAEMON} || exit 0

. /lib/init/vars.sh
. /lib/lsb/init-functions

# Try to extract nginx pidfile
PID=$(cat ${CONF} | grep -Ev '^\s*#' | awk 'BEGIN { RS="[;{}]" } { if ($1 == "pid") print $2 }' | head -n1)
if [ -z "${PID}" ]; then
    PID=/run/nginx.pid
fi

# Check if the ULIMIT is set in /etc/default/nginx
if [ -n "${ULIMIT}" ]; then
    # Set the ulimits
    ulimit ${ULIMIT}
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
    start-stop-daemon --start --quiet --pidfile ${PID} --exec ${DAEMON} --test > /dev/null \
        || return 1
    start-stop-daemon --start --quiet --pidfile ${PID} --exec ${DAEMON} -- \
        ${DAEMON_OPTS} 2>/dev/null \
        || return 2
}

test_nginx_config() {
    ${DAEMON} -t ${DAEMON_OPTS} >/dev/null 2>&1
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
    return "${RETVAL}"
}

#
# Function that sends a SIGHUP to the daemon/service
#
do_reload() {
    start-stop-daemon --stop --signal HUP --quiet --pidfile ${PID} --name ${NAME}
    return 0
}

#
# Rotate log files
#
do_rotate() {
    start-stop-daemon --stop --signal USR1 --quiet --pidfile ${PID} --name ${NAME}
    return 0
}

#
# Online upgrade nginx executable
#
# "Upgrading Executable on the Fly"
# http://nginx.org/en/docs/control.html
#
do_upgrade() {
    # Return
    #   0 if nginx has been successfully upgraded
    #   1 if nginx is not running
    #   2 if the pid files were not created on time
    #   3 if the old master could not be killed
    if start-stop-daemon --stop --signal USR2 --quiet --pidfile ${PID} --name ${NAME}; then
        # Wait for both old and new master to write their pid file
        while [ ! -s "${PID}.oldbin" ] || [ ! -s "${PID}" ]; do
            cnt=`expr ${cnt} + 1`
            if [ ${cnt} -gt 10 ]; then
                return 2
            fi
            sleep 1
        done
        # Everything is ready, gracefully stop the old master
        if start-stop-daemon --stop --signal QUIT --quiet --pidfile "${PID}.oldbin" --name ${NAME}; then
            return 0
        else
            return 3
        fi
    else
        return 1
    fi
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

        # Check configuration before stopping nginx
        if ! test_nginx_config; then
            log_end_msg 1 # Configuration error
            exit 0
        fi

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
    reload|force-reload)
        log_daemon_msg "Reloading ${DESC} configuration" "${NAME}"

        # Check configuration before reload nginx
        #
        # This is not entirely correct since the on-disk nginx binary
        # may differ from the in-memory one, but that's not common.
        # We prefer to check the configuration and return an error
        # to the administrator.
        if ! test_nginx_config; then
            log_end_msg 1 # Configuration error
            exit 0
        fi

        do_reload
        log_end_msg $?
        ;;
    configtest|testconfig)
        log_daemon_msg "Testing ${DESC} configuration"
        test_nginx_config
        log_end_msg $?
        ;;
    status)
        status_of_proc -p ${PID} "${DAEMON}" "${NAME}" && exit 0 || exit $?
        ;;
    upgrade)
        log_daemon_msg "Upgrading binary" "${NAME}"
        do_upgrade
        log_end_msg 0
        ;;
    rotate)
        log_daemon_msg "Re-opening ${DESC} log files" "${NAME}"
        do_rotate
        log_end_msg $?
        ;;
    *)
        echo "Usage: ${NAME} {start|stop|restart|reload|force-reload|status|configtest|rotate|upgrade}" >&2
        exit 3
        ;;
esac

:
EOF

    # 权限
    chmod a+x /etc/init.d/nginx && \
    update-rc.d nginx defaults && \
    update-rc.d nginx disable $(runlevel | cut -d ' ' -f2)

    # 启动
    service nginx start

    # 测试
    if [[ $(pgrep nginx) ]]; then
        echo "========================================================"
        echo "nginx install success!!!"
    fi
}

clean_file() {
    cd ../ && rm -rf nginx-*
}

