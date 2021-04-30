#!/usr/bin/env sh

[ ! -f /etc/apt/sources.list-backup ] && cp /etc/apt/sources.list /etc/apt/sources.list-backup
sed -i 's-http://archive-http://in.archive-g' /etc/apt/sources.list
