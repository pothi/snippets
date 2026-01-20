#!/usr/bin/env fish

set ver 1.0

set -xp PATH ~/bin:~/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin

# check for github cli
# check for gh-clone-org extension

set clone_path ~/backups/github-repos-(date +%F)
mkdir -p $clone_path

# set gh_cli ~/.local/bin/gh

# $gh_cli clone-org --path $clone_path -y pothi
# $gh_cli clone-org --path $clone_path -y -s is:private pothi
gh clone-org --path $clone_path -y pothi
gh clone-org --path $clone_path -y -s is:private pothi
