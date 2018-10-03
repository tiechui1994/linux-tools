#!/bin/bash

#==============================================================
# 系统: ubuntu
#
# 源码安装 mysql
#==============================================================

VERSION=5.7.23
WORKDIR=`pwd`/mysql-${VERSION}
INSTALL_DIR=/opt/local/mysql
USER=`whoami`

if [ "${USER}" != "root" ]; then
    echo "请使用root权限执行"
    exit
fi

##############################  准备工作  #######################################
# 安装依赖包
apt-get update && \
apt-get install cmake build-essential libncurses5-dev bison -y

# 安装下载工具
if [ -z `whereis axel | grep -E -o '/usr/bin/axel'` ]; then
   apt-get update && sudo apt-get install axel -y
fi


# 下载源码包
axel -n 100 https://cdn.mysql.com//Downloads/MySQL-5.7/mysql-${VERSION}.tar.gz \
-o mysql-${VERSION}.tar.gz

# 解压源文件
if [ -e ${WORKDIR} ]; then
   rm -rf ${WORKDIR}
fi

mkdir ${WORKDIR} && \
tar -zvxf mysql-${VERSION}.tar.gz -C ${WORKDIR} --strip-components 1 && \
cd ${WORKDIR}

# 下载boost依赖库文件
mkdir -p ${WORKDIR}/boost && \
axel -n 100 https://nchc.dl.sourceforge.net/project/boost/boost/1.59.0/boost_1_59_0.tar.gz \
-o ${WORKDIR}/boost/



##############################  编译安装  ####################################
# 增加用户
if [ -z `cat /etc/group | grep -E '^mysql:'` ]; then
   groupadd -r mysql
fi

if [ -z `cat /etc/password | grep -E '^mysql:'` ]; then
    useradd -r -g mysql -s /sbin/nologin mysql
fi

# 创建文件
rm -rf ${INSTALL_DIR} && \
mkdir -p ${INSTALL_DIR}/mysql && \
mkdir -p ${INSTALL_DIR}/data && \
mkdir -p ${INSTALL_DIR}/logs && \
mkdir -p ${INSTALL_DIR}/tmp && \
mkdir -p ${INSTALL_DIR}/conf

# cmake编译
cd ${WORKDIR} && \
cmake . \
-DCMAKE_INSTALL_PREFIX=${INSTALL_DIR}/mysql \
-DMYSQL_DATADIR=${INSTALL_DIR}/data \
-DSYSCONFDIR=${INSTALL_DIR}/conf \
-DDOWNLOAD_BOOST=1 \
-DWITH_BOOST=${WORKDIR}/boost \
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
cpu=`cat /proc/cpuinfo |grep 'processor'|wc -l`
make -j${cpu} && make install



############################  增加数据库配置  #####################################
# 创建配置文件my.cnf(确保文件没有被创建)
if [ -e ${INSTALL_DIR}/conf/my.cnf ];then
   rm -rf ${INSTALL_DIR}/conf/my.cnf
fi


# 写入配置内容
cat >> ${INSTALL_DIR}/conf/my.cnf << EOF
[client]
    port=3306
    socket=${INSTALL_DIR}/data/mysql.sock
    default-character-set=utf8

[mysqld]
    port=3306
    user=mysql
    socket=${INSTALL_DIR}/data/mysql.sock
    pid-file=${INSTALL_DIR}/data/mysql.pid
    basedir=${INSTALL_DIR}/mysql  # 安装目录
    datadir=${INSTALL_DIR}/data   # 数据目录
    tmpdir=${INSTALL_DIR}/tmp     # 临时目录
    character-set-server=utf8
    log_error=${INSTALL_DIR}/logs/mysql.err

    server-id=2
    log_bin=${INSTALL_DIR}/logs/binlog

    general_log_file=${INSTALL_DIR}/logs/general_log
    general_log=1

    slow_query_log=ON
    long_query_time=2
    slow_query_log_file=${INSTALL_DIR}/logs/query_log
    log_queries_not_using_indexes=ON

    bulk_insert_buffer_size=64M
    binlog_rows_query_log_events=ON

    sort_buffer_size=64M #默认是128K
    binlog_format=row #默认是mixed
    join_buffer_size=128M #默认是256K
    max_allowed_packet=512M #默认是16M
EOF

# 修改用户所有者权限
chown -R mysql:mysql ${INSTALL_DIR}

# 服务配置
cp ${INSTALL_DIR}/mysql/support-files/mysql.server /etc/init.d/mysqld && \
update-rc.d mysqld defaults


##########################  数据库数据的初始化  ##############################
# 初始化数据(需要清空logs和data目录下的所有的内容)
rm -rf ${INSTALL_DIR}/logs/* && \
rm -rf ${INSTALL_DIR}/data/* && \
${INSTALL_DIR}/mysql/bin/mysqld \
 --initialize \
--user=mysql \
--basedir=${INSTALL_DIR}/mysql \
--datadir=${INSTALL_DIR}/data

# 数据库初始化检查
if cat ${INSTALL_DIR}/logs/mysql.err | grep -E -i '\[error\]'; then
    echo "mysql初始化出现问题, 请查看详情文件${INSTALL_DIR}/logs/mysql.err自己解决"
    exit
fi

# 启动服务
service mysqld start
if [ -z "$(service mysqld status |grep -o 'Active: active (running)')" ];then
    echo "mysql启动失败,请检查原因"
    exit
fi

# 获取数据库临时密码, 并进行展示
password="$(cat ${INSTALL_DIR}/logs/mysql.err | grep 'temporary password' | cut -d ' ' -f11)"

echo "======================================="
echo "当前密码是: "${password}
echo "请使用下面的命令更新数据库密码:"
echo "SET PASSWORD = PASSWORD('your new password');"
echo "ALTER USER 'root'@'localhost' PASSWORD EXPIRE NEVER;"
echo "FLUSH PRIVILEGES;"
echo "======================================="

echo "mysql install success!!"



############################  文件清理  #############################
cd ../ && \
rm -rf mysql-*