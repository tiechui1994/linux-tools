#!/bin/bash

#----------------------------------------------------
# File: ${FILE}
# Contents: 
# Date: 8/20/19
#----------------------------------------------------


jdk="8u66"

check_user() {
    if [[ $(whoami) != "root" ]]; then
        echo "Please use root execute script"
        exit -1
    fi
}

check_jdk() {
    if [[ ${JAVA_HOME} != "" ]]; then
        echo "Java has existed. Info is:"
        ${JAVA_HOME}/bin/java -version
        exit -2
    fi
}

download_jdk() {
    echo "Start download jdk files ..."
    url="http://monalisa.cern.ch/MONALISA/download/java"

    if [[ -e "/usr/bin/wget" ]]; then
        wget "$url/jdk-$jdk-linux-x64.tar.gz" > /dev/null 2>&1
        return
    fi

    if [[ -e "/usr/bin/curl" ]]; then
        curl -o "jdk-$jdk-linux-x64.tar.gz" "$url/jdk-$jdk-linux-x64.tar.gz" > /dev/null 2>&1
        return
    fi
}

install_jdk() {
    echo "Start install jdk ..."

    cmd="$(command -v tar)"
    if [[ $? -ne 0 ]]; then
        apt-get update && apt-get install tar -y
        cmd="$(command -v tar)"
    fi

    8u66

    dir="jdk1.${jdk//u/.0_}" # jdk1.8.0_66
    ${cmd} -zvxf "jdk-$jdk-linux-x64.tar.gz" && mv ${jdk} /opt/jdk

    echo '# JDK configure'
    echo 'export JAVA_HOME=/opt/jdk' >> /etc/bash.bashrc
    echo 'export JRE_HOME=$JAVA_HOME/jre' >> /etc/bash.bashrc
    echo 'export PATH=$PATH:$JAVA_HOME/bin:$JRE_HOME/bin' >> /etc/bash.bashrc
    echo 'export CLASSPATH=.:$JAVA_HOME/lib:$JRE_HOME/lib:$CLASSPATH' >> /etc/bash.bashrc

    source /etc/bash.bashrc

    echo "JAVA VERSION is: "
    ${JAVA_HOME}/bin/java -version
}

install() {
    check_user
    check_jdk
    download_jdk
    install_jdk
}

install