#!/bin/bash

#TODO: if the remote.origin.url starts with https://, it is likely to be a read-only repo that can be skipped for changes.

# programming env: these switches turn some bugs into errors
# set -o errexit
# to capture non-zero exit code in the pipeline
set -o pipefail
# to avoid deleting existing file accidentally
# set -o noclobber
# to avoid using unset variable
set -o nounset

# set -x

export PATH=~/bin:~/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin

# PATH for wget on macOS
[ -d /opt/local/bin ] && PATH=/opt/local/bin:$PATH

[ ! -d ~/log ] && mkdir ~/log
log_file=~/log/pull-all-repos.log
exec > >(tee -a ${log_file} )
exec 2> >(tee -a ${log_file} >&2)

echo
echo "Script: $0"
echo "Date / Time: $(date +%c)"
echo

# Test for internet
inet=
sleep_for=3

while [ ! "$inet" ]; do
    # \curl -s --connect-timeout 3 -o /dev/null http://1.1.1.1
    cmd="wget --spider -q http://g.co"

    if $cmd
    then
        inet="Online"
    else
        echo "Waiting for internet..."
        sleep ${sleep_for}
        [ $sleep_for -lt 60 ] && sleep_for=$((sleep_for*2))
    fi
done

# echo 'Internet is up!'
# exit

# gitStatus=

gitStatus=$(git -C ~/.ssh status --short)
if [ "$gitStatus" ] ; then
    echo 'git status on ~/.ssh ...'
    echo "$gitStatus"
    echo
fi

echo "Running 'git status' on all directories inside ~/git/ ..."
echo
for repo in ~/git/*/; do
    gitStatus=$(git -C "$repo" status --short)
    if [ "$gitStatus" ] ; then
        echo "Current dir: $repo"
        echo "$gitStatus"
        echo
    fi
done

echo 'Done.'
echo
