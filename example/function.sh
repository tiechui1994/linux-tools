#!/bin/bash

#------------------------------------------------
#  基本命令函数
#------------------------------------------------

# 查找一个命令是否存在[相同功能的有type, which(不建议使用,性能和返回值不太理想)]
# 1> /dev/null 标准输出(通常把1去掉)
# 2> /dev/null 标准错误输出,  2>&1, 将标准输出,标准错误输出指定为同一路径, 注意格式
# 一遍标准输出在标准错误输出的前面.
# 1>> /dev/null 追加
# 2>> /dev/null 错误追加
command_exists() {
	command -v "$@" > /dev/null 2>&1
}


# . 命令, 从指定的文件当中去取所有命令语句并在当前进程中执行(常用于进程间共享参数)
# . filename 读取filename并且执行语句
point_command() {
    if [ -r /etc/os-release ]; then
        name="$(. /ect/os-release && echo "$ID")"
        echo ${name}
    fi
}

# 输出大段原始文本
output_text() {
    user=$(whoami)
    cat >&2 <<-'EOF' # 错误输出
	Hello ${user}:
	    This big text!!
	EOF


	cat >&1 <<-'EOF' # 标准输出
	Hello ${user}:
	    This big text!!
	EOF
}

# 获取发行商
get_distributor() {
	distributor=""
	if [ -r /etc/os-release ]; then
		distributor="$(. /etc/os-release && echo "${ID}")"
	fi
	echo "${distributor}"
}

get_codename() {
   distributor=$( get_distributor )
   distributor="$(echo "$distributor" | tr '[:upper:]' '[:lower:]')"

   case "${distributor}" in
        ubuntu)
			if command_exists lsb_release; then
				codename="$(lsb_release --codename | cut -f2)"
			fi

			if [ -z "${codename}" ] && [ -r /etc/lsb-release ]; then
				codename="$(. /etc/lsb-release && echo "$DISTRIB_CODENAME")"
			fi
		;;

		debian|raspbian)
			codename="$(sed 's/\/.*//' /etc/debian_version | sed 's/\..*//')"
			case "$codename" in
				9)
					codename="stretch"
				;;
				8)
					codename="jessie"
				;;
				7)
					codename="wheezy"
				;;
			esac
		;;

		centos)
			if [ -z "$codename" ] && [ -r /etc/os-release ]; then
				codename="$(. /etc/os-release && echo "$VERSION_ID")"
			fi
		;;

		rhel|ol|sles)
			ee_notice "$distributor"
			exit 1
			;;

		*)
			if command_exists lsb_release; then
				codename="$(lsb_release --release | cut -f2)"
			fi

			if [ -z "$codename" ] && [ -r /etc/os-release ]; then
				codename="$(. /etc/os-release && echo "$VERSION_ID")"
			fi
		;;

	esac

	echo "$codename"
}

install_depend() {
    distributor=$( get_distributor )
    distributor="$(echo "$distributor" | tr '[:upper:]' '[:lower:]')"

    case "${distributor}" in
		ubuntu|debian|raspbian)
			echo "${distributor}"
			exit 0
			;;
		centos|fedora)
		    echo "${distributor}"
			exit 0
			;;
	esac
}

install_depend
