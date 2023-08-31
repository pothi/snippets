#!/bin/bash

# traverse through /home/web/sites and wp-config file to create DB and DB user.

version=2023.07.13

export PATH=~/bin:~/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin

debug=true
db_name=db.sql
db_file=
sizeH=

cd ~/sites > /dev/null

# go through each directory
for domain in $(find * -maxdepth 0 -type d); do
    wp_root=~/sites/${domain}/public
    if [ ! -d $wp_root ]; then
        echo "WordPress is not found for domain $domain at $wp_root"
        # comment out any one of the following two lines.
        # echo 'Skipping this domain / directory.'
        exit
    fi

    db_file=~/sites/${domain}/${db_name}
    [ ! -f $db_file ] && db_file=~/sites/${domain}/public/${db_name}
    if [ ! -f $db_file ]; then
        echo "DB backup is not found for domain $domain at $db_file"
        # comment out any one of the following two lines.
        # echo 'Skipping this domain / directory.'
        exit
    fi

    sizeH=$(du -h $db_file | awk '{print $1}')

    echo "Processing the site: $domain"
    echo "DB Size: $sizeH"
    echo "It may take some time, depending on the size of the database."
    wp --path=$wp_root db import $db_file
    wp --path=$wp_root theme status
    echo

    # uncomment to stop processing after the first domain / site.
    # exit
done

cd - > /dev/null

