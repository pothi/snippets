#!/usr/bin/env fish

set repo ~/dotfiles

git -C $repo commit -m 'Auto-update history files - zsh, bash, mysql' dot-zsh_history dot-bash_history dot-mysql_history
git -C $repo push
