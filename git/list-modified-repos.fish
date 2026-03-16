#!/usr/bin/env fish

set ver 1.0

# check for changes in ~/.ssh dir
set git_status (git -C ~/.ssh status --short)
if not test -z "$git_status"
    echo 'git status on ~/.ssh ...'
    echo -e "$git_status\n"
end

# check for changes in repos under version control
set scan_dir scm

test -d ~/$scan_dir; or set scan_dir git
test -d ~/$scan_dir; or begin
    echo >&2 Scan dir ~/$scan_dir doesn\'t exist
    exit 1
end

# echo Scan dir: $scan_dir

echo Running 'git status' on repos inside ~/$scan_dir ...
echo

for repo in $HOME/$scan_dir/*
    if not test -d $repo/.git
        # skip directory without version control
        continue
    end

    set git_status (git -C $repo status --short)
    if not test -z "$git_status"
        echo Repo: $repo
        echo -e $git_status\n
    end
end
