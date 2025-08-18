#!/bin/bash
# This script helps organize files uploaded from Termux

SOURCE_DIR="/home/opc/uploads"  # Temporary upload directory
DEST_BASE="/home/opc/ProBiz"

# Create upload staging area
mkdir -p "$SOURCE_DIR"

# Function to move files to appropriate locations
organize_uploads() {
    echo "Organizing uploaded files..."
    
    # Move web files
    if [ -d "$SOURCE_DIR/web" ]; then
        cp -r "$SOURCE_DIR/web/"* "$DEST_BASE/websites/"
        rm -rf "$SOURCE_DIR/web"
    fi
    
    # Move Node.js files
    if [ -d "$SOURCE_DIR/nodejs" ]; then
        cp -r "$SOURCE_DIR/nodejs/"* "$DEST_BASE/nodejs/"
        rm -rf "$SOURCE_DIR/nodejs"
    fi
    
    # Fix permissions
    chgrp -R webdev "$DEST_BASE"
    find "$DEST_BASE" -type f -exec chmod 664 {} \;
    find "$DEST_BASE" -type d -exec chmod 775 {} \;
    
    echo "✅ Files organized and permissions set!"
}

organize_uploads
