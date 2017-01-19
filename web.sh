#!/bin/bash

# Script Name: web.sh
# Script URI: https://github.com/pothi/linux-bootstrap-snippets
# Version: 2.0
# Description: automatically reates primary user (web) or creates additional users
# Author: Pothi Kalimuthu (@pothi)
# Author URI: https://www.tinywp.in/

# Usage:
# bash web.sh newusername

# Changelog
# 2.0
#   - Jan 19, 2017
#   - Changed default to web from client
#   - changed the name from client.sh to web.sh

# TODO:
# Setup MySecureShell

# Variables - send these as command line options
MY_SFTP_USER=
MY_SSH_USER=

# import the defaults
if [ "$1" == "" ]; then
    source /root/.my.exports
else
    MY_SFTP_USER=$1
fi

if [ "$MY_SFTP_USER" == "" ]; then
    echo 'MY_SFTP_USER is not defined in "/root/.my.exports". Exiting!'; exit 1
fi

if [ "$MY_SSH_USER" != '' ]; then
  useradd --shell=/usr/bin/zsh --create-home $MY_SSH_USER
    if [ "$?" != 0 ]; then
        echo; echo 'MY_SSH_USER already exists. Continuing to run the script.'; echo
    fi

  echo $MY_SSH_USER' ALL = NOPASSWD : ALL' >> /etc/sudoers.d/$MY_SSH_USER && chmod 440 /etc/sudoers.d/$MY_SSH_USER

  # Add MY_SSH_USER in the "AllowUsers', if not exists
  if ! grep "$MY_SSH_USER" /etc/ssh/sshd_config &> /dev/null ; then
      sed -i '/AllowUsers/ s/$/ '$MY_SSH_USER'/' /etc/ssh/sshd_config
  fi

fi

if [ ! -e "/home/web/" ]; then
    groupadd --gid=1010 $MY_SFTP_USER &> /dev/null
    useradd --uid=1010 --gid=1010 --shell=/usr/bin/zsh -m --home-dir /home/web/ $MY_SFTP_USER &> /dev/null

    groupadd web &> /dev/null

    HOME_DIR=web

else
    useradd --shell=/usr/bin/zsh -m $MY_SFTP_USER &> /dev/null
    if [ "$?" != 0 ]; then
        echo 'Usage web.sh username'; exit 1
    fi

    HOME_DIR=${MY_SFTP_USER}
fi

# "web" is meant for SFTP only user/s
gpasswd -a $MY_SFTP_USER web &> /dev/null

mkdir -p /home/${HOME_DIR}/{.aws,.composer,.ssh,.well-known,Backup,bin,git,log,others,php/session,scripts,sites,src,tmp,mbox,.npm,.wp-cli} &> /dev/null
mkdir -p /home/${HOME_DIR}/Backup/{files,databases}

chown -R $MY_SFTP_USER:$MY_SFTP_USER /home/${HOME_DIR}
chown root:root /home/${HOME_DIR}
chmod 755 /home/${HOME_DIR}

# if the text 'match group web' isn't found, then
# insert it only once
if ! grep "Match group web" /etc/ssh/sshd_config &> /dev/null ; then
    # remove the existing subsystem
    sed -i 's/^Subsystem/### &/' /etc/ssh/sshd_config

    # add new
echo '
Subsystem sftp internal-sftp
    Match group web
    ChrootDirectory %h
    X11Forwarding no
    AllowTcpForwarding no
    ForceCommand internal-sftp
' >> /etc/ssh/sshd_config

fi # /Match group web

if ! grep "$MY_SFTP_USER" /etc/ssh/sshd_config &> /dev/null ; then
  sed -i '/AllowUsers/ s/$/ '$MY_SFTP_USER'/' /etc/ssh/sshd_config
fi

systemctl restart sshd &> /dev/null
if [ "$?" != 0 ]; then
  service ssh restart
fi

FPM_DIR=/etc/php/7.0/fpm/pool.d/
if [ -d $FPM_DIR ]; then
    echo "
[${MY_SFTP_USER}]
user = ${MY_SFTP_USER}
group = ${MY_SFTP_USER}
listen = /var/lock/php-fpm-${MY_SFTP_USER}
listen.owner = ${MY_SFTP_USER}
listen.group = ${MY_SFTP_USER}
listen.mode = 0666
pm = ondemand
pm.max_children = 5
pm.process_idle_timeout = 10s;
pm.max_requests = 500
catch_workers_output = yes
" >> ${FPM_DIR}${MY_SFTP_USER}.conf
# remove the empty line at the start of the file
sed -i '/^[[:space:]]*$/d' ${FPM_DIR}${MY_SFTP_USER}.conf

    systemctl restart php7.0-fpm &> /dev/null
    if [ "$?" != 0 ]; then
        echo 'Something went wrong while setting up PHP-FPM! See below...'; echo; echo;
        systemctl status php7.0-fpm
    fi
fi

echo
echo 'All done. Setup the password for your web by running...'
echo
echo "passwd $MY_SFTP_USER"
echo
