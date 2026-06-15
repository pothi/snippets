#!/usr/bin/env fish

# TODO: log file for updates

# variables

set REPO local_adminer_script
set REPO_OWNER vrana

set local_adminer_script ~/sites/example.com/public/adminer.php

# info

set ver 1.0

# changelog
# 1.1
#   - date: 2026-04-14
#   - check existance of adminer script.

# checks

if not test -f $local_adminer_script
    echo Adminer script is not found at $local_adminer_script .
    exit 1
end

set local_version (grep '* @version' $local_adminer_script | awk '{print $3}')
set upstream_version (curl -sSL "https://api.github.com/repos/$REPO_OWNER/$REPO/tags" | jq -r '.[0].name' | string trim -c v)

set download_url https://github.com/$REPO_OWNER/$REPO/releases/download/v$upstream_version/adminer-$upstream_version.php

echo "Installed Version: $local_version"

if test "$local_version" = $upstream_version
    echo No updates found.
else
    echo "Upstream Version: $upstream_version"

    cp $local_adminer_script ~/backups/adminer/$current_version-adminer.php
    echo Updating to $upstream_version ...
    curl -jsSL -o $local_adminer_script $download_url
end
