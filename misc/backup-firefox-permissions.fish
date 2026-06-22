#!/usr/bin/env fish

# Firefox permissions.sqlite backup + sync to Developer Edition (macOS + Fish)
# Run via cron @reboot or launchd

function backup-firefox

    set BACKUP_DIR "$HOME/backups/firefox/permissions"
    set TIMESTAMP (date +"%Y-%m-%d_%H-%M-%S")
    set BackupsToKeep 30

    # Create backup directory
    mkdir -p $BACKUP_DIR

    # Check if either Firefox or Firefox Developer Edition is running
    if pgrep -f "/Applications/Firefox.app" > /dev/null
        echo "[$TIMESTAMP] Regular Firefox is running — skipping backup."
        exit 0
    end

    if pgrep -f "Firefox Developer Edition" > /dev/null
        echo "[$TIMESTAMP] Firefox Developer Edition is running — skipping backup."
        exit 0
    end

    echo "[$TIMESTAMP] Both Firefox versions not running — starting backup & sync..."

    # === profiles.ini (shared) ===
    set PROFILES_INI "$HOME/Library/Application Support/Firefox/profiles.ini"

    if not test -f $PROFILES_INI
        echo "[$TIMESTAMP] Error: profiles.ini not found!"
        osascript -e 'display notification "Firefox backup failed: profiles.ini not found!" with title "Firefox Backup Error"' 2>/dev/null
        exit 1
    end

    # Select Profile0 (default-release) for regular Firefox backup
    set REG_PROFILE_PATH (grep -A 10 "\[Profile0\]" $PROFILES_INI | grep "Path=" | head -n1 | cut -d= -f2)
    set REG_FULL_PROFILE_PATH "$HOME/Library/Application Support/Firefox/$REG_PROFILE_PATH"

    if not test -d "$REG_FULL_PROFILE_PATH"
        echo "[$TIMESTAMP] Error: Regular Firefox Profile0 not found!"
        osascript -e 'display notification "Firefox backup failed: Profile0 not found!" with title "Firefox Backup Error"' 2>/dev/null
        exit 1
    end

    # Backup regular Firefox (Profile0)
    set FILES_TO_BACKUP "permissions.sqlite" "permissions.sqlite-wal" "permissions.sqlite-shm"
    set backed_up 0

    for file in $FILES_TO_BACKUP
        if test -f "$REG_FULL_PROFILE_PATH/$file"
            cp "$REG_FULL_PROFILE_PATH/$file" "$BACKUP_DIR/$file.$TIMESTAMP"
            cp "$REG_FULL_PROFILE_PATH/$file" "$BACKUP_DIR/$file.latest"
            echo "[$TIMESTAMP] Backed up: $file"
            set backed_up (math $backed_up + 1)
        end
    end

    # Rotation: Keep only the last 30 backups per file type
    for file in $FILES_TO_BACKUP
        set pattern "$BACKUP_DIR/$file.*"
        set backups (ls -1t $pattern 2>/dev/null)
        if test (count $backups) -gt $BackupsToKeep
            echo "[$TIMESTAMP] Cleaning up old backups for $file"
            for oldfile in $backups[(math $BackupsToKeep + 1)..-1]
                rm -f $oldfile
            end
        end
    end

    # === Sync to Developer Edition profile (dev-edition-default) ===
    set DEV_PROFILE_PATH (grep -A 10 "Name=dev-edition-default" $PROFILES_INI | grep "Path=" | head -n1 | cut -d= -f2)
    set DEV_FULL_PROFILE_PATH "$HOME/Library/Application Support/Firefox/$DEV_PROFILE_PATH"

    if test -d "$DEV_FULL_PROFILE_PATH"
        echo "[$TIMESTAMP] Syncing latest permissions to Firefox Developer Edition..."
        for file in $FILES_TO_BACKUP
            if test -f "$BACKUP_DIR/$file.latest"
                cp "$BACKUP_DIR/$file.latest" "$DEV_FULL_PROFILE_PATH/$file"
                echo "[$TIMESTAMP] Synced to Dev Edition: $file"
            end
        end
    else
        echo "[$TIMESTAMP] Warning: Developer Edition profile not found (skipping sync)."
    end

    # Success notification
    echo "[$TIMESTAMP] Backup & sync completed successfully. $backed_up file(s) processed."
    osascript -e "display notification \"Firefox backup & Dev Edition sync completed ($backed_up file(s)).\" with title \"Firefox Backup Success\"" 2>/dev/null

end

# Run the function
backup-firefox 2>&1 | tee -a ~/log/(status basename | awk -F. '{print $1}').log
