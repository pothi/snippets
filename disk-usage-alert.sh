#!/bin/bash
# set -x
# Shell script to monitor or watch the disk space
# It will send an email to $ADMIN_EMAIL, if the (free available) percentage of space is >= 90%.
# -------------------------------------------------------------------------
# Set ADMIN_EMAIL email so that you can get email.
ADMIN_EMAIL="pothi@tinywp.com"

# set ALERT_LEVEL level 80% is default
ALERT_LEVEL=80

# Exclude list of unwanted monitoring, if several partions then use "|" to separate the partitions.
# An example: EXCLUDE_LIST="/dev/hdd1|/dev/hdc5"
EXCLUDE_LIST="/auto/ripper"

#
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#
function main_prog() {
while read output;
do
#echo $output
  usep=$(echo $output | awk '{ print $1}' | cut -d'%' -f1)
  partition=$(echo $output | awk '{print $2}')
  if [ $usep -ge $ALERT_LEVEL ] ; then
     echo "Running out of space \"$partition ($usep%)\" on server $(hostname -f | awk -F. '{print $2"."$3}'), $(date)" | \
       mail -s "ALERT: Almost out of disk space $usep%" $ADMIN_EMAIL
  fi
done
}

if [ "$EXCLUDE_LIST" != "" ] ; then
  df -H | grep -vE "^Filesystem|tmpfs|cdrom|${EXCLUDE_LIST}" | awk '{print $5 " " $6}' | main_prog
else
  df -H | grep -vE "^Filesystem|tmpfs|cdrom" | awk '{print $5 " " $6}' | main_prog
fi