#!/bin/bash

#=========================================
# 带参数的shell脚本参数处理方式
#=========================================

while [ $# -gt 0 ]; do
    case "$1" in
		--mirror)
			echo "$2"
			# shift 等价于 shift 1
            shift
			;;
		--dry-run)
			echo 1
			;;
		--*)
			echo "Illegal option $1"
			;;
	esac
	# 重置参数, shift N, 即将参数 $N+1, $N+2, ... 重置为 $1, $2, ..
	shift $(( $# > 0 ? 1 : 0 ))
done
