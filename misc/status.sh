#!/bin/bash

# version: 1.1
# 1.1
#   - in "tail -50 /home/web/log/backups.log | head -6", instead of tailing last 50 lines, tail only -50 +6 lines using head command.
# 1.0
#   - initial version

[ -f ~/.envrc ] && . ~/.envrc

echo; echo Disk free info...
df -h | tail -n +2 | awk '$6 == "/" {print $0}'

echo; echo Memory info...
free -m

echo; echo System info...
w

# backups
echo; echo 'Backups info...'
ls -hostr /home/web/backups/db-backups/ | tail -5
du -hs /home/web/backups/db-backups
ls -hostr /home/web/backups/full-backups/ | tail -5
du -hs /home/web/backups/full-backups
tail -50 /home/web/log/backups.log | head -6
du -hs /home/web/log/backups.log

wp_domain=${WP_DOMAIN:-""}
if [ ! -z "$wp_domain" ]; then
    echo; echo 'WordPress info...'
    cd /home/web/sites/${wp_domain}/public

    wp --allow-root core version
    wp --allow-root core verify-checksums
    wp --allow-root theme status
    wp --allow-root plugin status
    wp --allow-root cron event list
fi

echo; echo 'Cache size...'
du -hs wp-content/cache

