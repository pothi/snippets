#!/bin/bash

# programming env: these switches turn some bugs into errors
set -o errexit -o pipefail -o noclobber -o nounset

# set -x

# to capture non-zero exit code in the pipeline
set -o pipefail

export PATH=~/bin:~/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin

[ ! -d ~/log ] && mkdir ~/log
log_file=~/log/git-pull-all.log
exec > >(tee -a ${log_file} )
exec 2> >(tee -a ${log_file} >&2)

echo; echo "Script: $0"
echo "Date / Time: $(date +%c)"

# Test for internet
inet=

while [ -z $inet ]; do
    # \curl -s --connect-timeout 3 -o /dev/null http://1.1.1.1
    wget --spider -q http://g.co

    if [ $? -eq 0 ]; then
        inet="Online"
    else
        echo "Waiting for internet..."
        sleep 3
    fi
done

echo 'Internet is up!'

echo 'Running git pull ~/.ssh ...'
git -C ~/.ssh pull -q

echo "Running 'git pull' on all directories inside ~/git/ ..."
for d in ~/git/*/; do
    echo; echo "Current dir: $d"
    git -C $d pull -q
done

echo 'Done.'
echo
