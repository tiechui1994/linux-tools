#!/bin/bash

#----------------------------------------------------
# File: pam-ssh-2fa.sh
# Contents: ssh pam 2fa
# Date: 1/5/21
# Doc: http://blog.gaoyuan.xyz/2017/01/05/2fa-a-programmers-perspective/
# Doc: https://www.digitalocean.com/community/tutorials/how-to-set-up-multi-factor-authentication-for-ssh-on-ubuntu-16-04
#----------------------------------------------------

declare -r workdir=$(pwd)
declare -r version=1.09
declare -r installdir=/opt/pam/google

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

download_libpam() {
    url="https://codeload.github.com/google/google-authenticator-libpam/tar.gz/$version"
    common_download "google-authenticator-libpam" ${url}
    return $?
}

check_param() {
    if [[ "$(whoami)" != "root" ]]; then
        log_error "please use root privileges to execute"
        exit
    fi

    command -v sshd > /dev/null 2>&1
    if [[ $? != 0 ]]; then
        log_warn "The program 'sshd' is currently not installed. You can install it by typing:"
        log_warn "sudo apt install openssh-server"
        exit
    fi
}

insatll_depend() {
    apt-get update && \
    apt-get install autoconf gcc libtool libpam0g-dev make
}

build() {
    rm -rf ${installdir} && \
    mkdir -p ${installdir}

    cd ${workdir}/google-authenticator-libpam
    ./bootstrap.sh
    if [[ $? != 0 ]];then
        log_error "bootstrap init fail"
        return ${failure}
    fi

    ./configure \
    --prefix=${installdir}
    if [[ $? != 0 ]]; then
        log_error "configure fail"
        return ${failure}
    fi

    make
    if [[ $? -ne 0 ]]; then
        log_error "make fail"
        return ${failure}
    fi

    make install
    if [[ $? -ne 0 ]]; then
        log_error "install fail"
        return ${failure}
    fi

    ln -sf ${installdir}/bin/google-authenticator /usr/local/bin/google-authenticator
    ln -sf ${installdir}/lib/security/pam_google_authenticator.so /lib/x86_64-linux-gnu/security/pam_google_authenticator.so
}

config_sshd() {
    cp /etc/ssh/sshd_config /tmp/sshd_config.backup
    cp /etc/pam.d/sshd /tmp/sshd.backup

    # change sshd_config
    awk -v challege=0 -v usepam=0 -v methods=0 '
    {
       if ( /^[#]?[\s]*ChallengeResponseAuthentication/ ) {
          print("ChallengeResponseAuthentication yes")
          challege=1
       } else if ( /^[#]?[\s]*UsePAM/ ) {
          print("UsePAM yes")
          usepam=1
       } else if ( /^[#]?[\s]*AuthenticationMethods/ ) {
          print("AuthenticationMethods publickey,keyboard-interactive")
          methods=1
       } else {
          print($0)
       }
    };
    END {
        if ( challege==0 ) {
            print("ChallengeResponseAuthentication yes")
        }
        if ( usepam==0 ) {
            print("UsePAM yes")
        }
        if ( methods==0 ) {
            print("AuthenticationMethods publickey,keyboard-interactive")
        }
    }' /tmp/sshd_config.backup > /tmp/sshd_config && \
    mv /tmp/sshd_config /etc/ssh/sshd_config
    if [[ $? -ne 0 ]]; then
        log_error "update sshd_config fail"
        mv /tmp/sshd_config.backup /etc/ssh/sshd_config
        return ${failure}
    fi

    grep -o -E '^auth.*?pam_google_authenticator.so' /etc/pam.d/sshd
    if [[ $? = 0 ]]; then
        log_warn "PAM sshd pam_google_authenticator success"
        log_info "Please add authenticate user:"
        log_info "su - zhangsan"
        log_info "google-authenticator"
        return ${success}
    fi

    # change pam sshd
    lines=($(grep -n -o -E '^account' /etc/pam.d/sshd | grep -o -E '^[[:digit:]]+'))
    declare -i lineno=0
    if [[ ${#lines} -gt 0 ]]; then
        lineno=${lines[-1]}
        lineno+=1
    fi

    content="auth required pam_google_authenticator.so nullok"
    awk -v content="$content" -v lineno=${lineno}  '
    {
       if ( NR == lineno ) {
          print($0)
          print("# Google code")
          print(content)
          print("")
       } else if ( /^@include common-auth/ ) {
          print("#", $0)
       } else {
          print($0)
       }
    }' /tmp/sshd.backup > /tmp/sshd

    if [[ $? -ne 0 ]]; then
        log_error "update pam sshd pam_google_authenticator fail"
        mv /tmp/sshd.backup /etc/pam.d/sshd
        return ${failure}
    fi

    mv /tmp/sshd /etc/pam.d/sshd && \
    service sshd restart
    if [[ $? -ne 0 ]]; then
        log_error "restart sshd fail"
        mv /tmp/sshd_config.backup /etc/ssh/sshd_config && service sshd restart
        return ${failure}
    fi

    log_info "PAM sshd pam_google_authenticator success"
    log_info "Please add authenticate user:"
    log_info "su - zhangsan"
    log_info "google-authenticator"
}

clean_file() {
    rm -rf ${workdir}/google-authenticator-libpam
    rm -rf ${workdir}/google-authenticator-libpam.tar.gz
}


do_install() {
    check_param

    insatll_depend
    if [[ $? != ${success} ]]; then
        return
    fi

    download_libpam
    if [[ $? != ${success} ]]; then
        return
    fi

    build
    if [[ $? != ${success} ]]; then
        return
    fi

    config_sshd
    if [[ $? != ${success} ]]; then
        return
    fi

    clean_file
}

do_install