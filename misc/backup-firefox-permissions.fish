#!/usr/bin/env fish

# Firefox permissions.sqlite backup script (macOS + Fish)
# Run via cron @reboot

function backup-firefox

    set BACKUP_DIR "$HOME/Documents/firefox/permissions"
    set TIMESTAMP (date +"%Y-%m-%d_%H-%M-%S")
    set BackupsToKeep 30

    # Create backup directory
    mkdir -p $BACKUP_DIR

    # Check if Firefox is running
    if pgrep -f "/Applications/Firefox.app" > /dev/null
        echo "[$TIMESTAMP] Firefox is running — skipping backup to avoid corruption."
        exit 0
    end

    echo "[$TIMESTAMP] Firefox not running — starting backup..."

    # Find the default Firefox profile
    set PROFILES_INI "$HOME/Library/Application Support/Firefox/profiles.ini"

    if not test -f $PROFILES_INI
        echo "[$TIMESTAMP] Error: profiles.ini not found!"
        osascript -e 'display notification "Firefox backup failed: profiles.ini not found!" with title "Firefox Backup Error"' 2>/dev/null
        exit 1
    end

    # Get the default profile path
    set PROFILE_PATH (grep -A 10 "\[Profile0\]" $PROFILES_INI | grep "Path=" | head -n1 | cut -d= -f2)
    set FULL_PROFILE_PATH "$HOME/Library/Application Support/Firefox/$PROFILE_PATH"

    if not test -d "$FULL_PROFILE_PATH"
        echo "[$TIMESTAMP] Error: Profile directory not found at $FULL_PROFILE_PATH"
        osascript -e 'display notification "Firefox backup failed: Profile directory not found!" with title "Firefox Backup Error"' 2>/dev/null
        exit 1
    end

    # Backup the key files
    set FILES_TO_BACKUP "permissions.sqlite" "permissions.sqlite-wal" "permissions.sqlite-shm"
    set backed_up 0

    for file in $FILES_TO_BACKUP
        if test -f "$FULL_PROFILE_PATH/$file"
            cp "$FULL_PROFILE_PATH/$file" "$BACKUP_DIR/$file.$TIMESTAMP"
            cp "$FULL_PROFILE_PATH/$file" "$BACKUP_DIR/$file.latest"
            echo "[$TIMESTAMP] Backed up: $file"
            set backed_up (math $backed_up + 1)
        end
    end

    # Rotation: Keep only the last 30 backups per file type
    for file in $FILES_TO_BACKUP
        set pattern "$BACKUP_DIR/$file.*"
        set backups (ls -1t $pattern 2>/dev/null)

        if test (count $backups) -gt $BackupsToKeep
            echo "[$TIMESTAMP] Cleaning up old backups for $file (keeping last $BackupsToKeep)"
            for oldfile in $backups[(math $BackupsToKeep + 1)..-1]
                rm -f $oldfile
            end
        end
    end

    # Summary + Success notification
    echo "[$TIMESTAMP] Backup completed successfully. $backed_up file(s) backed up."
    osascript -e "display notification \"Firefox backup completed successfully ($backed_up file(s)).\" with title \"Firefox Backup Success\"" 2>/dev/null

end

# Run the function
backup-firefox 2>&1 | tee -a ~/log/(status basename | awk -F. '{print $1}').log
