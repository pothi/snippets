#!/bin/bash

# logging everything
log_file=~/log/cron.log
exec > >(tee -a ${log_file} )
exec 2> >(tee -a ${log_file} >&2)

echo; echo "Script: $0"
echo "Date / Time: $(date +%c)"

today=$(date +%F)
backup_folder=~/Dropbox/backups/$(hostname)/pothi/crontabs
backup_file=$backup_folder/crontab-$today

[ ! -d $backup_location ] && mkdir -p $backup_location
[ ! -d ~/tmp ] && mkdir ~/tmp
crontab -l > ~/tmp/crontab
original=~/tmp/crontab

file_to_check=$backup_file

for i in $(seq 1 31);
do
    if [ ! -f $file_to_check ] ; then
        # echo "Value of i: $i"
        olddate=$(date --date="$i days ago" +%F)
        file_to_check=$backup_folder/crontab-$olddate
    else
        diff $original $file_to_check &> /dev/null
        if [ $? -ne 0 ] ; then
            mv $original $backup_file
            echo "New backup is taken. You can find it at '$backup_location'."
        else
            olddate=$(date --date="$(expr $i - 1) days ago" +%F)
            echo "No difference. Last backup was done on $olddate."
            # if [ $i -eq 31 ]; then
                # take monthly backup
                # mv $original $backup_file
                # echo 'Monthly backup is taken.'
            # fi
        fi
        break
        # echo "Value of i: $i"
    fi

    # if run after more than a month
    if [ $i -eq 31 ]; then
        # take monthly backup
        mv $original $backup_file
        echo "A new backup is taken, since the last backup is older than a month!"
        echo "You may find the new backup at '$backup_location'."
    fi
done

echo
