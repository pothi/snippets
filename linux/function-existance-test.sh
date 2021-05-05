#!/usr/bin/env sh

codename() {
    lsb_release_cli=$(which lsb_release)
    local codename=""
    if [ ! -z $lsb_release_cli ]; then
        codename=$($lsb_release_cli -cs)
    else
        codename=$(cat /etc/os-release | awk -F = '/VERSION_CODENAME/{print $2}')
    fi
    echo "$codename"
}

if ! $(type 'codename' 2>/dev/null | grep -q 'function')
then
   echo 'function does not exist.'
else
    echo 'function exists.'
fi

