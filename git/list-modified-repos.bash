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

echo -e "\nScript: $0"
echo -e "Date & Time: $(date +%c)\n"

# Alternativly, use git status --porcelain as per https://stackoverflow.com/a/25149786/1004587

gitStatus=$(git -C ~/.ssh status --short)
if [ "$gitStatus" ] ; then
    echo 'git status on ~/.ssh ...'
    echo -e "$gitStatus\n"
fi

SCAN_DIR=~/scm

[ ! -d "$SCAN_DIR" ] && SCAN_DIR=~/git
[ ! -d "$SCAN_DIR" ] && { echo 2> "Scan dir: $SCAN_DIR doesn't exist"; exit 1;}

# echo "Scan dir: $SCAN_DIR"

echo "Running 'git status' on all directories inside ~/git/ ..."
echo
for repo in ${SCAN_DIR}/*/; do
    gitStatus=$(git -C "$repo" status --short 2> /dev/null)
    if [ "$gitStatus" ] ; then
        echo "Repo: $repo"
        echo -e "$gitStatus\n"
    fi
done

echo -e "All done.\n"
