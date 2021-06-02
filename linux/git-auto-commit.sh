#!/usr/bin/env sh

gitdir=${1:-""}

if [ "x$gitdir" = "x" ]
then
    echo "Please enter git dir as an argument. Exiting"
    exit 1
fi

cd $gitdir
git add . && git commit -m "Auto commit by $0"
git push

