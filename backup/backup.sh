#!/bin/bash
set -euo pipefail

# The directory where we will save the archive
BACKUP_DIR="$HOME/devops/backup"

if [ ! -d "$BACKUP_DIR" ]; then
    mkdir -p "$BACKUP_DIR"
fi

# The name of the file with the date
DATE=$(date +'%Y-%m-%d_%H-%M')

# Which directories we backup
TARGETS=(/etc/nginx /etc/ssh /etc/fail2ban)

set +e

# Create the archive
if tar -czvf "$BACKUP_DIR/configs_backup_$DATE.tar.gz" "${TARGETS[@]}"; then
    echo "$DATE: [SUCCESS] Backup created successfully at $BACKUP_DIR/configs_backup_$DATE.tar.gz" >> "$BACKUP_DIR/backup.log"
else
    echo "$DATE: [FAILED] Backup failed!" >> "$BACKUP_DIR/backup.log"
    exit 1
fi

set -e

# Remove backups older than 7 days
find "$BACKUP_DIR" -type f -name "*.tar.gz" -mtime +7 -delete
