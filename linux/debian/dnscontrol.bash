#!/usr/bin/env bash

# TODO: Currently, arch (amd64) is hardcoded. Find it on-the-fly to make it compatible with other platforms.

# Install or update DNSControl

# Requirements: curl and jq

latestVersion=$(curl -s "https://api.github.com/repos/StackExchange/dnscontrol/tags" | jq -r '.[0].name' | awk -Fv '{print $2}')

downloadURL=https://github.com/StackExchange/dnscontrol/releases/download/v${latestVersion}/dnscontrol-${latestVersion}.amd64.deb

downloadedFile=~/tmp/dnscontrol-latest.deb

curl -sSLo $downloadedFile $downloadURL

sudo dpkg -i $downloadedFile

rm $downloadedFile
