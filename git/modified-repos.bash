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

export PATH=~/bin:~/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
# OS specific PATH
# snap on Debian / Ubuntu
[ -d /snap/bin ] && PATH=$PATH:/snap/bin
# port on macOS
[ -d /opt/local/bin ] && PATH=$PATH:/opt/local/bin

echo
echo "Script: $0"
echo "Date & Time: $(date +%c)"
echo

# Test for internet
isUP=
sleep_for=3

while [ ! "$isUP" ]; do
    # \curl -s --connect-timeout 3 -o /dev/null http://1.1.1.1
    cmd="wget --spider -q http://g.co"

    if $cmd
    then
        isUP="Yes"
    else
        echo "Waiting for internet..."
        sleep ${sleep_for}
        [ $sleep_for -lt 60 ] && sleep_for=$((sleep_for*2))
    fi
done

# echo 'Internet is up!'; exit

# Alternativly, use git status --porcelain as per https://stackoverflow.com/a/25149786/1004587

gitStatus=$(git -C ~/.ssh status --short)
if [ "$gitStatus" ] ; then
    echo 'git status on ~/.ssh ...'
    echo -e "$gitStatus\n"
fi

echo "Running 'git status' on all directories inside ~/git/ ..."
echo
for repo in ~/git/*/; do
    gitStatus=$(git -C "$repo" status --short)
    if [ "$gitStatus" ] ; then
        echo "Current repo: $repo"
        echo -e "$gitStatus\n"
    fi
done

echo -e "All done.\n"
