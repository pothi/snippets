#!/bin/bash

SCRIPT_NAME=remove-user.sh

LOG_FILE=${HOME}/log/remove-user.log
exec > >(tee -a ${LOG_FILE} )
exec 2> >(tee -a ${LOG_FILE} >&2)

# check if log directory exists
if [ ! -d "${HOME}/log" ] && [ "$(mkdir -p ${HOME}/log)" ]; then
    echo 'Log directory not found. Please create it manually and then re-run this script.'
    exit 1
fi

if [ "$1" == "" ]; then
	echo; echo "Usage ${SCRIPT_NAME} username";
    exit 1
else
    USER_TO_REMOVE=$1
fi

# Step #2 - Remove the PHP FPM pool conf
PHP_VERSION=7.0
if [ -f /etc/php/${PHP_VERSION}/fpm/pool.d/${USER_TO_REMOVE}.conf ]; then
    rm /etc/php/${PHP_VERSION}/fpm/pool.d/${USER_TO_REMOVE}.conf
    systemctl restart php${PHP_VERSION}-fpm
    echo 'PHP-FPM conf removed!'; echo
else
    echo "Could not remove the PHP-FPM conf file at /etc/php/${PHP_VERSION}/fpm/pool.d/${USER_TO_REMOVE}.conf";
    echo "File is not found"
    echo
    echo 'Continuing...'
fi

# STEP #1 - Remove the user files
if id -u $USER_TO_REMOVE &> /dev/null ; then
    echo 'Please hold on while we remove the user files...'
    # try Debian way
    deluser --quiet --remove-all-files --remove-home $USER_TO_REMOVE &> /dev/null
    if [ $? == 1 ]; then
        # use the low-level utility
        userdel --remove $USER_TO_REMOVE &> /dev/null
    fi
    rmdir /home/${USER_TO_REMOVE} &> /dev/null
fi
echo 'User files removed!'; echo

# Step #3 - Remove the line in Nginx conf
cp /etc/nginx/conf.d/common.conf ~/backups/nginx_common.conf-$(date +%F)
sed -i '/'${USER_TO_REMOVE}'/d' /etc/nginx/conf.d/common.conf
nginx -t && systemctl restart nginx
if [ $? == 1 ]; then
    echo 'Something went wrong while restarting Nginx'; echo;
else
    echo 'Nginx conf updated'; echo;
fi

echo 'All done!'; echo;