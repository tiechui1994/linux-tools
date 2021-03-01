#!/bin/bash

#----------------------------------------------------
# File: params.sh
# Contents: 带参数的shell脚本参数处理方式.
# Date: 19-3-22
#----------------------------------------------------

#---------------------------------------------------------------------------------------------------
# 手动遍历
#---------------------------------------------------------------------------------------------------
#!/bin/bash

#----------------------------------------------------
# File: ${FILE}
# Contents:
# Date: 3/1/21
#----------------------------------------------------

# --options 表示短选项(单个字母作为一个选项)
# --longoptions 表示长选项(一个单词作为选项, 需要使用符号 "," 进行分割)

# 选项含义(长,短选项需要保持一致)
# a   表示选项 a 没有参数. 合法格式: -a
# a:  表示选项 a 必须有一个参数. 合法格式: -a11 或 -a 11 或 --a-long=11 或 --a-long 11
# a:: 表示选项 a 可以有参数, 也可以没有参数. 合法格式: -a11 或 --a-long=11
# 注: 上面的 -a 表示短选项, --a-long 表示长选项
# 在后续的处理过程中需要遵照参数.

TEMP=`getopt --options ab:c:: --longoptions a-long,b-long:,c-long:: \
     -n 'param.bash' -- "$@"`

if [[ $? != 0 ]]; then
    echo "Terminating..." >&2
    exit 1
fi

# set 会重新排列参数的顺序, 也就是改变 $1,$2...$n的值, 这些值在getopt中重新排列过了
eval set -- ${TEMP}


while true ; do
    case "$1" in
        -a|--a-long)
            echo "Option a"
            shift ;;
        -b|--b-long)
            echo "Option b, argument [$2]"
            shift 2 ;;
        -c|--c-long)
            case "$2" in
                "")
                    echo "Option c, no argument" # 没有参数
                    shift 2 ;;
                *)
                    echo "Option c, argument [$2]" # 带有参数
                    shift 2 ;;
             esac ;;
        --)
            shift
            break ;;
        *)
            echo "Internal error!" ;
            exit 1 ;;
    esac
done


echo "other arguments:"
for arg do
   echo "--> [$arg]"
done