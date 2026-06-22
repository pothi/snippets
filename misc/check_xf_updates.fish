#!/usr/bin/env fish

# Gemini: https://gemini.google.com/share/875279082ab0

# Configuration
set FEED_URL "https://xenforo.com/community/forums/announcements/index.rss"
set CACHE_FILE "$HOME/.cache/xf_last_announcement.txt"
set ENV_FILE ~/.env

# 1. Dependency Check: Ensure xmlstarlet is installed
if not type -q xmlstarlet
    echo "Error: 'xmlstarlet' is not installed." >&2
    echo "Please install it before running this script:" >&2
    echo "  macOS:  brew install xmlstarlet" >&2
    echo "  Ubuntu/Debian: sudo apt install xmlstarlet" >&2
    echo "  CentOS/RHEL:   sudo dnf install xmlstarlet" >&2
    exit 1
end

# 2. Email Resolution Logic
set NOTIFY_EMAIL ""

# Strategy A: Check command-line argument ($argv[1])
if test (count $argv) -ge 1
    set NOTIFY_EMAIL $argv[1]
end

# Strategy B: If no argument, source .env file if it exists
if test -z "$NOTIFY_EMAIL"; and test -f $ENV_FILE
    # Read the file line by line to extract NOTIFY_EMAIL without breaking Fish syntax
    while read -l line
        if string match -r -q '^NOTIFY_EMAIL=' -- $line
            set NOTIFY_EMAIL (string replace -r '^NOTIFY_EMAIL=\s*["\']?(.*?)["\']?\s*$' '$1' -- $line)
            break
        end
    end < $ENV_FILE
end

# Strategy C: Fallback to existing ENVIRONMENT variable
if test -z "$NOTIFY_EMAIL"; and set -q NOTIFY_EMAIL
    set NOTIFY_EMAIL $NOTIFY_EMAIL
end

# 3. Core Processing
# Ensure cache directory exists
mkdir -p (dirname $CACHE_FILE)

# Fetch and parse the RSS feed safely
set NEWEST_LINK (curl -s -A "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)" $FEED_URL | xmlstarlet sel -t -v "//channel/item[1]/link" 2>/dev/null)

if test -z "$NEWEST_LINK"
    echo "Error: Failed to fetch or parse the XenForo RSS feed." >&2
    exit 1
end

# Check if this is the first run
if not test -f $CACHE_FILE
    echo "Initial setup: Saving current announcement link ($NEWEST_LINK)."
    echo $NEWEST_LINK > $CACHE_FILE
    exit 0
end

# Read the last saved link
set LAST_LINK (cat $CACHE_FILE)

# Compare links to determine if an update dropped
if test "$NEWEST_LINK" != "$LAST_LINK"
    echo "New XenForo Announcement detected: $NEWEST_LINK"

    # === NOTIFICATION EXECUTION ===

    # Local macOS Desktop Notification (Triggered regardless of email settings if on macOS)
    if test (uname) = "Darwin"
        # Safely pass the URL using AppleScript's native quote handling
        osascript -e "display notification \"New XenForo update available!\" with title \"XenForo Monitor\"" \
                  -e "open location \"$NEWEST_LINK\""
    end

    # Email Notification (Triggered only if an email address was found)
    if test -n "$NOTIFY_EMAIL"
        echo "A new XenForo software update or announcement has been posted: $NEWEST_LINK" | mail -s "XenForo Update Alert" $NOTIFY_EMAIL
        echo "Notification email sent to $NOTIFY_EMAIL."
    else
        echo "Warning: New update found, but no notification email address was supplied via argument, environment, or ~/.env file." >&2
    end

    # Update the cache file
    echo $NEWEST_LINK > $CACHE_FILE
else
    echo "No new XenForo updates found."
end
