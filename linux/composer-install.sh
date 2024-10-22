#!/usr/bin/env bash

# https://getcomposer.org/doc/faqs/how-to-install-composer-programmatically.md

version=2.0

# Variables

install_dir=~/.local/bin

[ ! -d $install_dir ] && mkdir -p $install_dir

if [ ! -f $install_dir/composer ]; then
    echo 'Installing Composer for PHP...'
    EXPECTED_CHECKSUM="$(php -r 'copy("https://composer.github.io/installer.sig", "php://stdout");')"
    php -r "copy('https://getcomposer.org/installer', '/tmp/composer-setup.php');"
    ACTUAL_CHECKSUM="$(php -r "echo hash_file('sha384', '/tmp/composer-setup.php');")"

    if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]
    then
        >&2 echo 'ERROR: Invalid installer checksum'
        rm /tmp/composer-setup.php
        exit 1
    fi

    php /tmp/composer-setup.php --quiet --install-dir=$install_dir --filename=composer

    rm /tmp/composer-setup.php &> /dev/null

    # setup cron to self-update composer
    crontab -l | grep -qw composer
    if [ "$?" -ne "0" ]; then
        # ( crontab -l; echo; echo "# auto-update composer - nightly" ) | crontab -
        ( crontab -l; echo "@daily $install_dir/composer self-update &> /dev/null" ) | crontab -
    fi

    crontab -l &> /dev/null
    if [ "$?" -ne "0" ]; then
        # ( crontab -l; echo; echo "# auto-update composer - nightly" ) | crontab -
        ( crontab -l; echo "@daily $install_dir/composer self-update > /dev/null" ) | crontab -
    fi

fi

echo "Composer is installed at $install_dir. Please make sure this dir is in PATH."
