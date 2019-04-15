#!/bin/bash

#----------------------------------------------------
# File: mysql.sh
# Contents: 安装mysql服务
# Date: 18-12-12
#----------------------------------------------------


version=5.7.23
workdir=$(pwd)/mysql-${version}
installdir=/opt/local/mysql

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
        apt-get update && sudo apt-get install axel -y
    fi
}

download_source_code() {
    # 下载源码包
    mysql="https://cdn.mysql.com/Downloads/MySQL-5.7"
    axel -n 100 "${mysql}/mysql-${version}.tar.gz" -o mysql-${version}.tar.gz

    # 解压源文件
    if [[ -e ${workdir} ]]; then
       rm -rf ${workdir}
    fi

    mkdir ${workdir} && \
    tar -zvxf mysql-${version}.tar.gz -C ${workdir} --strip-components 1 && \
    cd ${workdir}

    # 下载boost依赖库文件
    bost="https://nchc.dl.sourceforge.net/project/boost/boost/1.59.0/boost_1_59_0.tar.gz"
    mkdir -p ${workdir}/boost && \
    axel -n 100 ${bost} -o ${workdir}/boost/
}

before_install(){
    # 安装依赖包
    apt-get update && \
    apt-get install cmake build-essential libncurses5-dev bison -y

    # 增加用户
    if [[ -z "$(cat /etc/group | grep -E '^mysql:')" ]]; then
       groupadd -r mysql
    fi

    if [[ -z "$(cat /etc/passwd | grep -E '^mysql:')" ]]; then
        useradd -r -g mysql -s /sbin/nologin mysql
    fi

    # 创建文件
    rm -rf ${installdir} && \
    mkdir -p ${installdir}/mysql && \
    mkdir -p ${installdir}/data && \
    mkdir -p ${installdir}/logs && \
    mkdir -p ${installdir}/tmp && \
    mkdir -p ${installdir}/conf
}

make_install() {
    # cmake编译
    cd ${workdir} && \
    cmake . \
    -DCMAKE_INSTALL_PREFIX=${installdir}/mysql \
    -DMYSQL_DATADIR=${installdir}/data \
    -DSYSCONFDIR=${installdir}/conf \
    -DDOWNLOAD_BOOST=1 \
    -DWITH_BOOST=${workdir}/boost \
    -DWITH_INNOBASE_STORAGE_ENGINE=1 \
    -DWITH_PARTITION_STORAGE_ENGINE=1 \
    -DWITH_FEDERATED_STORAGE_ENGINE=1 \
    -DWITH_BLACKHOLE_STORAGE_ENGINE=1 \
    -DWITH_MYISAM_STORAGE_ENGINE=1 \
    -DENABLED_LOCAL_INFILE=1 \
    -DENABLE_DTRACE=0 \
    -DDEFAULT_CHARSET=utf8 \
    -DDEFAULT_COLLATION=utf8_general_ci

    # 安装
    cpu=$(cat /proc/cpuinfo |grep 'processor'|wc -l)
    make -j${cpu} && make install
}

add_mysql_config() {
    # 创建配置文件my.cnf(确保文件没有被创建)
    if [[ -e ${installdir}/conf/my.cnf ]];then
       rm -rf ${installdir}/conf/my.cnf
    fi

    # 写入配置内容
    cat >> ${installdir}/conf/my.cnf << EOF
[client]
    port=3306
    socket=${installdir}/data/mysql.sock
    default-character-set=utf8

[mysqld]
    port=3306
    user=mysql
    socket=${installdir}/data/mysql.sock
    pid-file=${installdir}/data/mysql.pid
    basedir=${installdir}/mysql  # 安装目录
    datadir=${installdir}/data   # 数据目录
    tmpdir=${installdir}/tmp     # 临时目录
    character-set-server=utf8
    log_error=${installdir}/logs/mysql.err

    server-id=2
    log_bin=${installdir}/logs/binlog

    general_log_file=${installdir}/logs/general_log
    general_log=1

    slow_query_log=ON
    long_query_time=2
    slow_query_log_file=${installdir}/logs/query_log
    log_queries_not_using_indexes=ON

    bulk_insert_buffer_size=64M
    binlog_rows_query_log_events=ON

    sort_buffer_size=64M #默认是128K
    binlog_format=row #默认是mixed
    join_buffer_size=128M #默认是256K
    max_allowed_packet=512M #默认是16M
EOF

    # 修改用户所有者权限
    chown -R mysql:mysql ${installdir}

    # 服务配置
    cp ${installdir}/mysql/support-files/mysql.server /etc/init.d/mysqld && \
    update-rc.d mysqld defaults
}

init_mysql_database() {
    # 初始化数据(需要清空logs和data目录下的所有的内容)
    rm -rf ${installdir}/logs/* && \
    rm -rf ${installdir}/data/* && \
    ${installdir}/mysql/bin/mysqld \
    --initialize \
    --user=mysql \
    --basedir=${installdir}/mysql \
    --datadir=${installdir}/data

    # 数据库初始化检查
    if cat ${installdir}/logs/mysql.err | grep -E -i '\[error\]'; then
        echo
        echo "ERROR: Mysql初始化出现问题, 请查看详情文件${installdir}/logs/mysql.err自己解决"
        echo
        exit
    fi

    # 启动服务
    service mysqld start
    if [[ -z "$(service mysqld status |grep -o 'Active: active (running)')" ]]; then
        echo
        echo "ERROR: Mysql启动失败,请检查原因"
        echo
        exit
    fi

    # 获取数据库临时密码, 并进行展示
    password="$(cat ${installdir}/logs/mysql.err | grep 'temporary password' | cut -d ' ' -f11)"

    echo
    echo "当前密码是: "${password}
    echo "请使用下面的命令更新数据库密码:"
    echo "SET PASSWORD = PASSWORD('your new password');"
    echo "ALTER user 'root'@'localhost' PASSWORD EXPIRE NEVER;"
    echo "FLUSH PRIVILEGES;"
    echo

    echo "INFO: Mysql install successfully"
    echo
}

clean_file(){
    cd ../ && rm -rf mysql-*
}

do_install() {
    check_param
    download_source_code
    before_install
    make_install
    add_mysql_config
    init_mysql_database
    clean_file
}

do_install