#!/bin/bash

# version: 2022.07.21
#   - fix an issue where php-package_name is installed by default irrespective of supplied PHP version.
#   - take a backup of /etc
#   - install php-intl package (ex: for Jan)
# version: 2022.06.19
#   - support for php 8
# version: 2020.10.28

### Requirements ###
# existing server with default php package.

# Difference between this and php-installation.sh file
#   - Ondrej repo is installed
#   - lb.conf is not modified
#   - lb.conf is not removed

# Defining return code check function
check_result() {
    if [ $? -ne 0 ]; then
        echo; echo "Error: $1"; echo
        exit 1
    fi
}

# programming env: these switches turn some bugs into errors
set -o errexit -o pipefail -o noclobber -o nounset

# Variable/s
# web_developer_username=
# PHP_MAX_CHILDREN=
# MY_MEMCACHED_MEMORY

echo "Setting up PHP..."

# get the variables
[ -f /root/.envrc ] && source /root/.envrc

if [ -z "$web_developer_username" ]; then
    echo '$web_developer_username is not found'
    echo 'If you use a different variable name for SFTP User, please update the script and re-run'
    echo 'SFTP User is not found. Exiting prematurely!'; exit
fi

# php${php_ver}-mysqlnd package is not found in Ubuntu
php_ver=8.1

###------------------------- Please do not edit below this line -------------------------###

# take a backup
backup_dir="/root/backups/etc-before-${php_ver}-$(date +%F)"
if [ ! -d "$backup_dir" ]; then
    printf '%-72s' "Taking initial backup..."
    mkdir -p $backup_dir
    cp -a /etc $backup_dir
    echo done.
fi

# create log directory, if it doesn't exist
[ ! -d /root/log ] && mkdir /root/log

LOG_FILE="/root/log/php${php_ver}-install.log"
exec > >(tee -a ${LOG_FILE} )
exec 2> >(tee -a ${LOG_FILE} >&2)

echo "Log file can be found at /root/log/php${php_ver}-install.log"

sudo apt-get install software-properties-common
sudo add-apt-repository --update ppa:ondrej/php -y
# sudo apt-get update

# if you wish to configure the PHP version, please see above
php_packages="php${php_ver}-fpm \
    php${php_ver}-mysql \
    php${php_ver}-gd \
    php${php_ver}-cli \
    php${php_ver}-xml \
    php${php_ver}-mbstring \
    php${php_ver}-soap \
    php${php_ver}-curl \
    php${php_ver}-zip \
    php${php_ver}-bcmath \
    php${php_ver}-intl
    php${php_ver}-imagick"

for package in $php_packages
do
    if dpkg-query -W -f='${Status}' $package 2>/dev/null | grep -q "ok installed"
    then
        # echo "'$package' is already installed"
        :
    else
        printf '%-72s' "Installing '${package}' ..."
        apt-get -qq install $package &> /dev/null
        check_result $? "Error installing ${package}."
        echo done.
    fi
done

# let's take a backup of config before modifing them
[ ! -d /root/backups ] && mkdir /root/backups
BACKUP_PHP_DIR="/root/backups/etc-php-$(date +%F)"
if [ ! -d "$BACKUP_PHP_DIR" ]; then
    cp -a /etc $BACKUP_PHP_DIR
fi

home_basename=web
wp_user=${web_developer_username:-""}
php_user=$wp_user

fpm_ini_file=/etc/php/${php_ver}/fpm/php.ini
pool_file=/etc/php/${php_ver}/fpm/pool.d/${php_user}.conf
PM_METHOD=ondemand

user_mem_limit=${PHP_MEM_LIMIT:-""}
[ -z "$user_mem_limit" ] && user_mem_limit=256

max_children=${PHP_MAX_CHILDREN:-""}

if [ -z "$max_children" ]; then
    # let's be safe with a minmal value
    sys_memory=$(free -m | grep -oP '\d+' | head -n 1)
    if (($sys_memory <= 600)) ; then
        max_children=4
    elif (($sys_memory <= 1600)) ; then
        max_children=6
    elif (($sys_memory <= 5600)) ; then
        max_children=10
    elif (($sys_memory <= 10600)) ; then
        PM_METHOD=static
        max_children=20
    elif (($sys_memory <= 20600)) ; then
        PM_METHOD=static
        max_children=40
    elif (($sys_memory <= 30600)) ; then
        PM_METHOD=static
        max_children=60
    elif (($sys_memory <= 40600)) ; then
        PM_METHOD=static
        max_children=80
    else
        PM_METHOD=static
        max_children=100
    fi
fi

env_type=${ENV_TYPE:-""}
if [[ $env_type = "local" ]]; then
    PM_METHOD=ondemand
fi


echo "Configuring memory limit to ${user_mem_limit}MB"
sed -i -e '/^memory_limit/ s/=.*/= '$user_mem_limit'M/' $fpm_ini_file

user_max_filesize=${PHP_MAX_FILESIZE:-64}
echo "Configuring 'post_max_size' and 'upload_max_filesize' to ${user_max_filesize}MB..."
sed -i -e '/^post_max_size/ s/=.*/= '$user_max_filesize'M/' $fpm_ini_file
sed -i -e '/^upload_max_filesize/ s/=.*/= '$user_max_filesize'M/' $fpm_ini_file

user_max_input_vars=${PHP_MAX_INPUT_VARS:-5000}
echo "Configuring 'max_input_vars' to $user_max_input_vars (from the default 1000)..."
sed -i '/max_input_vars/ s/;\? \?\(max_input_vars \?= \?\)[[:digit:]]\+/\1'$user_max_input_vars'/' $fpm_ini_file

# Setup timezone
user_timezone=${USER_TIMEZONE:-UTC}
echo "Configuring timezone to $user_timezone ..."
sed -i -e 's/^;date\.timezone =$/date.timezone = "'$user_timezone'"/' $fpm_ini_file
export PHP_PCNTL_FUNCTIONS='pcntl_alarm,pcntl_fork,pcntl_waitpid,pcntl_wait,pcntl_wifexited,pcntl_wifstopped,pcntl_wifsignaled,pcntl_wifcontinued,pcntl_wexitstatus,pcntl_wtermsig,pcntl_wstopsig,pcntl_signal,pcntl_signal_get_handler,pcntl_signal_dispatch,pcntl_get_last_error,pcntl_strerror,pcntl_sigprocmask,pcntl_sigwaitinfo,pcntl_sigtimedwait,pcntl_exec,pcntl_getpriority,pcntl_setpriority,pcntl_async_signals,pcntl_unshare'
export PHP_EXEC_FUNCTIONS='escapeshellarg,escapeshellcmd,exec,passthru,proc_close,proc_get_status,proc_nice,proc_open,proc_terminate,shell_exec,system'
sed -i "/disable_functions/c disable_functions = ${PHP_PCNTL_FUNCTIONS},${PHP_EXEC_FUNCTIONS}" $fpm_ini_file

[ ! -f $pool_file ] && cp /etc/php/${php_ver}/fpm/pool.d/www.conf $pool_file
sed -i -e 's/^\[www\]$/['$php_user']/' $pool_file
sed -i -e 's/www-data/'$php_user'/' $pool_file
sed -i -e '/^;listen.\(owner\|group\|mode\)/ s/^;//' $pool_file
sed -i -e '/^listen.mode = / s/[0-9]\{4\}/0666/' $pool_file

php_ver_short=$(echo $php_ver | sed 's/\.//')
socket=/run/php/fpm-${php_ver_short}-${php_user}.sock
sed -i "/^listen =/ s:=.*:= $socket:" $pool_file
# [ -f /etc/nginx/conf.d/lb.conf ] && sed -i "s:/var/lock/php-fpm.*;:$socket;:" /etc/nginx/conf.d/lb.conf
if [ ! -f /etc/nginx/conf.d/fpm${php_ver_short}.conf ]; then
    echo "upstream fpm${php_ver_short} { server unix:$socket; }" > /etc/nginx/conf.d/fpm${php_ver_short}.conf
    # following is applicable only on new servers, not during PHP upgrade.
    # echo "upstream fpm { server unix:$socket; }" > /etc/nginx/conf.d/fpm.conf
    # [ -f /etc/nginx/conf.d/lb.conf ] && rm /etc/nginx/conf.d/lb.conf
fi

sed -i -e 's/^pm = .*/pm = '$PM_METHOD'/' $pool_file
sed -i '/^pm.max_children/ s/=.*/= '$max_children'/' $pool_file

PHP_MIN=$(expr $max_children / 10)

sed -i '/^;catch_workers_output/ s/^;//' $pool_file
sed -i '/^;pm.process_idle_timeout/ s/^;//' $pool_file
sed -i '/^;pm.max_requests/ s/^;//' $pool_file
sed -i '/^;pm.status_path/ s/^;//' $pool_file
sed -i '/^;ping.path/ s/^;//' $pool_file
sed -i '/^;ping.response/ s/^;//' $pool_file

# home_basename=web
# home_basename=$(echo $wp_user | awk -F _ '{print $1}')
# [ -z $home_basename ] && home_basename=web
# [ ! -d /home/${home_basename}/log ] && mkdir /home/${home_basename}/log
PHP_SLOW_LOG_PATH="/var/log/slow-php.log"
sed -i '/^;slowlog/ s/^;//' $pool_file
sed -i '/^slowlog/ s:=.*$: = '$PHP_SLOW_LOG_PATH':' $pool_file
sed -i '/^;request_slowlog_timeout/ s/^;//' $pool_file
sed -i '/^request_slowlog_timeout/ s/= .*$/= 60/' $pool_file

FPMCONF="/etc/php/${php_ver}/fpm/php-fpm.conf"
sed -i '/^;emergency_restart_threshold/ s/^;//' $FPMCONF
sed -i '/^emergency_restart_threshold/ s/=.*$/= '$PHP_MIN'/' $FPMCONF
sed -i '/^;emergency_restart_interval/ s/^;//' $FPMCONF
sed -i '/^emergency_restart_interval/ s/=.*$/= 1m/' $FPMCONF
sed -i '/^;process_control_timeout/ s/^;//' $FPMCONF
sed -i '/^process_control_timeout/ s/=.*$/= 10s/' $FPMCONF

# restart php upon OOM or other failures
# ref: https://stackoverflow.com/a/45107512/1004587
# TODO: Do the following only if "Restart=on-failure" is not found in that file.
sed -i '/^\[Service\]/!b;:a;n;/./ba;iRestart=on-failure' /lib/systemd/system/php${php_ver}-fpm.service
systemctl daemon-reload
check_result $? "Could not update /lib/systemd/system/php${php_ver}-fpm.service file!"

printf '%-72s' "Restarting PHP-FPM..."
/usr/sbin/php-fpm${php_ver} -t 2>/dev/null && systemctl restart php${php_ver}-fpm
echo done.

printf '%-72s' "Restarting Nginx..."
/usr/sbin/nginx -t 2>/dev/null && systemctl restart nginx
echo done.

echo; echo 'All done with PHP-FPM!'; echo;
