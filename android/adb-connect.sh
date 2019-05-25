#!/bin/bash

#----------------------------------------------------
# File: adb_connect.sh
# Contents: 解决adb链接出现'no permission'问题
# Date: 18-11-12
#----------------------------------------------------

idVendor=
idProduct=

command_exists() {
	command -v "$@" > /dev/null 2>&1
}

get_id() {
    if [[ "$(whoami)" != "root" ]]; then
        echo
        echo "ERROR: Please use root"
        echo
        exit
    fi

    if ! command_exists lsusb ; then
        echo
        echo "ERROR: Please install lsusb"
        echo
        exit
    fi

    contens="$(lsusb|grep 'Google Inc'|cut -d ' ' -f6)"
    idVendor="$(echo ${contens}|cut -d ':' -f1)"
    idProduct="$(echo ${contens}|cut -d ':' -f2)"
}

add_config_file() {
    get_id

    config=/etc/udev/rules.d/51-android.rules
    if [[ -e config ]];then
       rm -rf ${config}
    fi

    echo "SUBSYSTEM=='usb',ATTRS{idVendor}=='"${idVendor}"',ATTRS{idProduct}=='"${idProduct}"',MODE='0666'" > \
    "${config}"

    chmod a+rx ${config} && service udev restart && \
    adb kill-server && adb start-server

    if [[ $? -eq 0 ]]; then
        echo
        echo "INFO: Success start adb"
        echo
    else
        echo
        echo "ERROR: start adb failed"
        echo
    fi
}

add_config_file
