#!/bin/bash

# programming env: these switches turn some bugs into errors
# set -o errexit
# to capture non-zero exit code in the pipeline
set -o pipefail
# to avoid deleting existing file accidentally
# set -o noclobber
# to avoid using unset variable
set -o nounset

set -x

export PATH=~/bin:~/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin

# PATH for wget on macOS
[ -d /opt/local/bin ] && PATH=/opt/local/bin:$PATH

[ ! -d ~/log ] && mkdir ~/log
log_file=~/log/pull-all-repos.log
exec > >(tee -a ${log_file} )
exec 2> >(tee -a ${log_file} >&2)

echo; echo "Script: $0"
echo "Date / Time: $(date +%c)"

# Test for internet
inet=
sleep_for=3

while [ -z $inet ]; do
    # \curl -s --connect-timeout 3 -o /dev/null http://1.1.1.1
    \wget --spider -q http://g.co

    if [ $? -eq 0 ]; then
        inet="Online"
    else
        echo "Waiting for internet..."
        sleep ${sleep_for}
        [ $sleep_for -lt 60 ] && sleep_for=$((${sleep_for}*2))
    fi
done

echo 'Internet is up!'

exit

echo 'Running git pull ~/.ssh ...'
git -C ~/.ssh pull -q

echo "Running 'git pull' on all directories inside ~/git/ ..."
for d in ~/git/*/; do
    echo; echo "Current dir: $d"
    git -C $d pull -q
done

echo 'Done.'
echo
