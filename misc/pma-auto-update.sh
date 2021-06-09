#!/bin/bash

# version: 2.1
# date: 2021-06-09

# raw url: https://github.com/pothi/linux-bootstrap-snippets/raw/master/pma-auto-update.sh

# TODO: implement as many things as possible from
# https://docs.phpmyadmin.net/en/latest/setup.html#securing-your-phpmyadmin-installation

# Script to automate PhpMyAdmin updates
# To manually switch to another version, use...
# bash pma-auto-update.sh version_number

# requirement/s
# - .envrc file with pma_db_user and pma_db_pass defined in it

### Variables

LOGDIR=$HOME/log
LOG_FILE=$LOGDIR/phpmyadmin-updates.log
exec > >(tee -a ${LOG_FILE} )
exec 2> >(tee -a ${LOG_FILE} >&2)

echo "Date / Time: $(date +%c)"

# change this to some real email, if you wish
ADMIN_EMAIL=pma@localhost

SITESDIR=${HOME}

PMADIR=${SITESDIR}/phpmyadmin

###### PLEASE DO NOT EDIT BELOW THIS LINE ######

dbname=phpmyadmin

function send_email() {
     echo "PhpMyAdmin Update didn't go through on server $(hostname -f | awk -F. '{print $2"."$3}'), $(date)" | \
            mail -s "ALERT: PhpMyAdmin Script Failed - Check the log file for more info" $ADMIN_EMAIL
}

TEMP_FILE='/tmp/pma-version.html'
PMAOLD=/tmp/old-pma
randomBlowfishSecret=`openssl rand -base64 32`

source ~/.envrc &> /dev/null

if [ -z "$pma_db_user" ]; then
    send_email
    echo pma_db_user and pma_db_pass variables do not exist. Please check .envrc file. Exiting!
    exit 1
fi

## check for all directories
if [ ! -d "$LOGDIR" ]; then
    echo
    echo "Log directory doesn't exist. Please modify the script and re-run."
    echo
    send_email
    exit 1
fi

# check for the latest version
# wget -q -O $TEMP_FILE http://www.phpmyadmin.net/home_page/downloads.php
# wget --no-check-certificate -q -O $TEMP_FILE https://www.phpmyadmin.net/downloads/
\curl -sLo $TEMP_FILE https://www.phpmyadmin.net/downloads/
if [ "$?" != '0' ]; then
    echo 'Something wrent wrong while downloading the downloads.php file from phpmyadmin.net!'
    send_email
    exit 1
fi

NEW_VERSION=$( grep -o 'Download [0-9].[0-9].[0-9]' $TEMP_FILE | awk '{print $2}' )
# NEW_VERSION=$( grep -w '<h2>phpMyAdmin' $TEMP_FILE | head -1 | awk '{print $2}' | awk -F'<' '{print $1}' )
if [ "$NEW_VERSION" == '' ]; then
    echo 'Something wrong in identifying the new version'
    send_email
    exit 1
fi

# remove old temp files if exist
rm -rf $PMAOLD &> /dev/null
rm $TEMP_FILE &> /dev/null

echo

# insert date and time of update
echo 'Date: '$(date +%F)
echo 'Time: '$(date +%H-%M-%S)

if [ -d ${PMADIR} ]; then
    CURRENT_VERSION=$(ls ${PMADIR}/RELEASE-DATE-* 2> /dev/null | sed 's:'${PMADIR}'/RELEASE-DATE-::')
    echo 'Current Version: '$CURRENT_VERSION
else
    CURRENT_VERSION=''
fi

echo 'New Version: '$NEW_VERSION

if [ "$1" == '' ]; then
    if [ "$NEW_VERSION" == "$CURRENT_VERSION" ]; then
        echo 'No updates available'
        echo
        exit 0
    elif [ "$CURRENT_VERSION" == '' ]; then
        version=$NEW_VERSION
        echo 'Installing PhpMyAdmin '$NEW_VERSION'...'
    else
        version=$NEW_VERSION
        echo 'Updating PhpMyAdmin from '$CURRENT_VERSION' to '$NEW_VERSION'...'
    fi
else
    version=$1
    echo 'Manually updating the version to '$1'...'
fi

if [ ! -d "$PMADIR" ]; then
    echo 'Setting up a new PhpMyAdmin installation...'
    mkdir -p $PMADIR &> /dev/null
    if [ "$?" != '0' ]; then
        echo 'Something wrent wrong while creating new directory at '${PMADIR}
        send_email
        exit 1
    fi
fi


# wget --no-check-certificate -q https://files.phpmyadmin.net/phpMyAdmin/${version}/phpMyAdmin-${version}-english.tar.gz -O /tmp/phpmyadmin-current-version.tar.gz
\curl -sLo /tmp/phpmyadmin-current-version.tar.gz https://files.phpmyadmin.net/phpMyAdmin/${version}/phpMyAdmin-${version}-english.tar.gz
if [ "$?" != '0' ]; then
    echo 'Something wrent wrong while downloading the version - '${version}
    send_email
    exit 1
fi
echo 'Done downloading'

cd /tmp/
tar xzf /tmp/phpmyadmin-current-version.tar.gz && rm /tmp/phpmyadmin-current-version.tar.gz
if [ "$?" != '0' ]; then
    echo 'Something wrent wrong, while extracting the archive!'
    send_email
    exit 1
fi

cd - &> /dev/null

# backup the installed version and switch to new version
if [ -s ${PMADIR}/config.inc.php ] ; then
    cp ${PMADIR}/config.inc.php ~/
fi

cp -a $PMADIR $PMAOLD &> /dev/null

rm -rf $PMADIR/* &> /dev/null

mkdir $PMADIR &> /dev/null

cp -a /tmp/phpMyAdmin-${version}-english/* $PMADIR/

if [ "$?" != '0' ]; then
    echo 'Something wrent wrong, while moving directories!'
    send_email
    exit 1
fi

# security - https://docs.phpmyadmin.net/en/latest/setup.html#securing-your-phpmyadmin-installation
rm -r ${PMADIR}/setup

if [ -s ~/config.inc.php ]; then
    cp ~/config.inc.php ${PMADIR}/
    if [ "$?" != '0' ]; then
        echo 'Something wrent wrong, while copying the config file!'
        send_email
        exit 1
    fi

    [ -d ${PMAOLD}/tmp ] && mv ${PMAOLD}/tmp ${PMADIR}/
    if [ "$?" != '0' ]; then
        echo 'Something wrent wrong, while moving the tmp directory!'
        send_email
        exit 1
    fi
else
    echo 'Creating a new config.inc.php file...'

    pmaconfigfile=${PMADIR}/config.inc.php
    cp ${PMADIR}/config.sample.inc.php $pmaconfigfile

    # Unhide the user/password config
    sed -i -e '/control/ s:^// ::' $pmaconfigfile

    # Unhide storage database and tables
    sed -i -e '/pma/ s:^// ::' ${PMADIR}/config.inc.php

    # Setup the username and password
    sed -i -e "/controluser/ s:=.*:= '${pma_db_user}';:" $pmaconfigfile
    sed -i -e "/controlpass/ s:=.*:= '${pma_db_pass}';:" $pmaconfigfile

    # setup blowfish
    sed -i -e "/blowfish_secret/ s:=.*:= '${randomBlowfishSecret}';:" $pmaconfigfile

    # create the tables
    mysql -u$pma_db_user -p$pma_db_pass phpmyadmin < ${PMADIR}/sql/create_tables.sql &> /dev/null

    # Hide unnecessary databases
    # sed -i "$ a\$cfg['Servers'][\$i]['hide_db'] = '^information_schema|performance_schema|mysql|phpmyadmin\$';" ${PMADIR}/config.inc.php
fi

# remove old files and phpinfo.php file
rm -rf $PMAOLD &> /dev/null
rm $TEMP_FILE &> /dev/null
rm ${PMADIR}/phpinfo.php &> /dev/null

echo 'Done upgrading PhpMyadmin...'
echo

