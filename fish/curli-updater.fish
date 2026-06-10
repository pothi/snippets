#!/usr/bin/env fish

set ver 1.1

# Currently installs the binary correctly on a linux machine.
# TODO: Update logic - check for version_dir
# TODO: Update on linux
# TODO: update on macOS

# changelog
# 1.1
#   - date: 2026-05-07
#   - improve symlink name
#   - add installation compatibility with macOS

set repo curl-impersonate
set owner lexiforest # active fork
# set -l owner lwthiker # original owner

set debug

set log_dir ~/log
# set -l log_file $log_dir/curli-update.log
set base_dir ~/.local/downloads
set curli_symlink $base_dir/$repo

mkdir -p $log_dir $base_dir

type -q jq; or begin; echo >&2 'jq command not found'; exit 1; end

set local_version
set upstream_version (curl -sSL "https://api.github.com/repos/$owner/$repo/tags" | jq -r '.[0].name')

set version_dir $base_dir/$repo-$upstream_version

set __os
set __arch

switch (uname)
    case Linux
        set __os linux
    case Darwin
        # set __os darwin
        set __os macos
    case '*'
        echo >&2 'Unknown OS'; exit;
end
test -z $debug; or echo "OS: $__os"

switch (uname -m)
    case amd64 x86_64
        set __arch x86_64
    case arm64
        set __arch arm64
    case aarch64
        set __arch aarch64
    case '*'
        echo >&2 'Unknown architecture: ' (uname -m); exit;
end
test -z $debug; or echo "Arch: $__arch"

set variant # applicable only on linux

set os_variant $__os

if test $__os = 'linux'
    if string match -q "*android*" $__os
        set variant "android"
    else if test -f /etc/alpine-release
        set variant "musl"
    else
        # Fallback: check what ldd actually links against
        if ldd /bin/sh 2>&1 | string match -q "*musl*"
            set variant "musl"
        else
            set variant "gnu"
        end
    end

    set os_variant $__os-$variant
end

echo "Detected: OS=$__os | Arch=$__arch | Variant (on Linux)=$variant"

function update-curli
    echo "=== curl-impersonate Updater - "(date)" ==="
    # echo "Log file: $log_file"
    echo ""

    if test -d $curli_symlink
        # echo Existing installation found.
    end

    # 1. Check current version
    set -l current_bin $curli_symlink/curl-impersonate
    if test -x $current_bin
        # echo "Current binary exists at: $current_bin"
        # echo "Current version:" (string replace -r '.*curl-impersonate (.*)' '$1' ($current_bin --version | head -n1))
        # else
        # echo "No current curl-impersonate found (first install)."
    end

    echo ""

    echo "Downloading latest curl-impersonate..."

    # GitHub latest release redirect
    set -l download_url "https://github.com/$owner/$repo/releases/download/$upstream_version/curl-impersonate-$upstream_version.$__arch-$os_variant.tar.gz"

    echo Download URL: $download_url
    # exit

    mkdir -p $version_dir
    cd $version_dir

    if curl -L -# -o curl-impersonate.tar.gz $download_url
        echo "Download successful."
    else
        echo "ERROR: Download failed!"
        return 1
    end

    # 3. Extract
    tar -xzf curl-impersonate.tar.gz
    rm curl-impersonate.tar.gz

    # 4. Make executable and create symlink
    chmod +x $version_dir/curl-impersonate

    # Remove old symlink if exists
    if test -L $curli_symlink
        rm $curli_symlink
    end

    ln -s $version_dir $curli_symlink

    echo "Update completed!"
    echo "New version linked to: $curli_symlink"
    echo "Binary path: $curli_symlink/curl-impersonate"
    echo "Version info:" ($curli_symlink/curl-impersonate --version | head -n1)
    echo "========================================"
    echo ""

    echo "✅ curl-impersonate updated successfully!"
    echo "You can now run: curli https://example.com"
end

update-curli 2>&1 | tee -a ~/log/(status basename | awk -F. '{print $1}').log
