#!/usr/bin/env fish

# TODO: display full changes on repos that have something modified.

set ver 1.0

# changelog
# version: 1.0
#   - date: 2026-03-20
#   - first commiit

set --local log_file ~/log/pull-all-repos.log

echo -e "\nScript: $0"
echo "Date / Time: $(date +%c)"
set -l start $(date +%s)

# Test for internet
set -l inet
set -l sleep_for 3

while test -z $inet
    # curl -s --connect-timeout 3 -o /dev/null http://1.1.1.1
    # cmd="wget --spider -q http://g.co"
    set -l cmd (curl -s --connect-timeout 3 -o /dev/null http://1.1.1.1)
    if test $status -eq 0
        set inet "Online"
    else
        echo "Waiting for internet..."
        echo Sleeping for $sleep_for seconds.
        sleep $sleep_for
        if test $sleep_for -lt 60
            set sleep_for $(math "$sleep_for*2")
        end
    end
end

echo 'Internet is up!'

# git_location=$(which git)
# echo "Git location: $git_location"

printf '\n%s\t' "Running 'git pull' on ~/.ssh ... "
git -C ~/.ssh pull -q
echo -e 'done.\n'

# check for changes in repos under version control
set -l scan_dir scm

test -d ~/$scan_dir; or set scan_dir git
test -d ~/$scan_dir; or begin
    echo >&2 Scan dir ~/$scan_dir doesn\'t exist
    exit 1
end

# echo "Scan dir: ~/$scan_dir"

echo "Running 'git pull' on all repos in ~/$scan_dir ..."
for repo in $HOME/$scan_dir/*
    # skip local repos (with no remote origin url)
    # local repos don't have remote.origin.url
    if git -C "$repo" config remote.origin.url &>/dev/null
        echo "Current repo: $repo"
        git -C "$repo" pull --quiet

        # Pull changes in submodule/s
        if test -f "$repo.gitmodules"
            git -C "$repo" submodule update --remote --merge -q
        end
    else
        echo "Skipped local repo: $repo"
    end
end
echo

echo "Date / Time: $(date +%c)"
set -l end $(date +%s)
echo "Execution time: $(math $end - $start) seconds."

echo -e 'All done.\n'
