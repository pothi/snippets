#!/usr/bin/env bash

# programming env: these switches turn some bugs into errors
# set -o errexit -o pipefail -o noclobber -o nounset

# Version: 1.0

# to be run as root, probably as a user-script just after a server is installed
# https://stackoverflow.com/a/52586842/1004587
# also see https://stackoverflow.com/q/3522341/1004587
is_user_root () { [ "${EUID:-$(id -u)}" -eq 0 ]; }
[ is_user_root ] || { echo 'You must be root or have sudo privilege to run this script. Exiting now.'; exit 1; }

export PATH=~/bin:~/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin
export DEBIAN_FRONTEND=noninteractive

echo "Script started on (date & time): $(date +%c)"

# Function to exit with an error message
check_result() {
    if [ $? -ne 0 ]; then
        echo; echo "Error: $1"; echo
        exit 1
    fi
}

# function to configure timezone to UTC
set_utc_timezone() {
    if [ "$(date +\%Z)" != "UTC" ] ; then
        [ ! -f /usr/sbin/tzconfig ] && apt-get -qq install tzdata > /dev/null
        printf '%-72s' "Setting up timezone..."
        ln -fs /usr/share/zoneinfo/UTC /etc/localtime
        dpkg-reconfigure -f noninteractive tzdata
        # timedatectl set-timezone UTC
        check_result $? 'Error setting up timezone.'

        # Recommended to restart cron after every change in timezone
        systemctl restart cron
        check_result $? 'Error restarting cron daemon after changing timezone.'
        echo done.
    fi
}

# if ~/.envrc doesn't exist, create it
if [ ! -f "$HOME/.envrc" ]; then
    touch ~/.envrc
    chmod 600 ~/.envrc
# if exists, source it to apply the env variables
else
    . ~/.envrc
fi

#--- apt tweaks ---#

# Ref: https://wiki.debian.org/Multiarch/HOWTO
# https://askubuntu.com/a/1336013/65814
[ ! $(dpkg --get-selections | grep -q i386) ] && dpkg --remove-architecture i386 2>/dev/null

# Fix apt ipv4/6 issue
[ ! -f /etc/apt/apt.conf.d/1000-force-ipv4-transport ] && \
echo 'Acquire::ForceIPv4 "true";' > /etc/apt/apt.conf.d/1000-force-ipv4-transport

# Fix a warning related to dialog
# run `debconf-show debconf` to see the current /default selections.
echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

# the following runs when apt cache is older than 6 hours
# Taken from Ansible - https://askubuntu.com/a/1362550/65814
APT_UPDATE_SUCCESS_STAMP_PATH=/var/lib/apt/periodic/update-success-stamp
APT_LISTS_PATH=/var/lib/apt/lists
if [ -f "$APT_UPDATE_SUCCESS_STAMP_PATH" ]; then
    if [ -z "$(find "$APT_UPDATE_SUCCESS_STAMP_PATH" -mmin -360 2> /dev/null)" ]; then
            printf '%-72s' "Updating apt cache"
            apt-get -qq update
            echo done.
    fi
elif [ -d "$APT_LISTS_PATH" ]; then
    if [ -z "$(find "$APT_LISTS_PATH" -mmin -360 2> /dev/null)" ]; then
            printf '%-72s' "Updating apt cache"
            apt-get -qq update
            echo done.
    fi
fi

# echo -------------------------- Prerequisites ------------------------------------
# apt-utils to fix an annoying non-critical bug on minimal images. Ref: https://github.com/tianon/docker-brew-ubuntu-core/issues/59
apt-get -qq install apt-utils &> /dev/null

# powermgmt-base to fix a warning in unattended-upgrade.log
required_packages="fail2ban \
    powermgmt-base \
    nginx-extras"

for package in $required_packages
do
    if dpkg-query -W -f='${status}' $package 2>/dev/null | grep -q "ok installed"
    then
        # echo "'$package' is already installed"
        :
    else
        printf '%-72s' "Installing '${package}' ..."
        apt-get -qq install $package > /dev/null
        check_result "Error: couldn't install $package."
        echo done.
    fi
done

#--- setup timezone ---#
set_utc_timezone

# Create a WordPress user with /home/web as $HOME
app_user=${SSH_USERNAME:-""}
if [ "$app_user" == "" ]; then
printf '%-72s' "Creating a WP User..."
    app_user="wp_$(openssl rand -base64 32 | tr -d /=+ | cut -c -10)"
    echo "export SSH_USERNAME=$app_user" >> /root/.envrc

    # home_basename=$(echo $app_user | awk -F _ '{print $1}')
    # [ -z $home_basename ] && home_basename=web
    home_basename=web

    useradd --shell=/bin/bash -m --home-dir /home/${home_basename} $app_user
    chmod 755 /home/$home_basename

    groupadd ${home_basename}
    gpasswd -a $app_user ${home_basename} > /dev/null
echo done.
fi

# Create password for WP User
app_pass=${SSH_PASSWORD:-""}
if [ "$app_pass" == "" ]; then
printf '%-72s' "Creating password for WP user..."
    app_pass=$(openssl rand -base64 32 | tr -d /=+ | cut -c -20)
    echo "export SSH_PASSWORD=$app_pass" >> /root/.envrc

    echo "$app_user:$app_pass" | chpasswd
echo done.
fi

# provide sudo access without passwd to WP User
if [ ! -f /etc/sudoers.d/$app_user ]; then
printf '%-72s' "Providing sudo privilege for WP user..."
    echo "${app_user} ALL=(ALL) NOPASSWD:ALL"> /etc/sudoers.d/$app_user
    chmod 400 /etc/sudoers.d/$app_user
echo done.
fi

# Enable password authentication for WP User
cd /etc/ssh/sshd_config.d
if [ ! -f enable-passwd-auth.conf ]; then
printf '%-72s' "Enabling Password Authentication for WP user..."
    echo "PasswordAuthentication yes" > enable-passwd-auth.conf
    /usr/sbin/sshd -t && systemctl restart sshd
    check_result $? 'Error restarting SSH daemon while enabling passwd auth.'
echo done.
fi
cd - 1> /dev/null

echo ---------------------------------- Nginx -------------------------------------

# take a backup before making changes
[ -d ~/backups ] || mkdir ~/backups
[ -f "$HOME/backups/nginx-$(date +%F)" ] || cp -a /etc/nginx ~/backups/nginx-"$(date +%F)"

# Download WordPress Nginx repo and copy its content to /etc/nginx
[ ! -d ~/wp-nginx ] && {
    mkdir ~/wp-nginx
    wget -q -O- https://github.com/pothi/wordpress-nginx/tarball/main | tar -xz -C ~/wp-nginx --strip-components=1
    cp -a ~/wp-nginx/{conf.d,errors,globals,sites-available} /etc/nginx/
    [ ! -d /etc/nginx/sites-enabled ] && mkdir /etc/nginx/sites-enabled
    ln -fs /etc/nginx/sites-available/default.conf /etc/nginx/sites-enabled/default.conf
}

# Remove the default conf file supplied by OS
[ -f /etc/nginx/sites-enabled/default ] && rm /etc/nginx/sites-enabled/default

# Remove the default SSL conf to support latest SSL conf.
# It should hide two lines starting with ssl_
# ^ starting with...
# \s* matches any number of space or tab elements before ssl_
# when run more than once, it just doesn't do anything as the start of the line is '#' after the first execution.
sed -i 's/^\s*ssl_/# &/' /etc/nginx/nginx.conf

# create dhparam
if [ ! -f /etc/nginx/dhparam.pem ]; then
    openssl dhparam -dsaparam -out /etc/nginx/dhparam.pem 4096 &> /dev/null
    sed -i 's:^# \(ssl_dhparam /etc/nginx/dhparam.pem;\)$:\1:' /etc/nginx/conf.d/ssl-common.conf
fi

echo -----------------------------------------------------------------------------
echo "Please check ~/.envrc for all the credentials."
echo -----------------------------------------------------------------------------

printf '%-72s' "Restarting Nginx..."
/usr/sbin/nginx -t 2>/dev/null && systemctl restart nginx
echo done.

echo --------------------------- Certbot -----------------------------------------
snap install core
snap refresh core
apt-get -qq remove certbot
snap install --classic certbot
ln -fs /snap/bin/certbot /usr/bin/certbot

# register certbot account if email is supplied
if [ $CERTBOT_ADMIN_EMAIL ]; then
    certbot show_account &> /dev/null
    if [ "$?" != "0" ]; then
        certbot -m $CERTBOT_ADMIN_EMAIL --agree-tos --no-eff-email register
    fi
fi

# Restart script upon renewal; it can also alert upon success or failure
# See - https://github.com/pothi/snippets/blob/main/ssl/nginx-restart.sh
[ ! -d /etc/letsencrypt/renewal-hooks/deploy/ ] && mkdir -p /etc/letsencrypt/renewal-hooks/deploy/
restart_script=/etc/letsencrypt/renewal-hooks/deploy/nginx-restart.sh
restart_script_url=https://github.com/pothi/snippets/raw/main/ssl/nginx-restart.sh
[ ! -f "$restart_script" ] && {
    wget -q -O $restart_script $restart_script_url
    check_result $? "Error downloading Nginx Restart Script for Certbot renewals."
    chmod +x $restart_script
}

echo All done.

echo -----------------------------------------------------------------------------
echo You may find the login credentials of SFTP/SSH user in /root/.envrc file.
echo -----------------------------------------------------------------------------

echo 'You may reboot (only once) to apply certain updates (ex: kernel updates)!'
echo

echo "Script ended on (date & time): $(date +%c)"
echo
