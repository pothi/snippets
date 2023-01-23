#!/bin/bash

# version 2.1
# changelog
# 2.1
#   - date: 2022-02-25
#   - minor tweaks
# 2.0
#   - date: 2021-05-06
#   - migrate to AWS CC

# logging everything
[ ! -d ~/log ] && mkdir ~/log
log_file=~/log/update-cron.log
exec > >(tee -a ${log_file} )
exec 2> >(tee -a ${log_file} >&2)

echo; echo "Script: $0"
echo "Date / Time: $(date +%c)"

# today=$(date +%F)

[ ! -d ~/tmp ] && mkdir ~/tmp
crontab -l > ~/tmp/crontab
current_cron=~/tmp/crontab
gitdir=${1:-""}
cron_user=${2:-""}

if [ "x$gitdir" = "x" ]
then
    echo; echo "Usage: $0 /path/to/git/repo [\$hostname-\$USER]"; echo
    exit 1
fi

if [ "x$cron_user" = "x" ]
then
    cron_user=$(hostname)-$USER
fi

cd $gitdir
echo "Pulling changes..."
git pull --quiet

if [ ! -f $gitdir/$cron_user ]; then
    echo "You seem to be run this script for the first time."
    echo "Please execute 'git add .' manually."
    echo "And then, re-run this script."
    echo "This is to avoid situations where file name is not generated correctly."
fi

cp $current_cron $gitdir/$cron_user
git commit -am "Auto commit for $cron_user by $0" --quiet
if [ $? -eq 0 ]; then
    echo "Pushing changes..."
    git push --quiet
fi

rm $current_cron

echo "Done."
echo
