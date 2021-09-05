#!/bin/bash

#----------------------------------------------------
# File: sync
# Contents: 
# Date: 21-9-5
#----------------------------------------------------

server="user@172.16.2.170"
path="$HOME/workspace/$1"
backup="~/workspace/$1"

/usr/bin/inotifywait -mrq --format '%w%f' -e create,close_write,delete ${path} | while read line
do
    if [[ -f ${line} ]]; then
        rsync -azPv ${line} --delete ${server}:${backup}
    else
        cd ${path} && \
        rsync -azPv ./ --delete ${server}:${backup}
    fi
done
