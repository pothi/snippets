#!/usr/bin/env bash

# TODO: display full changes on repos that have something modified.

ver=1.2

# changelog
# version: 1.2
#   - date: 2026-03-13
#   - display execution time
#   - better log output.
# version: 1.1
#   - date: 2026-03-13
#   - better log output.

# programming env: these switches turn some bugs into errors
# set -o errexit
# to capture non-zero exit code in the pipeline
set -o pipefail
# to avoid deleting existing file accidentally
# set -o noclobber
# to avoid using unset variable
set -o nounset

# set -x

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
# local bin directories
[ -d ~/bin ] && PATH=~/bin:$PATH
[ -d ~/.local/bin ] && PATH=~/.local/bin:$PATH
# OS specific PATH
# snap on Debian / Ubuntu
[ -d /snap/bin ] && PATH=$PATH:/snap/bin
# port, homebrew on macOS
[ -d /opt/local/bin ] && PATH=/opt/local/bin:$PATH
[ -d /opt/homebrew/bin ] && PATH=/opt/homebrew/bin:$PATH

[ ! -d ~/log ] && mkdir ~/log
log_file=~/log/pull-all-repos.log
exec > >(tee -a ${log_file})
exec 2> >(tee -a ${log_file} >&2)

echo -e "\nScript: $0"
echo "Date / Time: $(date +%c)"
start=$(date +%s)

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

# git_location=$(which git)
# echo "Git location: $git_location"

printf '\n%s\t' "Running 'git pull' on ~/.ssh ... "
git -C ~/.ssh pull -q
echo -e 'done.\n'

SCAN_DIR=scm

# set -x
[ ! -d "$HOME/$SCAN_DIR" ] && SCAN_DIR=git
[ ! -d "$HOME/$SCAN_DIR" ] && { echo 2> "Scan dir: ~/$SCAN_DIR doesn't exist"; exit 1;}

# echo "Scan dir: ~/$SCAN_DIR"

echo "Running 'git pull' on all repos in ~/$SCAN_DIR ..."
for repo in $HOME/${SCAN_DIR}/*/; do
    # skip local repos (with no remote origin url)
    # local repos don't have remote.origin.url
    if git -C "$repo" config remote.origin.url &>/dev/null ; then
        echo "Current repo: $repo"
        git -C "$repo" pull -q

        # Pull changes in submodule/s
        if [ -f "${repo}.gitmodules" ]; then
            git -C "$repo" submodule update --remote --merge -q
        fi
    else
        echo "Skipped local repo: $repo"
    fi
done
echo

echo "Date / Time: $(date +%c)"
end=$(date +%s)
echo "Execution time: $(($end - $start)) seconds."

echo -e 'All done.\n'
