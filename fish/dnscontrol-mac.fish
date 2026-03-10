#!/usr/bin/env fish

set ver 2.2

# changelog
# 2.2:
#   - date: 2026-03-09
#   - improve logic when checking the latest version info.
#   - improve output info.
#   - more checks for failures.
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
set action "update"

set latest_version $(curl -jsL "https://api.github.com/repos/StackExchange/dnscontrol/tags" | jq -r '.[0].name' | awk -Fv '{print $2}')
if test -z $latest_version
    echo 'Could not find the latest version from GitHub for some unknown reason.'
    echo 'Probably check the internet connection.'
    exit 1
end
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
    exit 0
else
    echo "Latest version: $latest_version"
end
echo

# download only if the binary is not already downloaded.
if not test -f $downloads_dir/dnscontrol-$latest_version
    # remove any old archive
    set --local archive $downloads_dir/$latest_binary.tar.gz
    test -f $archive; and rm $archive

    printf '%-72s' 'Downloading the latest version...'
    curl -jsSL -o $archive $download_url
    if test $status -ne 0
        echo >&2 "Error downloading the latest version. Exiting prematurely."
        exit 1
    end
    echo done.

    printf '%-72s' 'Extracting the binary from the downloaded archive...'
    tar xf $archive --directory $downloads_dir/
    if test $status -ne 0
        echo >&2 "Error extracting. Exiting prematurely"
        exit 1
    end
    echo done.

    mv $downloads_dir/dnscontrol $downloads_dir/dnscontrol-$latest_version
end

ln -fs $downloads_dir/dnscontrol-$latest_version $bin_dir/dnscontrol
if test $status -ne 0
    echo >&2 "Exiting switching to the latest version. Exiting prematurely"
    echo
    exit 1
else
    echo 'The dnscontrol binary is linked to the latest version available in the downloads dir.'
end

# clean up
test -f $downloads_dir/$latest_binary.tar.gz; and rm $downloads_dir/$latest_binary.tar.gz
test -f $downloads_dir/LICENSE; and rm $downloads_dir/LICENSE
test -f $downloads_dir/README.md; and rm $downloads_dir/README.md

echo
echo Successfully {$action}d to version: $(dnscontrol version)
echo
