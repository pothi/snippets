#!/bin/sh

# set -x

echo "Running 'git pull' on all directories inside ~/git/ ..."

for d in ~/git/*/; do
    echo; echo "Current dir: $d"
    git -C $d pull
done

echo
