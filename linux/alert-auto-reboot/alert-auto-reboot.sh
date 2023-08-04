#!/usr/bin/env bash

# Keep it on ~/.local/bin/

version=1.1

# Inspired by https://askubuntu.com/q/524692/65814

export PATH=~/bin:~/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin

# To get ADMIN_EMAIL if defined
[ -f ~/.envrc ] && source ~/.envrc
email_address=${ADMIN_EMAIL:-"root@localhost"}

if [ -f /var/run/reboot-required ]; then
    if command -v mail >/dev/null; then
        echo "`hostname -f` will be rebooted, as per the schedule!" | mail -s "Auto Reboot" $email_address
    else
        echo >&2 "`hostname -f` will be rebooted, as per the schedule!"
        echo >&2 "[Warn]: 'mail' command is not found in \$PATH; Email alerts will not be sent!"
    fi
fi

