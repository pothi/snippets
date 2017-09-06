#!/bin/bash

# TODO
# user pwgen to generate random username and password

# Script to automate PhpMyAdmin updates
# To manually switch to another version, use...
# bash pma-auto-update.sh version_number

### Variables

LOGDIR=$HOME/log
LOG_FILE=$LOGDIR/phpmyadmin-updates.log
exec > >(tee -a ${LOG_FILE} )
exec 2> >(tee -a ${LOG_FILE} >&2)

ADMIN_EMAIL=user@example.com
SITESDIR=${HOME}

PMADIR=${SITESDIR}/phpmyadmin

###### PLEASE DO NOT EDIT BELOW THIS LINE ######

function send_email() {
     echo "PhpMyAdmin Update didn't go through on server $(hostname -f | awk -F. '{print $2"."$3}'), $(date)" | \
            mail -s "ALERT: PhpMyAdmin Script Failed - Check the log file for more info" $ADMIN_EMAIL
}

TEMP_FILE='/tmp/pma-version.html'
PMAOLD=/tmp/old-pma

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
wget --no-check-certificate -q -O $TEMP_FILE https://www.phpmyadmin.net/downloads/
if [ "$?" != '0' ]; then
	echo 'Something wrent wrong while downloading the downloads.php file from phpmyadmin.net!'
	send_email
	exit 1
fi

NEW_VERSION=$(grep -i '.h2.phpmyadmin' $TEMP_FILE | head -1 | sed 's_</\?h2>__g' | awk '{print $2}')
if [ "$NEW_VERSION" == '' ]; then
	echo 'Something wrong in identifying the new version'
	send_email
fi

rm $TEMP_FILE

echo

# insert date and time of update
echo 'Date: '$(date +%F)
echo 'Time: '$(date +%H-%M-%S)

if [ -d ${PMADIR} ]; then
    CURRENT_VERSION=$(ls ${PMADIR}/RELEASE-DATE-* | sed 's:'${PMADIR}'/RELEASE-DATE-::')
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
        echo 'Something wrent wrong while setting up the new PhpMyAdmin installation at '${PMADIR}
        send_email
        exit 1
    fi
fi

echo 'Hold on! Downloading the latest version...'
wget --no-check-certificate -q https://files.phpmyadmin.net/phpMyAdmin/${version}/phpMyAdmin-${version}-english.tar.gz -O /tmp/phpmyadmin-current-version.tar.gz
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
mv $PMADIR $PMAOLD &> /dev/null

mv /tmp/phpMyAdmin-${version}-english $PMADIR
 
if [ "$?" != '0' ]; then
	echo 'Something wrent wrong, while moving directories!'
	send_email
	exit 1
fi

if [ -s ${PMAOLD}/config.inc.php ]; then
    cp ${PMAOLD}/config.inc.php ${PMADIR}/
    if [ "$?" != '0' ]; then
        echo 'Something wrent wrong, while copying the config file!'
        send_email
        exit 1
    fi
else
    cp ${PMADIR}/config.sample.inc.php ${PMADIR}/config.inc.php
    # Unhide the user/password config
    sed -i '/control/ s:^// ::' ${PMADIR}/config.inc.php

    # Unhide storage database and tables
    sed -i '/pma/ s:^// ::' ${PMADIR}/config.inc.php

    # Setup the password
    sed -i '/controlpass/ s:pmapass:&'$HOME':' ${PMADIR}/config.inc.php

    # Hide unnecessary databases
    # sed -i "$ a\$cfg['Servers'][\$i]['hide_db'] = '^information_schema|performance_schema|mysql|phpmyadmin\$';" ${PMADIR}/config.inc.php
fi

# remove old files
rm -rf $PMAOLD &> /dev/null

echo 'Done upgrading PhpMyadmin...'
echo
