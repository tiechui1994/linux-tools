#!/bin/bash

#----------------------------------------------------
# File: install.sh
# Contents: install mysql-5.7 on centos 7
# Date: 8/19/19
#----------------------------------------------------

version="5.7.24-1.el7" # mysql version

check_user() {
    if [[ $(whoami) != "root" ]]; then
        echo "Please use root execute script"
        exit -1
    fi
}

check_os_version() {
    if [[ -e "/etc/centos-release" ]]; then
        release=$(cat /etc/centos-release|cut -d ' ' -f1)
        version=$(cat /etc/centos-release|cut -d ' ' -f4)
    fi

    if [[ -e "/etc/redhat-release" ]]; then
        release=$(cat /etc/redhat-release|cut -d ' ' -f1)
        version=$(cat /etc/redhat-release|cut -d ' ' -f4)
    fi

    regex="^7.[0-9]{1}.*"
    if [[ ${release} == "CentOS" || ${release} == "REHL" ]] && [[ ${version} =~ ${regex} ]]; then
        echo "The Current OS is: ${release} ${version}"
    else
        echo "Please Install REHL 7 / CentOS 7"
        exit -2
    fi
}

check_mysql() {
    cmd="$(command -v 'mysqld')"
    if [[ $? -eq 0 ]]; then
        echo "MySQL server exists. Version is: $(${cmd} --verbose --version)"
        exit -3
    fi
}

uninstall_conflict_lib() {
    # CentOS 7 版本的 mariadb-libs 版本和新安装的 mysql-community-libs 有冲突.
    yum -y mariadb-libs > /dev/null 2>&1
}

download_rpm() {
    echo "Start download rpm files ..."

    url="https://mirrors.cloud.tencent.com/mysql/yum/mysql57-community-el7"
    files=([0]=mysql-community-server-$version.x86_64.rpm
           [1]=mysql-community-client-$version.x86_64.rpm
           [2]=mysql-community-libs-$version.x86_64.rpm
           [3]=mysql-community-common-$version.x86_64.rpm)

    for i in ${files[@]}; do
        if [[ -e "/bin/wget" ]]; then
            wget "$url/$i" > /dev/null 2>&1
            continue
        fi

        if [[ -e "/bin/curl" ]]; then
            curl -o "$i" "$url/$i" > /dev/null 2>&1
            continue
        fi
    done

    echo "End download rpm files ..."
}

install_rpm() {
    echo "Install rpm..."

    yum install -y mysql-community-*.rpm
    if [[ $? -eq 0 ]]; then
        count=$(rpm -qa|grep -E "mysql-community-.*?-$version.x86_64"|wc -l)
        if [[ ${count} -eq 4 ]]; then
            echo "Install MySQL-$version Success !!!"
            return 0
        fi
    fi

    echo "Install MySQL-$version Failed, Please Check Reason."
    exit -4
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
    systemctl start mysqld.service
    if [[ $? -eq 0 ]]; then
        old_pwd=$(cat /var/log/mysqld.log | grep 'temporary password' | cut -d ' ' -f11)
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
            echo "Update Password Success"
            return
        else
            echo "Update Password Failed. Please Check Reason"
            exit -5
        fi
    fi

    echo "Start MySQL Failed, Please Check Reason."
    exit -6
}

install(){
    check_user
    check_os_version
    check_mysql
    uninstall_conflict_lib
    init_mysql
}

install
