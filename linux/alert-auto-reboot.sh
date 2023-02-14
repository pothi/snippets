#!/usr/bin/env bash

version=1.0

# Inspired by https://askubuntu.com/q/524692/65814

export PATH=~/bin:~/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin

# To get ADMIN_EMAIL if defined
[ -f ~/.envrc ] && source ~/.envrc
email_address=${ADMIN_EMAIL:-"root@localhost"}

if [ -f /var/run/reboot-required ]; then
    echo "The server `hostname` will be rebooted, unattended, as per the schedule!" \
        | mail -s "Unattended Reboot" $email_address
fi
