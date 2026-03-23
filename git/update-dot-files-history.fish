#!/usr/bin/env fish

set repo ~/dotfiles

git -C $repo commit -m 'Auto-update history files - zsh, bash, mysql, vim' dot-zsh_history dot-bash_history dot-mysql_history dot-config/vim/.netrwhist
git -C $repo push
