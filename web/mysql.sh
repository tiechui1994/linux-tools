#!/bin/bash

#----------------------------------------------------
# File: mysql.sh
# Contents: 安装mysql服务
# Date: 18-12-12
#----------------------------------------------------


version=5.7.24
workdir=$(pwd)
installdir=/opt/share/local/mysql

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
        apt-get update && apt-get install axel -y
    fi
}

download_mysql() {
    mysql=${workdir}/mysql-${version}

    if [[ ! -e ${mysql} ]]; then
        url="http://cdn.mysql.com/Downloads/MySQL-5.7/mysql-$version.tar.gz"
        axel -n 100 ${url} -o mysql-${version}.tar.gz

        mkdir ${mysql} && \
        tar -zvxf mysql-${version}.tar.gz -C ${mysql} --strip-components 1
    fi


     if [[ ! -e ${mysql}/boost ]]; then
        boost="https://nchc.dl.sourceforge.net/project/boost/boost/1.59.0/boost_1_59_0.tar.gz"
        mkdir -p ${mysql}/boost && \
        axel -n 100 ${boost} -o ${mysql}/boost/
     fi
}

install_depency(){
    # install depend
    apt-get update && \
    apt-get install cmake build-essential libncurses5-dev bison -y

    # add new user
    if [[ -z "$(cat /etc/group | grep -E '^mysql:')" ]]; then
       groupadd -r mysql
    fi

    if [[ -z "$(cat /etc/passwd | grep -E '^mysql:')" ]]; then
        useradd -r -g mysql -s /sbin/nologin mysql
    fi

    # create mysql dir
    rm -rf ${installdir} && \
    mkdir -p ${installdir}/mysql && \
    mkdir -p ${installdir}/data && \
    mkdir -p ${installdir}/logs && \
    mkdir -p ${installdir}/tmp && \
    mkdir -p ${installdir}/conf
}

make_install() {
    # cmake
    cd ${workdir}/mysql-${version} && \
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

    # install
    cpu=$(cat /proc/cpuinfo |grep 'processor'|wc -l)
    make -j${cpu} && make install
}

add_config() {
    # create config file my.cnf
    if [[ -e ${installdir}/conf/my.cnf ]]; then
       rm -rf ${installdir}/conf/my.cnf
    fi

    cat > ${installdir}/conf/my.cnf << EOF
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

init_database() {
    # clear logs and data
    rm -rf ${installdir}/logs/* && \
    rm -rf ${installdir}/data/* && \
    ${installdir}/mysql/bin/mysqld \
    --initialize \
    --user=mysql \
    --basedir=${installdir}/mysql \
    --datadir=${installdir}/data

    # check  logs/mysql.err, if has error, need to resolve by self
    if cat ${installdir}/logs/mysql.err | grep -E -i '\[error\]'; then
        echo
        echo "ERROR: Mysql初始化出现问题, 请查看详情文件${installdir}/logs/mysql.err自己解决"
        echo
        exit
    fi

    # start mysqld service
    service mysqld start
    if [[ -z "$(service mysqld status |grep -o 'Active: active (running)')" ]]; then
        echo
        echo "ERROR: Mysql启动失败,请检查原因"
        echo
        exit
    fi

    # check password
    password="$(cat ${installdir}/logs/mysql.err | grep 'temporary password' | cut -d ' ' -f11)"

    echo
    echo "当前密码是: $password"
    echo "请使用下面的命令更新数据库密码:"
    echo "mysql -u root --password=$password"
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
    download_mysql
    install_depency
    make_install
    add_config
    init_database
    clean_file
}

do_install