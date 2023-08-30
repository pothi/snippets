#!/bin/bash

# traverse through /home/web/sites and wp-config file to create DB and DB user.
# to be run as root user (or any user with admin privilege for MySQL without password via cli)

version=2023.07.13

export PATH=~/bin:~/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin

debug=

cd /home/web/sites > /dev/null

# go through each directory
for domain in $(find * -maxdepth 0 -type d); do
    config_file=/home/web/sites/$domain/wp-config.php
    [ ! -f $config_file ] && config_file=/home/web/sites/$domain/public/wp-config.php
    if [ ! -f $config_file ]; then
        echo "wp-config.php is not found for domain $domain"
        # comment out any one of the following two lines.
        # echo 'Skipping this domain / directory.'
        exit
    fi

    PASS=`/bin/sed "s/[()',;]/ /g" $config_file | /bin/grep DB_PASSWORD | /bin/awk '{print $3}'`
    USER=`/bin/sed "s/[()',;]/ /g" $config_file | /bin/grep DB_USER | /bin/awk '{print $3}'`
    DB=`/bin/sed "s/[()',;]/ /g" $config_file | /bin/grep DB_NAME | /bin/awk '{print $3}'`

    echo "Processing the site: $domain"
    if [ "$debug" ]; then
        echo "DB Name: $DB"
        echo "DB User: $USER"
        echo "DB Pass: $PASS"
        echo
        # uncomment to see exit after processing the first domain / site.
        # exit
    fi

    mysql -e "CREATE DATABASE IF NOT EXISTS ${DB};"
    mysql -e "CREATE USER IF NOT EXISTS ${USER} IDENTIFIED BY '${PASS}';"
    mysql -e "GRANT ALL PRIVILEGES ON ${DB}.* TO ${USER} WITH GRANT OPTION;"

    # uncomment to see exit after processing the first domain / site.
    # exit
done

cd - > /dev/null

