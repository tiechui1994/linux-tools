#!/bin/bash

#----------------------------------------------------
# File: mount.sh
# Contents: 文件启动挂载, 在/etc/fstab当中挂载
# Date: 18-12-10
#----------------------------------------------------

#---------------------------------------------------------------------------------------------------
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
#---------------------------------------------------------------------------------------------------

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

device=
point=
uuid=
type="ext4"
options="defaults"
dump=0
pass=1


check(){
    if [[ "$(whoami)" != "root" ]]; then
        log_error "Please execute the script with root privileges"
        exit
    fi
    if [[ -z $(command -v "getopt") ]]; then
        log_error "cmd getopt not exist, please install it"
        exit
    fi
    if [[ -z $(command -v "blkid") ]]; then
        log_error "cmd blkid not exist, please install it"
        exit
    fi
    if [[ -z $(command -v "realpath") ]]; then
        log_error "cmd realpath not exist, please install it"
        exit
    fi
}

usage() {
    read -r -d '' conf <<-'EOF'
mount-fs [<options>]
 -h, --help                     Print this message
 -d, --device=<dev>             Set need mount device, eg: /dev/sdb
 -p, --point=<point dir>        Set mount point dir, eg: /media/user/usb
 -o, --options=<options>        Set optional mount options

EOF
    printf "$conf\n"
    exit
}

handle_params(){
    TEMP=`getopt --options d:p:o::h --longoptions dev:,point:,options::,help \
         -n 'param.bash' -- "$@"`
    if [[ $? != 0 ]]; then
        echo "Terminating..." >&2
        exit 1
    fi

    eval set -- ${TEMP}
    while true ; do
        case "$1" in
            -d|--dev)
                device=$2
                shift 2;;
            -p|--point)
                point=$2
                shift 2;;
            -o|--options)
                options=$2
                shift 2;;
            -h|--help)
                usage
                shift;;
            --)
                shift
                break;;
            *)
                log_error "invalid params."
                exit 1;;
        esac
    done

    if [[ -z ${device} || -z ${point} ]]; then
        log_error "The options --dev=DEV and --point=POINT must be set !!"
        exit 1
    fi

    declare -A var=()
    declare $(blkid "$device" | awk '{
    for (i = 2; i <= NF; i++) {
        split($i, x, "=");
        print("var["x[1]"]="x[2]);
      }
    }')

    if [[ ${#var[@]} == 0 ]]; then
        log_error "Please input valid device."
        exit 1;
    fi

    uuid="${var["UUID"]}"
    type="${var["TYPE"]}"

    # 去掉`"`字符串
    uuid=${uuid//\"/}
    type=${type//\"/}

    if [[ ! -d "${point}" ]]; then
        mkdir -p "${point}"
    fi

    point=$(realpath "$point")
}

mount_record() {
    exist=$(grep -o -E "($uuid|$point)" /etc/fstab)
    if [[ -n ${exist} ]]; then
        log_info "$device or $point has mounted."
    fi

    read -r -d '' conf <<-EOF
# ${point} was on ${device} during installation
UUID=${uuid}    ${point}  ${type}   ${options}    ${dump}   ${pass}
EOF

    printf "$conf\n" >>  /etc/fstab
}

do_install(){
    check
    handle_params $*
    mount_record
}

do_install $*
