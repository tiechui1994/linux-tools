#!/bin/bash

#----------------------------------------------------
# File: install.sh
# Contents: install mysql-5.7 on ubuntu 14.04/16.04
# Date: 8/19/19
#----------------------------------------------------

release=""
version="5.7.24"

check_user() {
    if [[ $(whoami) != "root" ]]; then
        echo "Please use root execute script"
        exit -1
    fi
}

check_os_version() {
    if [[ -e "/etc/lsb-release" ]]; then
        . /etc/lsb-release
        release="${DISTRIB_RELEASE}"
    fi

    if [[ -e "/etc/issue.net" ]];then
        release="$(cat /etc/issue.net|cut -d ' ' -f2|grep -E -o '1[0-9]{1}.[0-9]{2}')"
    fi

    echo "Current Ubuntu Version: $version"
}

check_mysql() {
    cmd="$(command -v 'mysqld')"
    if [[ $? -eq 0 ]]; then
        echo "MySQL server exists. Version is: $(${cmd} --verbose --version)"
        exit -2
    fi
}

download_deb() {
    echo "Start download deb files ..."
    url="https://mirrors.cloud.tencent.com/mysql/apt/ubuntu/pool/mysql-5.7/m/mysql-community"
    files=([0]="mysql-community-server_${version}-1ubuntu${release}_amd64.deb"
           [1]="mysql-community-client_${version}-1ubuntu${release}_amd64.deb"
           [2]="mysql-common_${version}-1ubuntu${release}_amd64.deb"
           [3]="mysql-client_${version}-1ubuntu${release}_amd64.deb")

    for i in ${files[@]}; do
        echo "url: $url/$i"
        if [[ -e "/usr/bin/wget" ]]; then
            wget "$url/$i" > /dev/null 2>&1
            continue
        fi

        if [[ -e "/usr/bin/curl" ]]; then
            curl -o "$i" "$url/$i" > /dev/null 2>&1
            continue
        fi
    done

    echo "End download rpm files ..."
}

install_deb() {
    echo "Install deb ..."

    apt-get update && \
    apt-get install -y libaio1 libmecab2

    dpkg -i mysql-*.deb
    if [[ $? -eq 0 ]]; then
        count=$(dpkg -l|grep mysql|grep ${version}-1ubuntu${release}|wc -l)
        if [[ ${count} -eq 4 ]]; then
            echo "Install MySQL-$version Success !!!"
            return 0
        fi
    fi

    echo "Install MySQL-$version Failed, Please Check Reason."
    exit -3
}

_input_password() {
     read -p "Input your root password: " new
     len=${#new}
     if [[ ${len} -lt 6 ]]; then
         _input_password
         return
     fi

     echo ${new}
}

init_mysql() {
    if [[ ${release} == "14.04" ]]; then
        service mysql start
    fi

    if [[ ${release} == "16.04" ||  ${release} == "18.04" ]]; then
        systemctl start mysql.service
    fi

    if [[ $? -eq 0 ]]; then
        old_pwd=$(cat /var/log/mysql/error.log | grep 'temporary password' | cut -d ' ' -f11)
        new_pwd=$(_input_password)
        cat > /tmp/update.sql <<- EOF
        SET global validate_password_policy=LOW;
        SET global validate_password_length=6;
        ALTER USER 'root'@'localhost' IDENTIFIED BY "${new_pwd}";
        SET global validate_password_policy=MEDIUM;
        SET global validate_password_length=8;
        COMMIT;
EOF
        mysql --connect-expired-password -h localhost -u root -p${old_pwd} mysql </tmp/update.sql > /dev/null 2>&1
        if [[ $? -eq 0 ]]; then
            rm -rf /tmp/update.sql
            echo "Update Password Success"
            return
        else
            rm -rf /tmp/update.sql
            echo "Update Password Failed. Please Check Reason"
            exit -4
        fi
    fi

    echo "Start MySQL Failed, Please Check Reason."
    exit -5
}

install(){
    check_user
    check_os_version
    check_mysql
    init_mysql
    download_deb
    install_deb
    init_mysql
}

install
