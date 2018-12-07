#!/bin/bash

#----------------------------------------------------
# File: function_param.sh
# Contents: 函数参数
# Date: 18-11-11
#----------------------------------------------------

param() {
    echo "params: $*"
    echo "params: $@"

    echo "params num: $#"
    echo "function pid: $$"
    echo "function return value: $?"

    echo "shell script: $0"
}

param "AA" "BB"