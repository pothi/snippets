#!/bin/bash

# version: 1.0
# date: 2024-12-28

# Changelog
# l.0:
#   - initial version

### Variables

LOGDIR=$HOME/log
LOG_FILE=$LOGDIR/expose-mysql.log
# script output to log file (and to console)
exec > >(tee -a ${LOG_FILE} )
exec 2> >(tee -a ${LOG_FILE} >&2)

echo "Date / Time: $(date +%c)"

# change this to some real email, if you wish
mysql_conf_file=/etc/mysql/mysql.conf.d/mysqld.cnf

###### PLEASE DO NOT EDIT BELOW THIS LINE ######

# take a backup if it doesn't exist
[ ! -f ~/backups/mysqld.cnf-$(date +%F) ] && cp $mysql_conf_file ~/backups/mysqld.cnf-$(date +%F)

export PATH=~/bin:~/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin

[ ! -d ~/backups ] && mkdir ~/backups
if [ ! -d ~/backups ]; then
    echo; echo "Backup directory doesn't exist. Please create it manually and re-run this script."; echo
    send_email
    exit 1
fi

# stop before making changes
systemctl stop mysql

# expose MySQL ports
sed -i '/bind-address/ s/127.0.0.1/0.0.0.0/' $mysql_conf_file

# start after making changes
systemctl start mysql

grep bind-address $mysql_conf_file

echo 'MySQL is made accessible from anywhere.'
echo
