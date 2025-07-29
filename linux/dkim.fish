#!/usr/bin/env fish

# replace example.com with the actual domain name.

# TODO:

set ver 1.0

# apt-get install opendkim -y

# let's append custom conf into opendkim.conf
if not grep -qF "CustomConf" /etc/opendkim.conf
    echo "

########## CustomConf ##########

# https://askubuntu.com/a/441536/65814
KeyTable                /etc/dkim.d/KeyTable
SigningTable            /etc/dkim.d/SigningTable
ExternalIgnoreList      /etc/dkim.d/TrustedHosts
InternalHosts           /etc/dkim.d/TrustedHosts" \
>> /etc/opendkim.conf
end

# if we don't create the following file, opendkim.server will not (re)start
test ! -d /etc/dkim.d && mkdir -p /etc/dkim.d
touch /etc/dkim.d/KeyTable
touch /etc/dkim.d/SigningTable
# if TrustedHosts doesn't exist, create & populate it with defaults
if ! test -f /etc/dkim.d/TrustedHosts
    echo "127.0.0.1
127.0.1.1
localhost" > /etc/dkim.d/TrustedHosts
end

# postconf -e 'DKIM = OpenDKIM'
# postconf -# 'DKIM'

postconf -e 'milter_default_action = accept'
postconf -e 'milter_protocol = 2'

# set dkim_socket_dir /var/spool/postfix/opendkim
# comment out the existing socket
sed -i 's/^Socket/#&/' /etc/opendkim.conf
# enable the new socket in chroot-ed postfix env
# In Debian, Postfix runs in a chroot in /var/spool/postfix
set postfix_chroot_dir /var/spool/postfix
sed -i "/spool/ s/^#\(Socket.*\)/\1/" /etc/opendkim.conf

set dkim_socket (grep -i '^SOCKET' /etc/opendkim.conf | awk -F: '{print $2}')
set dkim_socket_dir (dirname $dkim_socket)

# see the comment for the answer https://unix.stackexchange.com/a/404239/20241
# also see https://serverfault.com/a/1139487/102173
set dkim_socket_for_postfix (string replace "$postfix_chroot_dir/" "" $dkim_socket)

echo DKIM Socket: $dkim_socket
echo DKIM Socket Dir: $dkim_socket_dir
echo DKIM Socket for Postfix: $dkim_socket_for_postfix

# exit

test ! -d $dkim_socket_dir && mkdir $dkim_socket_dir
chown opendkim $dkim_socket_dir

# In Debian, opendkim runs as user "opendkim". A umask of 007 is required when
# using a local socket with MTAs that access the socket as a non-privileged
# user (for example, Postfix). You may need to add user "postfix" to group
# "opendkim" in that case.
gpasswd -a postfix opendkim

systemctl restart opendkim.service

postconf -e "smtpd_milters = local:$dkim_socket_for_postfix"
postconf -e 'non_smtpd_milters = $smtpd_milters'

postfix check
postfix reload
systemctl restart postfix.service

set selector (date +%Y%m%d)
set domains (hostname -f) example.com

echo Selector: $selector

exit

test ! -d /etc/dkim.d/keys && mkdir -p /etc/dkim.d/keys
for domain in $domains
    # TODO: Skip a domain, if relevant records exist.
    echo Domain: $domain

    set -l keydir /etc/dkim.d/keys/$domain
    test ! -d $keydir && mkdir -p $keydir

    cd $keydir
    opendkim-genkey -t -s $selector -d $domain
    chown opendkim $selector.private
    cd -

    echo "$selector._domainkey.$domain $domain:$selector:$keydir/$selector.private" >> /etc/dkim.d/KeyTable
    echo "$domain $selector._domainkey.$domain" >> /etc/dkim.d/SigningTable
    echo "$domain" >> /etc/dkim.d/TrustedHosts
end

