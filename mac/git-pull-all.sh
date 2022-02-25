#!/bin/bash

# set -x

[ ! -d ~/log ] && mkdir ~/log
log_file=~/log/git-pull-all.log
exec > >(tee -a ${log_file} )
exec 2> >(tee -a ${log_file} >&2)

echo; echo "Script: $0"
echo "Date / Time: $(date +%c)"

# Test for internet
inet=

while [ -z $inet ]; do
    \curl -s --connect-timeout 3 -o /dev/null http://1.1.1.1

    if [ $? -eq 0 ]; then
        inet="Online"
    else
        echo "Waiting for internet..."
        # sleep 3
    fi
done

echo 'Internet is up!'
echo "Running 'git pull' on all directories inside ~/git/ ..."

for d in ~/git/*/; do
    echo; echo "Current dir: $d"
    git -C $d pull -q
done

echo 'Done.'
echo
