#!/usr/bin/env bash

[ ! -d ~/log ] && mkdir ~/log
log_file=~/log/cron.log
exec > >(tee -a ${log_file} )
exec 2> >(tee -a ${log_file} >&2)

echo; echo "Script: $0"
echo "Date / Time: $(date +%c)"

cd ~/git/cron
# cd ~/git/wp-in-a-box

# export GIT_CURL_VERBOSE=1
# git pull
# export "$(env | grep SSH_AUTH_SOCK)"
# export SSH_AUTH_SOCK=

ssh_agent=$(pgrep ssh-agent)
ssh_auth_sock=$(/usr/sbin/lsof -a -p $ssh_agent -U -F n | sed -n 's/^n//p')
export SSH_AUTH_SOCK=$ssh_auth_sock

git pull
