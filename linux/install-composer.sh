#!/usr/bin/env bash

# Variables

install_dir=$HOME/.local/bin

[ ! -d $install_dir ] && mkdir -p $install_dir

if [ ! -f $install_dir/composer ]; then
    echo 'Installing Composer for PHP...'
    EXPECTED_SIGNATURE=$(wget -q -O - https://composer.github.io/installer.sig)
    php -r "copy('https://getcomposer.org/installer', '/tmp/composer-setup.php');"
    ACTUAL_SIGNATURE=$(php -r "echo hash_file('SHA384', '/tmp/composer-setup.php');")

    if [ "$EXPECTED_SIGNATURE" == "$ACTUAL_SIGNATURE" ]
    then
        php /tmp/composer-setup.php --quiet --install-dir=$install_dir --filename=composer
    fi
    rm /tmp/composer-setup.php &> /dev/null

    # setup cron to self-update composer
    crontab -l | grep -qw composer
    if [ "$?" -ne "0" ]; then
        # ( crontab -l; echo; echo "# auto-update composer - nightly" ) | crontab -
        ( crontab -l; echo '@daily $install_dir/composer self-update &> /dev/null' ) | crontab -
    fi

    crontab -l &> /dev/null
    if [ "$?" -ne "0" ]; then
        # ( crontab -l; echo; echo "# auto-update composer - nightly" ) | crontab -
        ( crontab -l; echo '@daily $install_dir/composer self-update &> /dev/null' ) | crontab -
    fi

fi

echo "Composer is installed at $install_dir. Please make sure this dir is in PATH."
