#!/bin/bash

# To take a DB backup of each site in ~/sites directory
# To be used while migration or for one-off manual backup.
# Useful on t360, Derek, etc.

version=2023.07.13

export PATH=~/bin:~/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin

db_name=db.sql

cd ~/sites > /dev/null

# go through each directory
for domain in $(find * -maxdepth 0 -type d); do
    [ -f ${domain}/${db_name} ] && rm ${domain}/${db_name}
    wp --path=${domain}/public db export --add-drop-table ${domain}/${db_name}
done

cd - > /dev/null
