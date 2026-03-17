#!/usr/bin/env fish

set ver 1.1

# changelog
# version: 1.1
#   - date: 2026-03-13
#   - minor improvements

set --local --export PATH ~/bin ~/.local/bin /usr/local/sbin /usr/local/bin /usr/sbin /usr/bin /sbin /bin /snap/bin

# echo PATH: $PATH

# check for github cli
# check for gh-clone-org extension

# set clone_path ~/backups/github-repos-(date +%Y-%m)
set clone_path ~/projects/clone-all-github-repos/(date +%Y-%m)
if test -d $clone_path
    echo
    echo Backups are taken for this month!
    echo Check the directory $clone_path
    echo
    exit 0
else
    mkdir -p $clone_path
end

# set gh_cli ~/.local/bin/gh

# $gh_cli clone-org --path $clone_path -y pothi
# $gh_cli clone-org --path $clone_path -y -s is:private pothi

echo "Date / Time: $(date +%c)"
set time_start (date +%s)

gh clone-org --path $clone_path -y pothi
gh clone-org --path $clone_path -y -s is:private pothi

echo "Date / Time: $(date +%c)"
set time_end (date +%s)
set runtime (math $time_end - $time_start)
set runtime_minutes (math -s0 $runtime / 60)
set runtime_seconds (math $runtime % 60)
echo Execution time: $runtime_minutes minutes $runtime_seconds seconds.
