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
    file=${path}
    if [[ -f ${line} ]]; then
        file=${line}
    fi

    rsync -azPv \
        --delete \
        --exclude="$path/.git" \
        --exclude="$path/.idea" \
        --exclude="$path/node_modules" \
        --exclude="$path/public" \
        ${file} ${server}:${backup}
done
