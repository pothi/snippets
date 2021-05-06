#!/bin/bash

# version 2.0
# changelog
# version 2.0
#   - date: 2021-05-06
#   - migrate to AWS CC

# logging everything
# log_file=~/log/cron.log
# exec > >(tee -a ${log_file} )
# exec 2> >(tee -a ${log_file} >&2)

# echo; echo "Script: $0"
# echo "Date / Time: $(date +%c)"

# today=$(date +%F)

[ ! -d ~/tmp ] && mkdir ~/tmp
crontab -l > ~/tmp/crontab
current_cron=~/tmp/crontab
gitdir=${1:-""}
cron_user=${2:-""}

if [ "x$gitdir" = "x" ]
then
    echo; echo "Usage: $0 /path/to/git/repo [hostname-cronuser]"; echo
    exit 1
fi

if [ "x$cron_user" = "x" ]
then
    cron_user=$(hostname)-$USER
fi

# echo "Cron User: '$cron_user'"

cd $gitdir
echo "Pulling changes..."
git pull --quiet
cp $current_cron $gitdir/$cron_user
git commit -am "Auto commit for $cron_user by $0" --quiet
echo "Pushing changes..."
git push --quiet

rm $current_cron

echo "Done."
echo
