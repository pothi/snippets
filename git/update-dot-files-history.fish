#!/usr/bin/env fish

set repo ~/dotfiles

git -C $repo commit -m 'Update history' dot-zsh_history dot-bash_history dot-mysql_history
git -C $repo push
