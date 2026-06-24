#!/usr/bin/env fish

# xAI - https://grok.com/share/c2hhcmQtMi1jb3B5_8d1da331-5a7a-4ac0-a157-425b2cbe5160

# === CONFIG ===
set KNOWN_VERSION "3.3.15"          # ← Update this to your current installed version
set EMAIL_TO "pothi"
set EMAIL_SUBJECT "phpBB Update Available!"
set LOG_FILE ~/log/phpbb-update-check.log
set STATE_FILE "$HOME/.cache/phpbb_latest_version"
set ENV_FILE "$HOME/.env"

# Load from ~/.env if it exists
if test -f $ENV_FILE
    # Simple parser for KEY=value lines (ignores comments and empty lines)
    for line in (cat $ENV_FILE | string match -r '^\s*[^#]' | string trim)
        set -l key (echo $line | cut -d= -f1 | string trim)
        set -l value (echo $line | cut -d= -f2- | string trim -c '"\'')
        if test "$key" = "EMAIL_TO"
            set EMAIL_TO $value
        end
    end
end

# Override with command line argument if provided
for arg in $argv
    if string match -- "--email=*" $arg
        set EMAIL_TO (string replace -- "--email=" "" $arg)
    else if string match -- "--email" $arg
        # Next argument is the email (simple handling)
        set next_index (math (contains -i -- $arg $argv) + 1)
        if test $next_index -le (count $argv)
            set EMAIL_TO $argv[$next_index]
        end
    end
end

# Final fallback
if not set -q EMAIL_TO
    set EMAIL_TO $DEFAULT_EMAIL
end

# Create dirs/files
mkdir -p (dirname $LOG_FILE)
touch $STATE_FILE

# === Fetch latest version ===
set latest_tag (curl -fsSL "https://api.github.com/repos/phpbb/phpbb/tags?per_page=50" \
    | jq -r '.[].name | select(test("^release-3+"))' \
    | head -n 1)

if test -z "$latest_tag"
    echo (date '+%Y-%m-%d %H:%M:%S') "ERROR: Failed to fetch latest version" >> $LOG_FILE
    exit 1
end

set latest_version (string replace "release-" "" $latest_tag)

set last_seen (cat $STATE_FILE 2>/dev/null || echo "")

if test "$latest_version" != "$KNOWN_VERSION" -a "$latest_version" != "$last_seen"
    echo (date '+%Y-%m-%d %H:%M:%S') "NEW VERSION DETECTED: $latest_version" >> $LOG_FILE

    echo -e "phpBB update available!\n\nLatest: $latest_version\nYour known: $KNOWN_VERSION\n\nDownload: https://www.phpbb.com/downloads/\nGitHub: https://github.com/phpbb/phpbb/releases/tag/$latest_tag" \
        | mail -s "phpBB Update Available! ($latest_version)" $EMAIL_TO

    echo $latest_version > $STATE_FILE
    echo (date '+%Y-%m-%d %H:%M:%S') "NOTIFICATION SENT to $EMAIL_TO for $latest_version" >> $LOG_FILE
else
    echo (date '+%Y-%m-%d %H:%M:%S') "Up to date ($latest_version)" >> $LOG_FILE
end
