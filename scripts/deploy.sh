#!/bin/bash

# Deployment script for personal website
# Usage: ./deploy.sh [environment]

ENVIRONMENT=${1:-production}
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

echo "Deploying to $ENVIRONMENT environment..."

# Create backup before deployment
echo "Creating backup..."
cp -r websites/main/public ../backups/main_backup_$TIMESTAMP

# Add your deployment logic here
echo "Deployment logic goes here..."

# Restart web server if needed
# sudo systemctl restart nginx

echo "Deployment completed at $(date)"
