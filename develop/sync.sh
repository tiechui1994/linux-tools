#!/bin/bash

#----------------------------------------------------
# File: sync
# Contents: 
# Date: 21-9-5
#----------------------------------------------------

server="user@172.16.2.170"
path="$HOME/workspace/$1"
backup="~/workspace/$2"

rsync -azPv \
    --delete \
    --exclude="$path/.(git|git|vscode)/*" \
    --exclude="$path/(node_modules|public)/*" \
    ${path}/* ${server}:${backup}

# modify, MODIFY sync.sh___jb_tmp___
# attrib, ATTRIB sync.sh
# delete, DELETE sync.sh___jb_old___  DELETE sync.sh
# create, CREATE sync.sh___jb_tmp___  CREATE sync.sh
ignore="^$path/(.idea|.git|.vscode|node_modules|public)"
/usr/bin/inotifywait --quiet --recursive --monitor \
    --format '%w%f' \
    --event create,attrib,delete ${path} | while read line
do
    file=""
    if [[ -f "$line" ]]; then
        file="$line"
    elif [[ -d "$line" ]]; then
        file="$line"
    else
        file="$line"
    fi

    if [[ -z ${file} || ${file} =~ ${ignore} || ${file} =~ jb_(tmp|old)___$ ]]; then
        continue
    fi
    
    echo "update: $file"

    rsync -azPv \
        --delete \
        --exclude="$path/.(git|git|vscode)/*" \
        --exclude="$path/(node_modules|public)/*" \
        ${file} ${server}:${backup}
done
