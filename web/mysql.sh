#!/bin/bash

#----------------------------------------------------
# File: mysql.sh
# Contents: 安装mysql服务
# Date: 18-12-12
#----------------------------------------------------

declare -r version=5.7.32
declare -r workdir=$(pwd)
declare -r installdir=/opt/local/mysql

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

check() {
    if [[ "$(whoami)" != "root" ]]; then
        log_error "Please use root privileges to execute"
        exit
    fi
}

download_mysql() {
    url="https://mirrors.cloud.tencent.com/mysql/downloads/MySQL-5.7/mysql-$version.tar.gz"
    download "mysql.tar.gz" ${url} curl 1
    return $?
}

download_boost(){
    url="https://nchc.dl.sourceforge.net/project/boost/boost/1.59.0/boost_1_59_0.tar.gz"
    download "boost.tar.gz" ${url} curl 1
    if [[ $? -eq ${success} ]]; then
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
        return ${failure}
    fi

    # remove old directory
    rm -rf ${installdir}

    # in workspace
    cd "$workdir/mysql"

    # cmake
    cmake . \
    -DCMAKE_INSTALL_PREFIX=${installdir}/mysql \
    -DMYSQL_DATADIR=${installdir}/data \
    -DSYSCONFDIR=${installdir}/conf \
    -DDOWNLOAD_BOOST=1 \
    -DWITH_BOOST=${workdir}/mysql/boost \
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
        return ${failure}
    fi

    # make
    cpu=$(cat /proc/cpuinfo |grep 'processor'|wc -l)
    make -j ${cpu}
    if [[ $? -ne 0 ]]; then
        log_error "make fail, plaease check and try again..."
        return ${failure}
    fi

    make install
    if [[ $? -ne 0 ]]; then
        log_error "make install fail, plaease check and try again..."
        return ${failure}
    fi
}

add_service() {
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

    # update install dir owner
    chown -R mysql:mysql "$installdir"

    # create config file my.cnf
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

    regex='$dir'
    repl="$installdir"
    printf "%s" "${conf//$regex/$repl}" > ${installdir}/conf/my.cnf

    # add service config
    cp ${installdir}/mysql/support-files/mysql.server /etc/init.d/mysqld
    chmod a+x /etc/init.d/mysqld && update-rc.d mysqld defaults
    if [[ $? -ne 0 ]]; then
        log_error "update-rc failed"
        return ${failure}
    fi
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
        return ${failure}
    fi

    # check logs/mysql.err.
    error=$(grep -E -i -o '\[error\].*' "$installdir/logs/mysql.err")
    if [[ -n ${error} ]]; then
        log_error "mysql database init failed"
        log_error "error message:"
        log_error "$error"
        log_error "the detail message in file $installdir/logs/mysql.err"
        return ${failure}
    fi

    # start mysqld service
    systemctl daemon-reload && service mysqld start
    if [[ $? -ne 0 ]]; then
        log_error "mysqld service start failed, please check and trg again..."
        return ${failure}
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
}

clean_file(){
    rm -rf ${workdir}/mysql
    rm -rf ${workdir}/mysql.tar.gz
    rm -rf ${workdir}/boost
    rm -rf ${workdir}/boost.tar.gz
}

do_install() {
    check

    download_mysql
    if [[ $? -ne ${success} ]]; then
        return
    fi

    download_boost
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

    init_db
    if [[ $? -ne ${success} ]]; then
        return
    fi

    clean_file
}

do_install
