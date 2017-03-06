#!/bin/bash

# Script Name: web.sh
# Script URI: https://github.com/pothi/linux-bootstrap-snippets
# Version: 2.3
# Description: automatically reates primary user (web) or creates additional users
# Author: Pothi Kalimuthu (@pothi)
# Author URI: https://www.tinywp.in/

# Usage:
# bash web.sh newusername

# Changelog
# 2.3
#   - March 6, 2017
#   - create only additional SFTP user
# 2.2
#   - Jan 25, 2017
#   - test ssh and php-fpm config before restarting the daemons
# 2.1
#   - Jan 25, 2017
#   - change the default 'web' into a variable
#   - introduced logging
#   - Removed older way of allowing new users into the server and introduced newer way

# 2.0
#   - Jan 19, 2017
#   - Changed default to web from client
#   - changed the name from client.sh to web.sh

# TODO:
# Setup MySecureShell

# Variables - you may send these as command line options
MY_SFTP_USER=

#--- please do not edit below this file ---#

SSHD_CONF=/etc/ssh/sshd_config

LOG_FILE=${HOME}/log/create-additional-sftp-user.log
exec > >(tee -a ${LOG_FILE} )
exec 2> >(tee -a ${LOG_FILE} >&2)

# import or set the default/s
if [ "$1" != "" ]; then
    MY_SFTP_USER=$1
    else
        echo; echo "Usage: $0 sftp_username"; echo
        exit 1
fi

useradd -m $MY_SFTP_USER &> /dev/null
if [ "$?" != 0 ]; then
    echo 'Something went wrong while creating the new user. Probably, the supplied username already exists in the server!'; exit 1
fi

HOME_DIR=${MY_SFTP_USER}

# "web" is meant for SFTP only user/s
gpasswd -a $MY_SFTP_USER ${BASE_NAME} &> /dev/null

mkdir -p /home/${HOME_DIR}/{.aws,.composer,.nano,.selected-editor,.ssh,.well-known,Backup,bin,git,log,others,php/session,scripts,sites,src,tmp,mbox,.npm,.wp-cli} &> /dev/null
mkdir -p /home/${HOME_DIR}/Backup/{files,databases}

chown -R $MY_SFTP_USER:$MY_SFTP_USER /home/${HOME_DIR}
chown root:root /home/${HOME_DIR}
chmod 755 /home/${HOME_DIR}

#-- allow the user to login to the server --#
# older way of doing things by appending it to AllowUsers directive
# if ! grep "$MY_SFTP_USER" ${SSHD_CONFIG} &> /dev/null ; then
  # sed -i '/AllowUsers/ s/$/ '$MY_SFTP_USER'/' ${SSHD_CONFIG}
# fi
# latest way of doing things
# ref: https://knowledgelayer.softlayer.com/learning/how-do-i-permit-specific-users-ssh-access
groupadd –r sshusers

# if AllowGroups line doesn't exist, insert it only once!
# if ! grep -i "AllowGroups" ${SSHD_CONFIG} &> /dev/null ; then
    # echo '
# allow users within the (system) group "sshusers"
# AllowGroups sshusers
# ' >> ${SSHD_CONFIG}
# fi

# add new users into the 'sshusers' now
usermod -a -G sshusers ${MY_SFTP_USER}

echo 'Testing the modified SSH config'
/usr/sbin/sshd –t &> /dev/null
if [ "$?" != 0 ]; then
    echo 'Something is messed up in the SSH config file'
    echo 'Please re-run after fixing errors'
    echo "See the logfile ${LOG_FILE} for details of the error"
    echo 'Exiting pre-maturely'
    exit 1
else
    echo 'Cool. Things seem fine. Restarting SSH Daemon...'
    systemctl restart sshd &> /dev/null
    if [ "$?" != 0 ]; then
        echo 'Something went wrong while setting up PHP-FPM! See below...'; echo; echo;
        systemctl status sshd
    else
        echo 'SSH Daemon restarted!'
        echo 'WARNING: Try to create another SSH connection from another terminal, just incase...!'
        echo 'Do NOT ignore this warning'
    fi
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
catch_workers_output = yes
" >> ${FPM_DIR}${MY_SFTP_USER}.conf
# remove the empty line at the start of the file
sed -i '/^[[:space:]]*$/d' ${FPM_DIR}${MY_SFTP_USER}.conf

    echo 'Testing the modified PHP-FPM pool config'
    /usr/sbin/php-fpm7.0 -t &> /dev/null
    if [ "$?" != 0 ]; then
        echo "php-fpm test failed. check your log at ${LOG_FILE}"
        echo 'exiting'
        exit 1
    fi

    echo 'Cool. Things seem fine. Restarting PHP-FPM Daemon...'
    systemctl restart php7.0-fpm &> /dev/null
    if [ "$?" != 0 ]; then
        echo 'Something went wrong while setting up PHP-FPM! See below...'; echo; echo;
        systemctl status php7.0-fpm
    else
        echo 'PHP-FPM restarted.'
    fi
fi

echo
echo 'All done. Setup the password for your ${MY_SFTP_USER} by running...'
echo
echo "passwd $MY_SFTP_USER"
echo
