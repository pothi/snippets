#!/bin/bash

version=1.0

# path to ssl archive
ssl_archive=/home/web/sites/ssl.tar.gz

if [ ! -f "$ssl_archive" ]; then
    echo "SSL archive not found at $ssl_archive"
    exit 1
fi  

tar xf $ssl_archive -C /etc

certbot certificates 2>/dev/null

echo; echo 'Make sure certificates of all domains are migrated.'; echo

# [ -d ~/tmp ] || mkdir ~/tmp

# cp "$ssl_archive" ~/tmp
# tar xf ~/tmp/ssl.tar.gz
