#!/usr/bin/env bash

# Note: Currently, arch (amd64/arm64) is tested on Oracle Ampere and DO.

# Install or update DNSControl

# Requirements: curl and jq

latestVersion=$(curl -jsL "https://api.github.com/repos/StackExchange/dnscontrol/tags" | jq -r '.[0].name' | awk -Fv '{print $2}')

downloadURL=https://github.com/StackExchange/dnscontrol/releases/download/v${latestVersion}/dnscontrol-${latestVersion}.(uname -m | sed s/aarch64/arm64/ | sed s/x86_64/amd64/).deb

downloadedFile=~/tmp/dnscontrol-latest.deb

curl -sSLo $downloadedFile $downloadURL

sudo dpkg -i $downloadedFile

rm $downloadedFile
