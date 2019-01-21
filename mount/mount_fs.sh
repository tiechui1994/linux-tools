#!/bin/bash

#----------------------------------------------------
# File: mount.sh
# Contents: 文件启动挂载, 在/etc/fstab当中挂载
# Date: 18-12-10
#----------------------------------------------------

# 挂载参数说明:
#
# uuid, 文件系统设备的唯一标示
# point, 挂载点, 必须是一个目录, 而且挂载之前已经创建
# type, 文件类型, 常用文件类型有 ext4, ext3, vfat(针对uefi启动的/boot/efi), swap(交换分区)
#
# options, 文件系统参数,
#   async/sync, 设置是否同步方式运行, 默认是async
#   auto/noauto, 当执行mount -a的命令时, 此文件系统是否被主动挂载, 默认是auto
#   rw/ro, 是否以"读写/只读"模式挂载
#   exec/noexec, 限制此文件系统内是否能够进行"执行"的操作
#   user/nouser, 是否允许用户使用mount命令挂载
#   suid/nosuid, 是否允许SUID的存在
#   Usrquota, 启动文件系统支持磁盘配额模式
#   Grpquota, 启动文件系统支持群组磁盘配额模式
#   defaults, 同时具备的默认参数设置
#
# dump, 备份, 0表示不做dump备份, 1表示每天进行dump的操作, 2表示不定日期进行dump操作
# pass, 是否检验扇区(开机时), 0表示不检验, 1表示最早检验 2表示1级别检验完成之后检验
#

uuid=
point=
type="ext4"
options="defaults"
dump=0
pass=1
dev=

check_user(){
    if [[ "$(whoami)" != "root" ]];then
        echo
        echo "ERROR: Please execute the script with root privileges"
        echo
        exit
    fi
}

set_mount_param(){
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dev)
                dev="$2"
                shift
                ;;
            --point)
                point="$2"
                shift
                ;;
            --options | -o )
                options="$2"
                shift
                ;;
            --dump)
                dump=$2
                shift
                ;;
            --pass)
               pass=$2
               shift
               ;;
            --*)
                echo "Illegal option $1"
                ;;
        esac
        # 重置参数, shift N, 即将参数 $N+1, $N+2, ... 重置为 $1, $2, ..
        shift $(( $# > 0 ? 1 : 0 ))
    done

    if [[ -z ${dev} || -z ${point} ]]; then
        echo
        echo "ERROR: Must provide mount POINT and DEV."
        echo "mount_fs --dev DEV --point POINT [--options|-o OPTION] [--pass PASS] [--dump DUMP]"
        echo
        exit
    fi

    declare -A var=()
    declare $( blkid | grep -E "^/dev/sdb"|awk '{
    for (i = 2; i <= NF; i++) {
        split($i, x, "=");
        print("var["x[1]"]="x[2]);
      }
    }')

    if [[ ${#var[@]} == 0 ]];then
        echo
        echo "ERROR: Please input validation DEV."
        echo
        exit
    fi

    uuid=${var["UUID"]}
    type=${var["TYPE"]}

    if [[ $(echo "${point}"| grep -E '^[^/]') ]]; then
        point="$(pwd)/${point}"
    fi

    if [[ -e "${point}" && -f "${point}" ]];then
        echo
        echo "ERROR: The POINT: ${point} is a file. The POINT need to be a dir"
        echo
        exit
    fi

    if [[ -e "${point}" && -d "${point}" ]];then
        return
    else
        mkdir -p "${point}"
    fi
}

do_install(){
    check_user
    set_mount_param $*

    # 添加挂在记录
    cat >> /etc/fstab << EOF
# ${point} was on ${dev} during installation
UUID=${uuid} ${point}            ${type}    ${options}        ${dump}       ${pass}
EOF

}

do_install $*
