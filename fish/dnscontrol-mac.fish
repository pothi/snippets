#!/usr/bin/env fish

set ver 2.4

# changelog
# 2.4:
#   - date: 2026-04-13
#   - improve variable names.
# 2.3:
#   - date: 2026-03-11
#   - check for jq command.
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

set local_version 0
set action "update"

type -q jq; or begin; echo >&2 'jq command not found'; exit 1; end

if not type -q is_internet_available
    function is_internet_available
        for sleep_duration in (seq 6 1)
            sleep 1
            ping -c 1 1.1.1.1 &> /dev/null
            if test $status -eq 0
                echo "✓ Internet connectivity: OK"
                break
            end
            if test $sleep_duration -eq 1
                echo >&2 'No Internet'
                return 1
            end
        end
    end
end

is_internet_available; or exit 1

set upstream_version $(curl -jsL "https://api.github.com/repos/StackExchange/dnscontrol/tags" | jq -r '.[0].name' | awk -Fv '{print $2}')
# alternative way
# set upstream_version $(curl -fsSL 'https://api.github.com/repos/StackExchange/dnscontrol/releases/latest' | jq -r .tag_name | awk -Fv '{print $2}')
if test -z $upstream_version
    echo 'Could not find the latest version from GitHub for some unknown reason.'
    echo 'Probably check the internet connection.'
    exit 1
end
set latest_binary dnscontrol_{$upstream_version}_darwin_all

set download_url https://github.com/StackExchange/dnscontrol/releases/download/v$upstream_version/$latest_binary.tar.gz

# pre-check

echo
echo "Bin dir: $bin_dir"
echo "Downloads dir: $downloads_dir"
echo

if test -f $bin_dir/dnscontrol
    set local_version ($bin_dir/dnscontrol version)
    echo "Local Version: $local_version"
else
    set action "install"
end

# Debugging
# echo "Version: $upstream_version"
# echo "Binary: $latest_binary"
# echo "Download URL: $download_url"
# exit

# string comparision as version looks like 1.0.0
if test $local_version = $upstream_version
    echo "Latest version ($upstream_version) is already installed."
    exit 0
else
    echo "Upstream version: $upstream_version"
end
echo

# download only if the binary is not already downloaded.
if not test -f $downloads_dir/dnscontrol-$upstream_version
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

    mv $downloads_dir/dnscontrol $downloads_dir/dnscontrol-$upstream_version
end

ln -fs $downloads_dir/dnscontrol-$upstream_version $bin_dir/dnscontrol
if test $status -ne 0
    echo >&2 "Could not switch to the latest version. Exiting prematurely"
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
