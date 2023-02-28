#!/usr/bin/env bash

# nginx restart script for certbot

# version=2.2

# put it in /etc/letsencrypt/renewal-hooks/deploy/
# make it executable (chmod +x)

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

# the shell variable $RENEWED_LINEAGE will point to the config live subdirectory
# (for example, "/etc/letsencrypt/live/example.com") containing the new certs and
# keys; the shell variable $RENEWED_DOMAINS will contain a space-delimited list
# of renewed cert domains (for example, "example.com www.example.com").
# https://community.letsencrypt.org/t/environment-variables-available-in-etc-letsencrypt-renewal-hooks-scripts/102036
config_live_subdir=${RENEWED_LINEAGE:-""}

certbot_domain=$(basename "$config_live_subdir")
certbot_admin_email=${CERTBOT_ADMIN_EMAIL:-${ADMIN_EMAIL:-"root@localhost"}}
ssl_utility=/root/bin/ssl-cert-check
old_expiry_date=
new_expiry_date=

old_expiry_date=$(echo | openssl s_client --servername ${certbot_domain} -connect ${certbot_domain}:443 2>/dev/null | openssl x509 -noout -dates | grep notAfter | awk -F= '{print $2}' | cut -d ' ' -f 1,2,4)

if nginx -t 2>/dev/null; then
    if ! systemctl restart nginx; then
        echo >&2 "The command 'systemctl nginx restart' failed!!"
    fi
else
    echo >&2 "The command 'nginx -t' failed!"
fi

new_expiry_date=$(cat "${RENEWED_LINEAGE}/fullchain.pem" | openssl x509 -noout -dates | grep notAfter | awk -F= '{print $2}' | cut -d ' ' -f 1,2,4)

if command -v mail >/dev/null; then
    printf '\nCertificate for the domain %s is renewed.\n\nThe old expiry date was %s.\nThe new expiry date is %s.\n\nIf you did not expect the above output, please check the logs at /var/log/letsencrypt/.\n' "$certbot_domain" "$old_expiry_date" "$new_expiry_date" | mail -s "Renewal of $certbot_domain" $certbot_admin_email
else
    echo >&2 "[Warn]: 'mail' command is not found in \$PATH; Email alerts will not be sent!"
    printf '\nCertificate for the domain %s is renewed.\n\nThe old expiry date was %s.\nThe new expiry date is %s.\n\nIf you did not expect the above output, please check the logs at /var/log/letsencrypt/.\n' "$certbot_domain" "$old_expiry_date" "$new_expiry_date"
fi
