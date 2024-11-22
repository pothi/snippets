#!/usr/bin/env fish

# Variables

# comma separated list of emails to send the alert
set admin_emails

# To alert when the disk usage reaches a threshold in DigitalOcean Volume Block Storage.
# Can be used for any volumes, though.

# you may put it on /etc/update-motd.d/99-symlink_to_this_script to run it upon every login

set ver 1.2

# https://docs.digitalocean.com/products/volumes/how-to/create/#automatically-format--mount
# /etc/systemd/system/mnt-volume_*.mount

set mount_vol /
# set mount_vol /mnt/volume_name
set threshold 50

# to display it as motd...
# ln it to /etc/update-motd.d/NN-xxxxxxx
# where NN is a two digit number indicating their position in the MOTD, and xxxxxx is the script name
# Scripts must not have filename extensions

# get human-readable disk size
set sizeP (df -h | grep -w $mount_vol | awk '{print $5}')
# echo Disk Usage of $mount_vol: {$sizeP}


# remove the last char of the above result.
set sizeN (echo $sizeP | tr -d '%' )
# echo Size: $sizeN

if test $sizeN -gt (math $threshold -1)
    echo (set_color red;)Alert(set_color normal;): The disk usage (set_color -o black;)$mount_vol(set_color normal;) is at (set_color -o red;){$sizeN}%(set_color normal;) that reached the threshold \({$threshold}%\)!

    set email_msg (echo Alert: The disk usage $mount_vol is at {$sizeN}% that reached the threshold \({$threshold}%\)!)
    if not set -q $admin_emails
        echo $email_msg | mail --append=Bcc:"$admin_emails" -s 'Disk Usage Alert' root
    else
        echo $email_msg | mail -s 'Disk Usage Alert' root
    end
else
    echo The disk usage of (set_color -o black;)$mount_vol(set_color normal;) is at (set_color green;){$sizeN}%(set_color normal;), below the threshold {$threshold}%.
end

echo;
