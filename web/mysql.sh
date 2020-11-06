#!/bin/bash

#----------------------------------------------------
# File: mysql.sh
# Contents: 安装mysql服务
# Date: 18-12-12
#----------------------------------------------------


version=5.7.30
workdir=$(pwd)
installdir=/opt/local/mysql

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
        return ${SUCCESS}
    fi

    if [[ -f "$name.tar.gz" && -n $(file "$name.tar.gz" |grep -o 'POSIX tar archive') ]]; then
        rm -rf ${name} && mkdir ${name}
        tar -zvxf ${name}.tar.gz -C ${name} --strip-components 1
        if [[ $? -ne 0 ]]; then
            log_error "$name decopress failed"
            rm -rf ${name}*
            return ${DECOMPRESS_FAIL}
        fi
        return ${SUCCESS}
    fi

    log_info "$name url: $url"
    rm -rf ${name}.tar.gz
    command_exists "$cmd"
    if [[ $? -eq 0 && "$cmd" == "axel" ]]; then
        axel -n 10 -o "$name.tar.gz" ${url}
    else
        curl -C - ${url} -o "$name.tar.gz"
    fi

    if [[ $? -ne 0 ]]; then
        log_error "$name source download failed"
        rm -rf ${name}.tar.gz
        return ${DOWNLOAD_FAIL}
    fi

    rm -rf ${name} && mkdir ${name}
    tar -zvxf ${name}.tar.gz -C ${name} --strip-components 1
    if [[ $? -ne 0 ]]; then
        log_error "$name decopress failed"
        rm -rf ${name}*
        return ${DECOMPRESS_FAIL}
    fi
}

command_exists() {
	command -v "$@" > /dev/null 2>&1
}

check_param() {
    if [[ "$(whoami)" != "root" ]]; then
        log_error "Please use root privileges to execute"
        exit
    fi
}

download_mysql() {
    url="https://mirrors.cloud.tencent.com/mysql/downloads/MySQL-5.7/mysql-$version.tar.gz"
    common_download "mysql" ${url} axel

    return $?
}

download_boost(){
    url="https://nchc.dl.sourceforge.net/project/boost/boost/1.59.0/boost_1_59_0.tar.gz"
    common_download "boost" ${url} axel
    if [[ $? -eq ${SUCCESS} ]]; then
        mv "$workdir/boost" "$workdir/mysql/boost"
        return $?
    fi

    return $?
}

build() {
    # depend
    apt-get update && \
    apt-get install cmake build-essential libncurses5-dev bison libssl-dev -y
    if [[ $? -ne 0 ]]; then
        log_error "install depency fail"
        return ${INSTALL_FAIL}
    fi

    # remove old directory
    rm -rf ${installdir} && \
    mkdir -p ${installdir}/mysql && \
    mkdir -p ${installdir}/data && \
    mkdir -p ${installdir}/logs && \
    mkdir -p ${installdir}/tmp && \
    mkdir -p ${installdir}/conf

    # user and group
    if [[ -z "$(cat /etc/group|grep -E '^mysql:')" ]]; then
       groupadd -r mysql
    fi
    if [[ -z "$(cat /etc/passwd|grep -E '^mysql:')" ]]; then
        useradd -r -g mysql -s /sbin/nologin mysql
    fi

    # in workspace
    cd "$workdir/mysql"

    # cmake
    cmake . \
    -DCMAKE_INSTALL_PREFIX=${installdir}/mysql \
    -DMYSQL_DATADIR=${installdir}/data \
    -DSYSCONFDIR=${installdir}/conf \
    -DDOWNLOAD_BOOST=1 \
    -DWITH_BOOST=${workdir}/mysql-${version}/boost \
    -DWITH_INNOBASE_STORAGE_ENGINE=1 \
    -DWITH_PARTITION_STORAGE_ENGINE=1 \
    -DWITH_FEDERATED_STORAGE_ENGINE=1 \
    -DWITH_BLACKHOLE_STORAGE_ENGINE=1 \
    -DWITH_MYISAM_STORAGE_ENGINE=1 \
    -DENABLED_LOCAL_INFILE=1 \
    -DENABLE_DTRACE=0 \
    -DDEFAULT_CHARSET=utf8 \
    -DDEFAULT_COLLATION=utf8_general_ci
    if [[ $? -ne 0 ]]; then
        log_error "cmake fail, plaease check and try again.."
        return ${CMAKE_FAIL}
    fi

    # make
    cpu=$(cat /proc/cpuinfo |grep 'processor'|wc -l)
    make -j ${cpu}
    if [[ $? -ne 0 ]]; then
        log_error "make fail, plaease check and try again..."
        return ${MAKE_FAIL}
    fi

    make install
    if [[ $? -ne 0 ]]; then
        log_error "make install fail, plaease check and try again..."
        return ${INSTALL_FAIL}
    fi

    return ${SUCCESS}
}

add_service() {
    read -r -d '' conf <<- 'EOF'
[client]
    port=3306
    socket=$dir/data/mysql.sock
    default-character-set=utf8

[mysqld]
    port=3306
    user=mysql
    socket=$dir/data/mysql.sock
    pid-file=$dir/data/mysql.pid
    basedir=$dir/mysql  # 安装目录
    datadir=$dir/data   # 数据目录
    tmpdir=$dir/tmp     # 临时目录
    character-set-server=utf8
    log_error=$dir/logs/mysql.err

    server-id=2
    log_bin=$dir/logs/binlog

    general_log_file=$dir/logs/general_log
    general_log=1

    slow_query_log=ON
    long_query_time=2
    slow_query_log_file=$dir/logs/query_log
    log_queries_not_using_indexes=ON

    bulk_insert_buffer_size=64M
    binlog_rows_query_log_events=ON

    sort_buffer_size=64M #默认是128K
    binlog_format=row #默认是mixed
    join_buffer_size=128M #默认是256K
    max_allowed_packet=512M #默认是16M
EOF

    # create config file my.cnf
    regex='$dir'
    repl="$installdir"
    printf "%s" "${conf//$regex/$repl}" > ${installdir}/conf/my.cnf

    # update install dir owner
    chown -R mysql:mysql "$installdir"

    # add service config
    cp ${installdir}/mysql/support-files/mysql.server /etc/init.d/mysqld
    chmod a+x /etc/init.d/mysqld && update-rc.d mysqld defaults
    if [[ $? -ne 0 ]]; then
        log_error "update-rc failed"
        return ${SERVICE_FAIL}
    fi

    return ${SUCCESS}
}

init_db() {
    # clear logs and data
    rm -rf ${installdir}/logs/* && rm -rf ${installdir}/data/*

    # init database
    ${installdir}/mysql/bin/mysqld \
    --initialize \
    --user=mysql \
    --basedir=${installdir}/mysql \
    --datadir=${installdir}/data
    if [[ $? -ne 0 ]]; then
        log_error "mysqld initialize failed"
        return ${INIT_FAIL}
    fi

    # check logs/mysql.err.
    error=$(grep -E -i -o '\[error\].*' "$installdir/logs/mysql.err")
    if [[ -n ${error} ]]; then
        log_error "mysql database init failed"
        log_error "error message:"
        log_error "$error"
        log_error "the detail message in file $installdir/logs/mysql.err"
        return ${INIT_FAIL}
    fi

    # start mysqld service
    systemctl daemon-reload && service mysqld start
    if [[ $? -ne 0 ]]; then
        log_error "mysqld service start failed, please check and trg again..."
        return ${SERVICE_FAIL}
    fi

    # check password
    password="$(grep 'temporary password' "$installdir/logs/mysql.err"|cut -d ' ' -f11)"
    log_info "current password is: $password"
    log_warn "please use follow command and sql login and update your password:"
    log_warn "mysql -u root --password='$password'"
    log_warn "SET PASSWORD = PASSWORD('your new password');"
    log_warn "ALTER user 'root'@'localhost' PASSWORD EXPIRE NEVER;"
    log_warn "FLUSH PRIVILEGES;"
    log_info "mysql install successfully"

    return ${SUCCESS}
}

clean_file(){
    rm -rf ${workdir}/mysql
    rm -rf ${workdir}/mysql.tar.gz
    rm -rf ${workdir}/boost
    rm -rf ${workdir}/boost.tar.gz
}

do_install() {
    check_param

    download_mysql
    if [[ $? -ne ${SUCCESS} ]]; then
        return
    fi

    download_boost
    if [[ $? -ne ${SUCCESS} ]]; then
        return
    fi

    build
    if [[ $? -ne ${SUCCESS} ]]; then
        return
    fi

    add_service
    if [[ $? -ne ${SUCCESS} ]]; then
        return
    fi

    init_db
    if [[ $? -ne ${SUCCESS} ]]; then
        return
    fi

    clean_file
}

do_install
