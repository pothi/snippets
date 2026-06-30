#!/usr/bin/env fish

set VERSION "1.3.0"

function show_usage
    echo "FUTO Notes Backup Script v$VERSION"
    echo "Usage: "(status filename)" <instance_dir> [options]"
    echo ""
    echo "Options:"
    echo "  -b, --bucket BUCKET       AWS S3 bucket for offsite backup"
    echo "  -p, --profile PROFILE     AWS profile (default: default)"
    echo "      --passphrase PASS     Passphrase for GPG encryption"
    echo "  -v, --version             Show version"
    echo "  -h, --help                Show this help"
end

# Argument parsing using argparse
argparse 'b/bucket=' 'p/profile=' 'passphrase=' 'v/version' 'h/help' -- $argv
or exit 1

if set -q _flag_version
    echo "v$VERSION"
    exit 0
end

if set -q _flag_help
    show_usage
    exit 0
end

set INSTANCE_DIR $argv[1]

if test -z "$INSTANCE_DIR"
    echo "Error: Instance directory is required."
    show_usage
    exit 1
end

set S3_BUCKET $_flag_bucket
set AWS_PROFILE (test -n "$_flag_profile"; and echo $_flag_profile; or echo "default")
set PASSPHRASE $_flag_passphrase

set START_TIME (date +%s)

# Validation
if not test -d "$INSTANCE_DIR"
    echo "Error: Directory does not exist: $INSTANCE_DIR" | tee -a ~/log/futo-notes-backup-(date +%Y%m%d).log
    exit 1
end

# Directories
set BACKUP_BASE ~/backups
mkdir -p $BACKUP_BASE/{nightly,weekly,monthly} ~/log

set TODAY (date +%Y-%m-%d)
set DAY_OF_WEEK (date +%u)
set DAY_OF_MONTH (date +%d)

if test "$DAY_OF_MONTH" = "01"
    set BACKUP_DIR $BACKUP_BASE/monthly
else if test "$DAY_OF_WEEK" = "1"
    set BACKUP_DIR $BACKUP_BASE/weekly
else
    set BACKUP_DIR $BACKUP_BASE/nightly
end

set BACKUP_FILE "$BACKUP_DIR/futo-notes-$TODAY.tar.gz"
set LOG_FILE ~/log/futo-notes-backup-(date +%Y%m%d).log

echo "=== FUTO Notes Backup v$VERSION started at "(date)" ===" | tee -a $LOG_FILE

# Stop containers
echo "Stopping containers..." | tee -a $LOG_FILE
docker compose -f "$INSTANCE_DIR/docker-compose.yml" down 2>&1 | tee -a $LOG_FILE

# DB Dump
echo "Taking PostgreSQL dump..." | tee -a $LOG_FILE
docker compose -f "$INSTANCE_DIR/docker-compose.yml" exec -T postgres \
    pg_dump -U futo_notes -d futo_notes > "$INSTANCE_DIR/backup.sql" 2>&1 | tee -a $LOG_FILE

# Tar backup (exclude raw postgres dir)
# Create structured backup with proper exclude
set INSTANCE_NAME (basename $INSTANCE_DIR)

echo "Creating structured backup with top-level folder: $INSTANCE_NAME/" | tee -a $LOG_FILE

# Correct tar command
tar -czf "$BACKUP_FILE" \
    --exclude="futo-notes-data/postgres" \
    --transform "s|^$INSTANCE_NAME/|$INSTANCE_NAME/|" \
    -C (dirname $INSTANCE_DIR) "$INSTANCE_NAME" \
    2>&1 | tee -a $LOG_FILE

set BACKUP_STATUS $status

rm -f "$INSTANCE_DIR/backup.sql"

# Encrypt
if test -n "$PASSPHRASE"
    echo "Encrypting backup..." | tee -a $LOG_FILE
    gpg --batch --yes --passphrase "$PASSPHRASE" --cipher-algo AES256 -c "$BACKUP_FILE" 2>&1 | tee -a $LOG_FILE
    and rm "$BACKUP_FILE"
    set BACKUP_FILE "$BACKUP_FILE.gpg"
end

# S3 Upload
if test -n "$S3_BUCKET"
    echo "Uploading to S3 ($S3_BUCKET) using profile '$AWS_PROFILE'..." | tee -a $LOG_FILE
    aws --profile $AWS_PROFILE s3 cp "$BACKUP_FILE" "s3://$S3_BUCKET/futo-notes-$TODAY.tar.gz"(test -n "$PASSPHRASE"; and echo ".gpg") 2>&1 | tee -a $LOG_FILE
end

# Restart
echo "Restarting containers..." | tee -a $LOG_FILE
docker compose -f "$INSTANCE_DIR/docker-compose.yml" up -d 2>&1 | tee -a $LOG_FILE

set END_TIME (date +%s)
set DURATION (math $END_TIME - $START_TIME)

echo "=== Backup completed in $DURATION seconds ===" | tee -a $LOG_FILE
echo "Backup: $BACKUP_FILE" | tee -a $LOG_FILE

if test $BACKUP_STATUS -ne 0
    echo "WARNING: Backup had errors. Check log." | tee -a $LOG_FILE
    echo "FUTO Notes Backup Warning" | cat - $LOG_FILE | mail -s "FUTO Notes Backup Warning" root
end
