#!/usr/bin/env fish

#TODO: Alert via email

# To alert when the disk usage reaches a threshold in DigitalOcean Volume Block Storage.
# Can be used for any volumes, though.

set ver 1.0

# https://docs.digitalocean.com/products/volumes/how-to/create/#automatically-format--mount
# /etc/systemd/system/mnt-volume_*.mount

set mount_vol /mnt/volume_name
set threshold 45

# to display it as motd...
# ln it to /etc/update-motd.d/NN-xxxxxxx
# where NN is a two digit number indicating their position in the MOTD, and xxxxxx is the script name
# Scripts must not have filename extensions

# get human-readable disk size
set sizeH (df -h | grep $mount_vol | awk '{print $3}')
# echo Disk Usage of $mount_vol: {$sizeH}G

# remove the last char of the above result.
set sizeN (echo $sizeH | cut -c -(math (string length $sizeH) - 1))
# echo Size: $sizeN

if test $sizeN -gt (math $threshold -1)
    echo (set_color red;)Alert(set_color normal;): The disk usage (set_color -o black;)$mount_vol(set_color normal;) is at (set_color -o red;){$sizeN}GB(set_color normal;) that reached the threshold \({$threshold}GB\)!

    set email_msg (echo Alert: The disk usage $mount_vol is at {$sizeN}GB that reached the threshold \({$threshold}GB\)!)
    # echo $email_msg | mail --append=Bcc:ubuntu@localhost,noreply@gmail.com -s 'Disk Usage Alert' root
    echo $email_msg | mail -s 'Disk Usage Alert' root
else
    echo The disk usage of (set_color -o black;)$mount_vol(set_color normal;) is at (set_color green;){$sizeN}GB(set_color normal;), below the threshold {$threshold}GB.
end

echo;
