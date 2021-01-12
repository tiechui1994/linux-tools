#!/bin/bash

#----------------------------------------------------
# File: lock.sh
# Contents: use "flock" implment file lock
# Date: 1/12/21
#----------------------------------------------------

declare -r -x LOCK="/tmp/lock"
declare timeout=3
declare -i fd=0

declare -r success=0
declare -r failure=1

function lock() {
   if [[ -z ${fd} ]]; then
      touch ${LOCK}
      exec {fd}<>${LOCK}
   fi

   flock --exclusive --nonblock ${fd}
   return $?
}

function unlock() {
    flock --unlock ${fd}
    return $?
}


# use example
while [[ 1 ]]; do
     lock
     if [[ $? = ${success} ]]; then
         echo "$$, $(date +%s)"
         sleep 2
         unlock
     fi
done
