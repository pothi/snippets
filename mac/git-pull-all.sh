#!/bin/sh

# set -x

# TODO: Check for internet and then run the rest of the code

# Test for internet
inet=

while [ -z $inet ]; do
    wget -q --spider http://g.co

    if [ $? -eq 0 ]; then
        inet="Online"
    else
        echo "Offline"
        sleep 3
    fi
done

echo "Running 'git pull' on all directories inside ~/git/ ..."

for d in ~/git/*/; do
    echo; echo "Current dir: $d"
    git -C $d pull -q
done

echo
