#!/usr/bin/env fish

set ver 3.0
# for m4air
set local_ip $(/usr/sbin/ipconfig getifaddr en0)
if test -z $local_ip
    # on mac mini
    set local_ip $(/usr/sbin/ipconfig getifaddr en1)
    if test -z $local_ip
        echo 'Could not find the local IP'
        exit 2
    end
end
# https://superuser.com/a/805488/142306
set router_ip $(/sbin/route -n get default | grep gateway | awk '{print $2}')
set subnet $(echo $local_ip | cut -d . -f 1-3)

# echo "Version: $version"; exit
echo " Local IP: $local_ip"
echo "Router IP: $router_ip"
# echo "Network: $subnet"; exit

echo "________________________________________"
echo " "

echo "Searching for IP addresses... Please hold on..."
for ip in (seq 254)
    # let's exclude pinging our local IP and router IP
    if test "$subnet.$ip" != "$local_ip" && test "$subnet.$ip" != "$router_ip"
        ping -i 0.002 -W 25 -c 1 -s 16 "$subnet.$ip" 2>/dev/null | grep "^24 bytes" | awk '{print $4,$7}' | tr -d :
    end
end

echo 'The one with the lowest time is likely to be the MikroTik repeater.'
echo 'If no IP address is listed, then the MikroTik repeater could be down.'
