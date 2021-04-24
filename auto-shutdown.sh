#!/bin/bash

# ref: http://www.linuxquestions.org/questions/linux-server-73/auto-suspend-for-my-home-server-730037/

# changelog
# v3
#   - 2017-05-08
#   - include Xorg in the list of processes to check

sleep 180     # Sleep for 3 mins to make sure the server don't shut down right away
class=192.168.83
# myIP=$(/sbin/ifconfig | egrep -o "192.168.178.[0-9]{1,3}")
myIP="${class}.11"
failcount=0
maxfail=3       # Set the number of failure count before we do a shutdown
SLEEP=300       # Numbers of seconds between each check/loop, right now 5 min

LOGFILE=/var/log/auto-shutdown.log
exec > >(tee -a ${LOGFILE} )
exec 2> >(tee -a ${LOGFILE} >&2)

# Don't suspend if one of the following processes is active (separate by space):
STOPPROCS='storeBackup wget Xorg'

echo Logfile=$LOGFILE

unset known_host

_ping_last_host() {
  # try to ping the last known active host
  # return 0 on success, otherwise 1
  if [ $known_host ]; then
    echo -n "`date` - pinging last known host $known_host - "
    ping -c 1 -s 8 -t 1 $known_host >/dev/null;
    if [ $? -eq 0 ]; then 
      # Jepp! We're done
      return 0
    else
      echo "fail"
      unset known_host
      return 1
    fi;
  else
    return 1
  fi
  
}

_ping_range() {
  # Ping an IP-range and look for a responding host.
  # If there is one store it's IP in $known_host and return 0
  # return 0 on success, otherwise 1
  cnt=0
  echo -n "`date` - pinging range...  "
  for i in {200..219}; # Set the range   192.168.178.20 through .200
  do
    # Ignore my own ip
    if ! [ ${class}.${i} = $myIP ]; then
      ping -c 1 -s 8 -t 1 ${class}.${i} >/dev/null

      if [ $? -eq 0 ]; then 
        echo -n "${class}.${i} - "
        known_host=${class}.${i}
        return 0;
      fi
    fi
  done
  return 1
}

_shutdown() {  
  # Do a shutdown if we failed for $failcount rounds
  # We need a script suspend.sh in the current directory
  if [ $failcount -eq $maxfail ];then 
    echo "`date` - going to shutdown now!"
    # off cause you cold place a "powersave -u" here too
    # ./suspend.sh
    /sbin/shutdown now
    # for testing
    # echo "`date` - back from shutdown"
    failcount=0;
  fi
}

while [ 1 ];
do
  proc_found=0
  # look if uniterruptable jobs are running
  for proc in $STOPPROCS
  do
    if [ "`pgrep --full $proc`" != "" ];then 
      echo "`date` - $proc is running."
      proc_found=1
      break
    fi
  done 
  # echo procfound=$proc_found 
  echo "Number of uninterruptable processes found: $proc_found"

  if [ $proc_found -eq 0 ]; then
    # look for other hosts, that are alive in our subnet
    _ping_last_host
    if [ $? -ne 0 ];then
      _ping_range
      if [ $? -ne 0 ];then
        let failcount++;
        echo "failure No. $failcount"
        _shutdown;
      else
        echo "good."
        failcount=0;
      fi
      else
        echo "good."
        failcount=0;
    fi
  fi
  sleep $SLEEP;
done
