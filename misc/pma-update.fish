#!/usr/bin/env fish

# set pma_version 2.5

# TODO: install any pma_version through arg
# TODO: install cron

# Changelog
# 2.5:
#   - date: 2025-09-06
#   - create log dir if it doesn't exist
# 2.4:
#   - date: 2024-12-28
#   - fix an issue with blowfish_secret creation
#   - hide core databases
# 2.3:
#   - fix the error while finding the latest pma_version

# raw url: https://raw.githubusercontent.com/pothi/snippets/main/misc/pma-auto-update.sh

# TODO: implement as many things as possible from
# https://docs.phpmyadmin.net/en/latest/setup.html#securing-your-phpmyadmin-installation

# Script to automate PhpMyAdmin updates
# To manually switch to another pma_version, use...
# bash pma-auto-update.sh pma_version_number

# requirement/s
# - .envrc file with pma_db_user and pma_db_pass defined in it

### Variables

set LOGDIR $HOME/log
[ ! -d $LOGDIR ] && mkdir -p $LOGDIR

echo "Date / Time: $(date +%c)"

# change this to some real email, if you wish
set ADMIN_EMAIL pma@localhost

set SITESDIR $HOME

set PMADIR $SITESDIR/phpmyadmin

###### PLEASE DO NOT EDIT BELOW THIS LINE ######

set dbname phpmyadmin

function send_email
     echo "PhpMyAdmin Update didn't go through on server $(hostname -f | awk -F. '{print $2"."$3}'), $(date)" | \
            mail -s "ALERT: PhpMyAdmin Script Failed - Check the log file for more info" $ADMIN_EMAIL
end

set TEMP_FILE '/tmp/pma-pma_version.html'
set randomBlowfishSecret (openssl rand -base64 32)
set encryptedBlowFishSecret (php -r 'echo bin2hex(random_bytes(32)) . PHP_EOL;')

[ -f ~/.envrc ] && source ~/.envrc

if test -z "$pma_db_user"
    send_email
    echo pma_db_user and pma_db_pass variables do not exist. Please check .envrc file. Exiting!
    exit 1
end

## check for all directories
[ ! -d ~/log ] && mkdir ~/log
if not test -d ~/log
    echo; echo "Log directory doesn't exist. Please modify the script and re-run."; echo
    send_email
    exit 1
end

[ ! -d ~/backups ] && mkdir ~/backups
if not test -d ~/backups
    echo; echo "Backup directory doesn't exist. Please create it manually and re-run this script."; echo
    send_email
    exit 1
end

# check for the latest pma_version
# wget -q -O $TEMP_FILE http://www.phpmyadmin.net/home_page/downloads.php
# wget --no-check-certificate -q -O $TEMP_FILE https://www.phpmyadmin.net/downloads/
curl -sLo $TEMP_FILE https://www.phpmyadmin.net/downloads/
if test $status -ne 0
    echo 'Something wrent wrong while downloading the downloads.php file from phpmyadmin.net!'
    send_email
    exit 1
end

set NEW_VERSION $( grep -o 'Download [0-9].[0-9].[0-9]' $TEMP_FILE | awk '{print $2}' | head -1 )
if test -z "$NEW_VERSION"
    echo 'Something wrong in identifying the new pma_version'
    send_email
    exit 1
end

# remove old temp files if exist
# [ -d $PMAOLD ] && rm -rf $PMAOLD
[ -f $TEMPFILE ] && rm $TEMP_FILE

echo

# insert date and time of update
echo 'Date: '$(date +%F)
echo 'Time: '$(date +%H-%M-%S)

if test -d $PMADIR
    set CURRENT_VERSION $(ls $PMADIR/RELEASE-DATE-* 2> /dev/null | sed 's:'$PMADIR'/RELEASE-DATE-::')
    echo 'Current Version: '$CURRENT_VERSION
else
    set CURRENT_VERSION ''
end

echo 'New Version: '$NEW_VERSION

if test -z $argv[1]
    if test "$NEW_VERSION" = "$CURRENT_VERSION"
        echo 'No updates available'
        echo
        exit 0
    end
    if test -z "$CURRENT_VERSION"
        set pma_version $NEW_VERSION
        echo 'Installing PhpMyAdmin '$NEW_VERSION'...'
    else
        set pma_version $NEW_VERSION
        echo 'Updating PhpMyAdmin from '$CURRENT_VERSION' to '$NEW_VERSION'...'
    end
else
    set pma_version $argv[1]
    echo "Manually updating the pma_version to $argv[1]..."
end

if not test -d "$PMADIR"
    echo 'Setting up a new PhpMyAdmin installation...'
    mkdir $PMADIR
    if test $status -ne 0
        echo "Something wrent wrong while creating new directory at '$PMADIR'"
        send_email
        exit 1
    end
end

curl -sLo /tmp/phpmyadmin-current-pma_version.tar.gz https://files.phpmyadmin.net/phpMyAdmin/$pma_version/phpMyAdmin-$pma_version-english.tar.gz
if test $status -ne 0
    echo 'Something wrent wrong while downloading the pma_version - '$pma_version
    send_email
    exit 1
end
echo 'Done downloading'

tar xzf /tmp/phpmyadmin-current-pma_version.tar.gz -C /tmp/ && rm /tmp/phpmyadmin-current-pma_version.tar.gz
if test $status -ne 0
    echo 'Something wrent wrong, while extracting the archive!'
    send_email
    exit 1
end

# backup the installed pma_version and switch to new pma_version
[ -s $PMADIR/config.inc.php ] && cp $PMADIR/config.inc.php ~/backups/

if test -d $PMADIR
    rm -rf $PMADIR
    mkdir $PMADIR
else
    mkdir $PMADIR
end

cp -a /tmp/phpMyAdmin-$pma_version-english/* $PMADIR/
if test $status -ne 0
    echo 'Something wrent wrong, while copying newer pma_version to PMADIR!'
    send_email
    exit 1
end

# security - https://docs.phpmyadmin.net/en/latest/setup.html#securing-your-phpmyadmin-installation
[ -d $PMADIR/setup ] && rm -r $PMADIR/setup

if test -s ~/backups/config.inc.php
    cp ~/backups/config.inc.php $PMADIR/
    if test $status -ne 0
        echo 'Something wrent wrong, while copying the config file!'
        send_email
        exit 1
    end

else
    echo 'Creating a new config.inc.php file...'

    set pmaconfigfile $PMADIR/config.inc.php
    cp $PMADIR/config.sample.inc.php $pmaconfigfile

    # Unhide the user/password config
    sed -i -e '/control/ s:^// ::' $pmaconfigfile

    # Unhide storage database and tables
    sed -i -e '/pma/ s:^// ::' $PMADIR/config.inc.php

    # Setup the username and password
    sed -i -e "/controluser/ s:=.*:= '$pma_db_user';:" $pmaconfigfile
    sed -i -e "/controlpass/ s:=.*:= '$pma_db_pass';:" $pmaconfigfile

    # setup blowfish
    # sed -i -e "/blowfish_secret/ s:=.*:= '$randomBlowfishSecret';:" $pmaconfigfile
    # new method - checkout FAQ 2.10
    sed -i -e "/blowfish_secret/ s:=.*:= sodium_hex2bin('$encryptedBlowFishSecret');:" $pmaconfigfile

    # create the tables
    mysql -u$pma_db_user -p$pma_db_pass phpmyadmin < $PMADIR/sql/create_tables.sql &> /dev/null

    # Configure tmp dir
    echo >> $PMADIR/config.inc.php
    echo "// Custom configs" >> $PMADIR/config.inc.php
    echo >> $PMADIR/config.inc.php
    sed -i "\$ a\$cfg['TempDir'] = '/tmp/';" $PMADIR/config.inc.php
    # Hide core databases
    echo >> $PMADIR/config.inc.php
    sed -i "\$ a\$cfg['Servers'][\$i]['hide_db'] = '^information_schema|performance_schema|mysql|sys|phpmyadmin\$';" $PMADIR/config.inc.php
    echo >> $PMADIR/config.inc.php
end

# remove old files and phpinfo.php file
# [ -d $PMAOLD ] && rm -rf $PMAOLD
[ -f $TEMP_FILE ] && rm $TEMP_FILE
[ -f $PMADIR/phpinfo.php ] && rm $PMADIR/phpinfo.php
[ -d /tmp/phpMyAdmin-$pma_version-english/ ] && rm -rf /tmp/phpMyAdmin-$pma_version-english/

# setup cron to self-update phpmyadmin
crontab -l 2>/dev/null | grep -qw pma-update
if test $status -ne 0
    set min $(random 0 59)
    set hour $(random 0 59)
    begin; crontab -l 2>/dev/null; echo; echo "$min $hour * * * ~/pma-update.fish >> ~/log/pma-update.log 2>&1"; end | crontab -
    echo; echo A new cron entry is created to auto-update.
else
    echo; echo A cron entry is already in place to auto-update.
end

echo
echo 'All Done.'
echo

