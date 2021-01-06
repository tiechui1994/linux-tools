#!/bin/bash

#----------------------------------------------------
# File: nginx.sh
# Contents: 安装nginx服务
# Date: 18-12-12
#----------------------------------------------------


declare -r version=1.15.8
declare -r workdir=$(pwd)
declare -r installdir=/opt/local/nginx

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
    if [[ "$(whoami)" != "root" ]];then
        log_error "please use root privileges to execute"
        return ${failure}
    fi
}

insatll_depend() {
    apt-get update && \
    apt-get install build-essential zlib1g-dev openssl libssl-dev libpcre3 libpcre3-dev libxml2 \
    libxml2-dev libxslt-dev perl libperl-dev -y
}

download_nginx() {
    url="http://nginx.org/download/nginx-$version.tar.gz"
    common_download "nginx" "$url" axel
    return $?
}

download_openssl() {
    prefix="https://ftp.openssl.org/source/old"
    openssl="$(openssl version |cut -d " " -f2)"
    url=$(printf "%s/%s/openssl-%s.tar.gz" ${prefix} ${openssl:0:${#openssl}-1} ${openssl})
    common_download "openssl" "$url" axel
    return $?
}

download_pcre() {
    url="https://ftp.pcre.org/pub/pcre/pcre-8.38.tar.gz"
    common_download "pcre" "$url" axel
    return $?
}

download_zlib() {
    url="http://www.zlib.net/fossils/zlib-1.2.11.tar.gz"
    common_download "zlib" "$url" axel
    return $?
}

# https proxy
# doc: https://github.com/chobits/ngx_http_proxy_connect_module
download_proxy_connect() {
    url="https://codeload.github.com/chobits/ngx_http_proxy_connect_module/tar.gz/v0.0.1"
    common_download "ngx_http_proxy_connect_module" "$url"
    return $?
}

# nginx lua
donwnload_nginx_lua() {
    luajit="http://luajit.org/download/LuaJIT-2.0.5.tar.gz"
    common_download "luajit" "$luajit" axel
    if [[ $? -ne ${success} ]]; then
        return $?
    fi

    ngx_devel_kit="https://codeload.github.com/vision5/ngx_devel_kit/tar.gz/v0.3.1"
    common_download "ngx_devel_kit" "$ngx_devel_kit"
    if [[ $? -ne ${success} ]]; then
        return $?
    fi

    ngx_lua="https://codeload.github.com/openresty/lua-nginx-module/tar.gz/v0.10.14"
    common_download "lua-nginx-module" "$ngx_lua"
    return $?
}

# nginx_lua
# doc: https://github.com/openresty/lua-nginx-module#installation
build_luajit() {
    cd ${workdir}/luajit && make
    if [[ $? -ne 0 ]]; then
        log_error "make luajit fail"
        return ${failure}
    fi

    make install PREFIX=/usr/local/luajit
    if [[ $? -ne 0 ]]; then
        log_error "make install luajit fail"
        rm -rf /usr/local/luajit
        return ${failure}
    fi
}


build() {
    # create nginx dir
    rm -rf  ${installdir} && \
    mkdir -p ${installdir} && \
    mkdir -p ${installdir}/tmp/client && \
    mkdir -p ${installdir}/tmp/proxy && \
    mkdir -p ${installdir}/tmp/fcgi && \
    mkdir -p ${installdir}/tmp/uwsgi && \
    mkdir -p ${installdir}/tmp/scgi

    # create user
    if [[ -z "$(cat /etc/group | grep -E '^www:')" ]]; then
        groupadd -r www
    fi

    if [[ -z "$(cat /etc/passwd | grep -E '^www:')" ]]; then
        useradd -r www -g www
    fi

    ##
    # nginx配置模块解析:
    #   ngx_http_ssl_module  为HTTPS提供必要的支持, 需要OpenSSL库
    #   ngx_http_v2_module   提供了HTTP2协议的支持, 并取代ngx_http_spdy_module模块
    #   ngx_http_realip_module 用于改变客户端地址和可选端口在发送的头字段
    #   ngx_http_addition_module  在响应之前和之后添加文件内容
    #   ngx_http_xslt_module  过滤转换XML请求
    #   ngx_http_image_filter_module 实现图片裁剪、缩放、旋转功能，支持jpg、gif、png格式, 需要gd库
    #   ngx_http_geoip_module  可以用于IP访问限制
    #   ngx_http_sub_module  允许用一些其他文本替换nginx响应中的一些文本
    #   ngx_http_dav_module  增加PUT,DELETE,MKCOL(创建集合),COPY和MOVE方法
    #   ngx_http_flv_module  提供寻求内存使用基于时间的偏移量文件(流媒体点播)
    #   ngx_http_mp4_module
    #   ngx_http_gunzip_module
    #   ngx_http_gzip_static_module  在线实时压缩输出数据流
    #   ngx_http_auth_request_module 第三方auth支持
    #   ngx_http_random_index_module 从目录中随机挑选一个目录索引
    #   ngx_http_secure_link_module  计算和检查要求所需的安全链接网址
    #   ngx_http_degradation_module 许在内存不足的情况下返回204或444码
    #   ngx_http_slice_module  将一个请求分解成多个子请求, 每个子请求返回响应内容的一个片段，让大文件的缓存更有效
    #   ngx_http_stub_status_module 获取nginx自上次启动以来的工作状态
    #   ngx_http_perl_module
    #
    #   ngx_mail_ssl_module
    #
    #   ngx_stream_ssl_module
    #   ngx_stream_realip_module 真实ip
    #   ngx_stream_geoip_module  ip限制
    #   ngx_stream_ssl_preread_module
    #
    #   ngx_google_perftools_module
    #   ngx_cpp_test_module
    #
    ##
    # build and install
    cd ${workdir}/nginx

    # proxy_connect
    if [[ "$version" =~ 1.13.* || "$version" =~ 1.14.* ]]; then
        patch -p1 < ${workdir}/ngx_http_proxy_connect_module/patch/proxy_connect_rewrite_1014.patch
    elif [[ "$version" = "1.15.2"  ]]; then
        patch -p1 < ${workdir}/ngx_http_proxy_connect_module/patch/proxy_connect_rewrite_1015.patch
    elif [[ "$version" =~ 1.15.* || "$version" =~ 1.16.* ]]; then
        patch -p1 < ${workdir}/ngx_http_proxy_connect_module/patch/proxy_connect_rewrite_101504.patch
    else
        patch -p1 < ${workdir}/ngx_http_proxy_connect_module/patch/proxy_connect_rewrite_1018.patch
    fi

    # nginx lua
    export LUAJIT_LIB="/usr/local/luajit/lib"
    export LUAJIT_INC="/usr/local/luajit/include/luajit-2.0"

    ./configure \
    --user=www  \
    --group=www \
    --prefix=${installdir} \
    --with-poll_module \
    --with-threads \
    --with-file-aio \
    --with-http_ssl_module \
    --with-http_v2_module \
    --with-http_realip_module \
    --with-http_addition_module \
    --with-http_sub_module \
    --with-http_dav_module \
    --with-http_flv_module \
    --with-http_mp4_module \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_auth_request_module \
    --with-http_secure_link_module \
    --with-http_perl_module \
    --with-http_slice_module \
    --with-mail \
    --with-mail_ssl_module \
    --with-stream \
    --with-pcre \
    --with-debug \
    --with-zlib=${workdir}/zlib \
    --with-pcre=${workdir}/pcre \
    --with-openssl=${workdir}/openssl \
    --add-module=${workdir}/ngx_http_proxy_connect_module \
    --with-ld-opt="-Wl,-rpath,$LUAJIT_LIB" \
    --add-module=${workdir}/ngx_devel_kit \
    --add-module=${workdir}/lua-nginx-module \
    --http-client-body-temp-path=${installdir}/tmp/client \
    --http-proxy-temp-path=${installdir}/tmp/proxy \
    --http-fastcgi-temp-path=${installdir}/tmp/fcgi \
    --http-uwsgi-temp-path=${installdir}/tmp/uwsgi \
    --http-scgi-temp-path=${installdir}/tmp/scgi
    if [[ $? -ne 0 ]]; then
        log_error "configure fail"
        return ${failure}
    fi

    cpu=$(cat /proc/cpuinfo | grep 'processor' | wc -l)
    openssl="$(openssl version |cut -d " " -f2)"
    if [[ ${openssl} > "1.1.0" ]]; then
        cpu=1
    fi

    make -j ${cpu}
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
    # set dir mode
    chown -R www:www ${installdir}

    # conf template and add deafult conf file
    read -r -d '' conf <<- 'EOF'
user  www;
worker_processes 1;

error_log  $dir/logs/error.log  notice;
pid        $dir/logs/nginx.pid;

events {
     worker_connections  1024;
}

http {
    include       mime.types;
    default_type  application/octet-stream;
    log_format  main   '$remote_addr - $remote_user [$time_local] "$request" '
                       '$status $body_bytes_sent "$http_referer" '
                       '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  $dir/logs/access.log  main;
    sendfile        on;
    tcp_nopush      on;
    keepalive_timeout  65;
    gzip  on;

    #
    # HTTP server
    #
    server {
        listen 80;
        server_name  localhost;
        location / {
            root   html;
            index  index.html index.htm;
        }

        error_page  404              /404.html;

        # redirect server error pages to the static page /50x.html
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }

        # proxy the PHP scripts to Apache listening on 127.0.0.1:80
        #
        #location ~ \.php$ {
        #    proxy_pass   http://127.0.0.1;
        #}

        # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
        #
        #location ~ \.php$ {
        #    root           html;
        #    fastcgi_pass   127.0.0.1:9000;
        #    fastcgi_index  index.php;
        #    fastcgi_param  SCRIPT_FILENAME  /scripts$fastcgi_script_name;
        #    include        fastcgi_params;
        #}

        # deny access to .htaccess files, if Apache's document root
        # concurs with nginx's one
        #
        #location ~ /\.ht {
        #    deny  all;
        #}
    }

    #
    # HTTPS server
    #
    #server {
    #    listen       443 ssl;
    #    server_name  localhost;
    #
    #    ssl_certificate      cert.pem;
    #    ssl_certificate_key  cert.key;
    #
    #    ssl_session_cache    shared:SSL:1m;
    #    ssl_session_timeout  5m;
    #
    #    ssl_ciphers  HIGH:!aNULL:!MD5;
    #    ssl_prefer_server_ciphers  on;
    #
    #    location / {
    #        root   html;
    #        index  index.html index.htm;
    #    }
    #}

    #
    # other server config
    #
    include conf.d/*.conf;
}
EOF
    regex='$dir'
    repl="$installdir"
    printf "%s" "${conf//$regex/$repl}" > ${installdir}/conf/nginx.conf

    if [[ ! -d ${installdir}/conf/conf.d ]]; then
        mkdir -p ${installdir}/conf/conf.d
    fi

    # start up template file and instace
    read -r -d '' startup <<- 'EOF'
#!/bin/bash

### BEGIN INIT INFO
# Provides:   nginx
# Required-Start:    $local_fs $syslog
# Required-Stop:     $local_fs $syslog
# Default-Start:     2
# Default-Stop:      0 1 3 4 5 6
# Short-Description: starts the nginx web server
# Description:       starts nginx using start-stop-daemon
### END INIT INFO

DAEMON=$dir/sbin/nginx
CONF=$dir/conf/nginx.conf
PID=$dir/logs/nginx.pid
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

    regex='$dir'
    repl="$installdir"
    printf "%s" "${startup//$regex/$repl}" > /etc/init.d/nginx
    chmod a+x /etc/init.d/nginx && update-rc.d nginx defaults
    if [[ $? -ne 0 ]]; then
        log_error "update-rc failed"
        return ${failure}
    fi

    # start up
    systemctl daemon-reload && service nginx start
    if [[ $? -ne 0 ]]; then
        log_error "service start nginx failed"
        return ${failure}
    fi

    # test
    if [[ $(pgrep nginx) ]]; then
        log_info "nginx install successfully !"
        return ${success}
    fi

    return ${failure}
}

clean_file() {
    rm -rf ${workdir}/nginx
    rm -rf ${workdir}/nginx.tar.gz
    rm -rf ${workdir}/openssl*
    rm -rf ${workdir}/pcre*
    rm -rf ${workdir}/zlib*
    rm -rf ${workdir}/luajit*
    rm -rf ${workdir}/lua-nginx-module*
    rm -rf ${workdir}/ngx_devel_kit*
    rm -rf ${workdir}/ngx_http_proxy_connect_module*
}

do_install(){
     check_user
     if [[ $? -ne ${success} ]]; then
        return
     fi

     insatll_depend

     download_openssl
     if [[ $? -ne ${success} ]]; then
        return
     fi

     download_pcre
     if [[ $? -ne ${success} ]]; then
        return
     fi

     download_zlib
     if [[ $? -ne ${success} ]]; then
        return
     fi

     download_proxy_connect
     if [[ $? -ne ${success} ]]; then
        return
     fi

     donwnload_nginx_lua
     if [[ $? -ne ${success} ]]; then
        return
     fi

     download_nginx
     if [[ $? -ne ${success} ]]; then
        return
     fi

     build_luajit
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
