#!/usr/bin/env fish

# Note: Currently, arch (amd64/arm64) is tested on Oracle Ampere and DO.

# Install or update DNSControl

# Requirements: curl and jq

set bin_dir ~/.local/bin
set downloads_dir ~/.local/downloads/dnscontrol
test -d $bin_dir; or mkdir -p $bin_dir
test -d $downloads_dir; or mkdir -p $downloads_dir

set current_version 0

set latest_version $(curl -jsL "https://api.github.com/repos/StackExchange/dnscontrol/tags" | jq -r '.[0].name' | awk -Fv '{print $2}')
set latest_binary dnscontrol_{$latest_version}_darwin_all

set download_url https://github.com/StackExchange/dnscontrol/releases/download/v$latest_version/$latest_binary.tar.gz

if test -f $bin_dir/dnscontrol
    set current_version ($bin_dir/dnscontrol version)
end

# Debugging
# echo "Version: $latest_version"
# echo "Binary: $latest_binary"
# echo "Download URL: $download_url"
# echo "Current Version: $current_version"
# exit

if test $current_version = $latest_version
    echo "Latest version is already installed."
    exit 2
end

curl -jsSL -o $downloads_dir/$latest_binary.tar.gz $download_url
if test $status -ne 0
    echo "Exiting prematurely"
    exit 1
end

tar xf $downloads_dir/$latest_binary.tar.gz --directory $downloads_dir/
if test $status -ne 0
    echo "Exiting prematurely"
    exit 1
end

mv $downloads_dir/dnscontrol $downloads_dir/dnscontrol-$latest_version

ln -fs $downloads_dir/dnscontrol-$latest_version $bin_dir/dnscontrol
if test $status -ne 0
    echo "Exiting prematurely"
    exit 1
end

# clean up
rm $downloads_dir/$latest_binary.tar.gz

echo "Successfully installed/updated dnscontrol version: $(dnscontrol version)"
