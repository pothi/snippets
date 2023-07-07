#!/bin/bash

# script to switch to snap based certbot

export PATH=~/bin:~/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin
export DEBIAN_FRONTEND=noninteractive

# Function to exit with an error message
check_result() {
    if [ $? -ne 0 ]; then
        echo; echo "Error: $1"; echo
        exit 1
    fi
}

[ ~/.envrc ] && . ~/.envrc

# Step 1: Remove the existing certbot package

echo; echo "Removing the old instance of certbot if exists..."; echo

apt-get -qq remove certbot && apt-get -qq autoremove

# Step 2: Install using snap

echo; echo "Installing certbot via snap..."; echo

snap install core
snap refresh core

snap install --classic certbot
ln -fs /snap/bin/certbot /usr/bin/certbot

# register certbot account if email is supplied
if [ $CERTBOT_ADMIN_EMAIL ]; then
    certbot show_account &> /dev/null
    if [ "$?" != "0" ]; then
        certbot -m $CERTBOT_ADMIN_EMAIL --agree-tos --no-eff-email register
    else
        certbot update_account --email $CERTBOT_ADMIN_EMAIL --no-eff-email
    fi
fi

# Restart script upon renewal; it can also alert upon success or failure
# See - https://github.com/pothi/snippets/blob/main/ssl/nginx-restart.sh
[ ! -d /etc/letsencrypt/renewal-hooks/deploy/ ] && mkdir -p /etc/letsencrypt/renewal-hooks/deploy/
restart_script=/etc/letsencrypt/renewal-hooks/deploy/nginx-restart.sh
restart_script_url=https://github.com/pothi/snippets/raw/main/ssl/nginx-restart.sh
[ ! -f "$restart_script" ] && {
    wget -q -O $restart_script $restart_script_url
    check_result $? "Error downloading Nginx Restart Script for Certbot renewals."
    chmod +x $restart_script
}

# Step 3: remove old crontab entries

echo; echo "Removing old entries in crontab..."; echo
crontab -l | grep -v renew | crontab -

echo 'All done.'; echo
