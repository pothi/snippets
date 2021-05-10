#!/usr/bin/env sh

# Commands to quickly migrate Github repo from master branch to main branch

# Ref: https://docs.github.com/en/github/administering-a-repository/renaming-a-branch#updating-a-local-clone-after-a-branch-name-changes

git branch -m master main
git fetch origin
git branch -u origin/main main
git remote set-head origin -a
git remote prune origin
