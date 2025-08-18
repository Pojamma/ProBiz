#!/bin/bash

# Backup script for Oracle server projects
BACKUP_DIR="../backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_NAME="full_backup_$TIMESTAMP.tar.gz"

echo "Creating backup: $BACKUP_NAME"

# Create compressed backup
tar -czf "$BACKUP_DIR/$BACKUP_NAME" \
    --exclude="logs/*" \
    --exclude="node_modules" \
    --exclude=".git" \
    websites/ nodejs/ shared/ scripts/ docs/

echo "Backup created: $BACKUP_DIR/$BACKUP_NAME"

# Keep only last 10 backups
cd "$BACKUP_DIR"
ls -t full_backup_*.tar.gz | tail -n +11 | xargs -r rm --

echo "Backup completed at $(date)"
