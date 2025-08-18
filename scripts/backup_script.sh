#!/bin/bash
# Enhanced backup script with security focus

BACKUP_DIR="/home/opc/ProBiz/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="probiz_backup_$DATE"

# Create backup directory if it doesn't exist
mkdir -p $BACKUP_DIR

# Create backup
echo "Starting backup at $(date)"

# Backup ProBiz directory
tar -czf "$BACKUP_DIR/${BACKUP_NAME}_probiz.tar.gz" \
    --exclude="*.log" \
    --exclude="*.tmp" \
    --exclude="node_modules" \
    /home/opc/ProBiz/

# Backup nginx configuration
tar -czf "$BACKUP_DIR/${BACKUP_NAME}_nginx.tar.gz" \
    /etc/nginx/

# Backup SSL certificates (if they exist)
if [ -d "/etc/letsencrypt" ]; then
    sudo tar -czf "$BACKUP_DIR/${BACKUP_NAME}_ssl.tar.gz" \
        /etc/letsencrypt/
    sudo chown opc:opc "$BACKUP_DIR/${BACKUP_NAME}_ssl.tar.gz"
fi

# Backup system configurations
tar -czf "$BACKUP_DIR/${BACKUP_NAME}_configs.tar.gz" \
    /etc/ssh/sshd_config \
    /etc/fail2ban/jail.local \
    /etc/firewalld/ \
    /home/opc/.ssh/

# Create backup info file
cat > "$BACKUP_DIR/${BACKUP_NAME}_info.txt" << EOF
Backup created: $(date)
System: $(cat /etc/os-release | grep PRETTY_NAME)
Nginx version: $(nginx -v 2>&1)
Disk usage: $(df -h /)
Files backed up:
- ProBiz directory
- Nginx configuration
- SSL certificates (if present)
- System configurations
EOF

# Remove backups older than 30 days
find $BACKUP_DIR -name "probiz_backup_*" -mtime +30 -delete

# Set proper permissions
chmod 600 "$BACKUP_DIR"/${BACKUP_NAME}_*

echo "Backup completed: $BACKUP_NAME"
echo "Backup location: $BACKUP_DIR"

# Optional: Send backup to remote location
# rsync -av "$BACKUP_DIR/${BACKUP_NAME}_*" user@remote-server:/backups/