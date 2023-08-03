#!/bin/bash

# traverse through /home/web/sites to deploy nginx for each site

version=2023.08.03

export PATH=~/bin:~/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin

debug=
SITES_DIR=/home/web/sites

cd $SITES_DIR > /dev/null

# go through each directory
for domain in $(find * -maxdepth 0 -type d); do
    config_file=${SITES_DIR}/$domain/nginx.conf
    [ ! -f $config_file ] && config_file=${SITES_DIR}/$domain/public/nginx.conf
    if [ ! -f $config_file ]; then
        echo "nginx.conf is not found for domain $domain"
        # comment out any one of the following two lines.
        # echo 'Skipping this domain / directory.'
        exit
    fi

    echo "Processing the site: $domain"
    ln -fs "${config_file}" /etc/nginx/sites-enabled/${domain}.conf
    if ! nginx -t 2>/dev/null; then
        echo "Error processing ${domain}."
    fi
done

# if we reach this stage, then it is safe to restart nginx
nginx -t 2>/dev/null && systemctl restart nginx
echo; echo 'Listing of /etc/nginx/sites-enabled ...'
ls -l /etc/nginx/sites-enabled
echo; echo 'Nginx restarted.'; echo

cd - > /dev/null

