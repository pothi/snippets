#!/usr/bin/env bash

# nginx restart script for certbot

version=3.0

# put it in /etc/letsencrypt/renewal-hooks/deploy/
# make it executable (chmod +x)

# version: 3.0
#   - date: 2024-08-09
#   - complete rewrite from ssl-cert-check script by Matty
#   - migrate from cut to awk for output processing for new_certificate
#   - remove unused code
#   - use better naming scheme
#   - prepare for an alternate way to find new_expiry_date
#   - improve docs
# version: 2.4.1
#   - date: 2023-12-08
#   - migrate from cut to awk for output processing
# version: 2.4
#   - date: 2023-07-29
#   - simplify code
# version: 2.3
#   - date: 2023-07-25
#   - improve readability of expiry dates in console output and in email.
# version: 2.2
#   - date: 2023-02-20
#   - Use ADMIN_EMAIL for alerts, if CERTBOT_ADMIN_EMAIL isn't available
#   - Check for mail command.
# version: 2.0
#   - date: 2023-02-17
#   - include PATH
#   - complete refactor with current best practices
# version: 1.1
#   - date: 2022-12-1
#   - try to get CERTBOT_ADMIN_EMAIL from ~/.env(rc)
# version: 1.0
#   - date: 2021-04-22

# programming env: these switches turn some bugs into errors
# set -o errexit -o pipefail -o noclobber -o nounset
set -o pipefail
# set -x

# get environment variables, if exists
[ -f "$HOME/.envrc" ] && source ~/.envrc
[ -f "$HOME/.env" ] && source ~/.env

export PATH=~/bin:~/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin

# function to find expiry date from an SSL certificate
find_expiry_date() {
    echo "$1" | openssl x509 -noout -enddate | sed 's/notAfter\=//' | awk '{print $1, $2, $4}'
}

# the shell variable $RENEWED_LINEAGE will point to the config live subdirectory
# (for example, "/etc/letsencrypt/live/example.com")
# https://community.letsencrypt.org/t/environment-variables-available-in-etc-letsencrypt-renewal-hooks-scripts/102036
config_live_subdir=${RENEWED_LINEAGE:-""}
domain=$(basename "$config_live_subdir")

alert_email=${CERTBOT_ADMIN_EMAIL:-${ADMIN_EMAIL:-"root@localhost"}}

old_cert=$(echo "" | openssl s_client --servername ${domain} -connect ${domain}:443 2>/dev/null)
new_cert=$(cat "${config_live_subdir}/fullchain.pem")
old_expiry_date=$(find_expiry_date "$old_cert")
new_expiry_date=$(find_expiry_date "$new_cert")

# restart the web server to apply the new certificate
# this step is irrespective of finding the expiry dates (and consecutive alert)
if nginx -t 2>/dev/null; then
    if ! systemctl restart nginx; then
        echo >&2 "The command 'systemctl nginx restart' failed!!"
    fi
else
    echo >&2 "The command 'nginx -t' failed!"
fi

# alertnative way to find new_expiry_date after restarting the server
# new_cert=$(echo "" | openssl s_client --servername ${domain} -connect ${domain}:443 2>/dev/null)
# new_expiry_date=$(find_expiry_date "$new_cert")

# alert
msg=$(printf "\nCertificate for the domain %s is renewed.\n\nThe old expiry date: %s.\nThe new expiry date: %s.\n\nIf you did not expect the above output, please check the logs at /var/log/letsencrypt/.\n" "$domain" "$old_expiry_date" "$new_expiry_date")

if command -v mail >/dev/null; then
    echo "$msg" | mail -s "Renewal of $domain" $alert_email
else
    echo >&2 "[Warn]: 'mail' command is not found in \$PATH; Email alerts will not be sent to '$alert_email'."
    echo "$msg"
fi
