#!/usr/bin/env fish

set ver 2.1

# changelog
# 2.1
#   - date: 2026-02-25
#   - improve docs.
# 2.0:
#   - date: 2025-09-08
#   - clean up license and readme.md

# Note: Tested on...
#   - macOS
#   - arm64 on Oracle Ampere
#   - amd64 on DO.

# Install or update DNSControl

# Requirements: curl and jq

set bin_dir ~/.local/bin
set downloads_dir ~/.local/downloads/dnscontrol
test -d $bin_dir; or mkdir -p $bin_dir
test -d $downloads_dir; or mkdir -p $downloads_dir

set current_version 0
set action "upgrade"

set latest_version $(curl -jsL "https://api.github.com/repos/StackExchange/dnscontrol/tags" | jq -r '.[0].name' | awk -Fv '{print $2}')
set latest_binary dnscontrol_{$latest_version}_darwin_all

set download_url https://github.com/StackExchange/dnscontrol/releases/download/v$latest_version/$latest_binary.tar.gz

# pre-check

echo
echo "Bin dir: $bin_dir"
echo "Downloads dir: $downloads_dir"
echo

if test -f $bin_dir/dnscontrol
    set current_version ($bin_dir/dnscontrol version)
    echo "Current Version: $current_version"
else
    set action "install"
end

# Debugging
# echo "Version: $latest_version"
# echo "Binary: $latest_binary"
# echo "Download URL: $download_url"
# exit

if test $current_version = $latest_version
    echo "Latest version is already installed."
    exit 2
else
    echo "Latest version: $latest_version"
end
echo

echo Downloading the latest version...
curl -jsSL -o $downloads_dir/$latest_binary.tar.gz $download_url
if test $status -ne 0
    echo "Error downloading the latest version. Exiting prematurely."
    exit 1
end

echo Extracting the binary from the downloaded archive...
tar xf $downloads_dir/$latest_binary.tar.gz --directory $downloads_dir/
if test $status -ne 0
    echo "Error extracting. Exiting prematurely"
    exit 1
end

mv $downloads_dir/dnscontrol $downloads_dir/dnscontrol-$latest_version

ln -fs $downloads_dir/dnscontrol-$latest_version $bin_dir/dnscontrol
if test $status -ne 0
    echo "Exiting switching to the latest version. Exiting prematurely"
    exit 1
else
    echo 'The dnscontrol binary is linked to the latest version available in the download dir.'
end

# clean up
rm $downloads_dir/$latest_binary.tar.gz
rm $downloads_dir/LICENSE
rm $downloads_dir/README.md

echo
echo Successfully {$action}d to version: $(dnscontrol version)
echo
