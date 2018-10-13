#!/bin/sh

#====================================================
# redis 安装脚本
#====================================================

command_exists() {
	command -v "$@" > /dev/null 2>&1
}

VERSION="4.0.0"
BASE_URL="https://codeload.github.com/antirez/redis/tar.gz"
WORK_DIR=$(pwd)/redis-${VERSION}
INSTALL_DIR="/opt/local/redis"

if [ "$(whoami)" != "root" ]; then
    echo "Please use root privileges to execute"
fi

# 下载源代码
if ! command_exists curl; then
    apt-get update && \
    apt-get install curl
fi

curl -o redis-${VERSION}.tar.gz ${BASE_URL}/${VERSION} && \
tar -zvxf redis-${VERSION}.tar.gz && \
cd ${WORK_DIR}

# 目录检测
if [ -e ${INSTALL_DIR} ];then
    rm -rf ${INSTALL_DIR}
else
    mkdir -p ${INSTALL_DIR} && rm -rf ${INSTALL_DIR}
fi

# 编译
make && make PREFIX=${INSTALL_DIR} install

# 修正配置文件
mkdir -p ${INSTALL_DIR}/conf && \
cp redis.conf ${INSTALL_DIR}/conf && \
cp sentinel.conf ${INSTALL_DIR}/conf

if [ -e /etc/init.d/redis ];then
   rm -rf /etc/init.d/redis
fi

mkdir ${INSTALL_DIR}/data && \
mkdir ${INSTALL_DIR}/logs

cp utils/redis_init_script /etc/init.d/redis && \
sed -i \
    -e 's|^EXEC=.*|EXEC=/opt/local/redis/bin/redis-server|g' \
    -e 's|^CLIEXEC=.*|CLIEXEC=/opt/local/redis/bin/redis-cli|g' \
    -e 's|^PIDFILE=.*|PIDFILE=/opt/local/redis/data/redis_${REDISPORT}.pid|g' \
    -e 's|^CONF=.*|CONF=/opt/local/redis/conf/redis.conf|g'\
    /etc/init.d/redis

chmod a+x /etc/init.d/redis && \
update-rc.d redis defaults && \
update-rc.d redis disable $(runlevel | cut -d ' ' -f2)

sed -i \
    -e 's|^daemonize.*|daemonize yes|g' \
    -e 's|^supervised.*|supervised auto|g' \
    -e 's|^pidfile.*|pidfile /opt/local/redis/data/redis_6379.pid|g' \
    -e 's|^logfile.*|logfile /opt/local/redis/logs/redis.log|g' \
    ${INSTALL_DIR}/conf/redis.conf

# 启动服务
systemctl daemon-reload && \
service redis start
if [ -n $(netstat -an|grep '127.0.0.1:6379') ];then
    echo "Redis Installed Successful"
fi

# 链接
ln -sf ${INSTALL_DIR}/bin/redis-cli /usr/local/bin/redis-cli && \
ln -sf ${INSTALL_DIR}/bin/redis-server /usr/local/bin/redis-server

# 清理文件
cd ../ &&
rm -rf redis-${VERSION}*
