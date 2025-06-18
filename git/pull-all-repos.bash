#!/usr/bin/env bash

# TODO: display full changes on repos that have something modified.

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

[ ! -d ~/log ] && mkdir ~/log
log_file=~/log/pull-all-repos.log
exec > >(tee -a ${log_file})
exec 2> >(tee -a ${log_file} >&2)

echo -e "\nScript: $0"
echo "Date / Time: $(date +%c)"

# Test for internet
inet=
sleep_for=3

while [ -z $inet ]; do
    # curl -s --connect-timeout 3 -o /dev/null http://1.1.1.1
    # cmd="wget --spider -q http://g.co"
    cmd="curl -s --connect-timeout 3 -o /dev/null http://1.1.1.1"

    if $cmd; then
        inet="Online"
    else
        echo "Waiting for internet..."
        sleep ${sleep_for}
        [ $sleep_for -lt 60 ] && sleep_for=$((sleep_for * 2))
    fi
done

# echo 'Internet is up!'
# exit

echo 'Running git pull on ~/.ssh ...'
git -C ~/.ssh pull -q

echo "Running 'git pull' on all directories inside ~/git/ ..."
for repo in ~/git/*/; do
    # skip local repos (with no remote origin url)
    if git -C "$repo" config remote.origin.url >/dev/null; then
        echo "Current dir: $repo"
        git -C "$repo" pull -q

        # Pull changes in submodule/s
        if [ -f "${repo}.gitmodules" ]; then
            git -C "$repo" submodule update --remote --merge -q
        fi
    else
        echo "Skipped local repo: $repo"
    fi
done

echo -e 'Done.\n'
