#!/bin/bash

# ProBiz File Sync Script for Termux
# Manages file transfers between Android Termux and Oracle Linux Server

# Configuration
SSH_HOST="oracle-instance-probiz"
LOCAL_DIR="/data/data/com.termux/files/home/storage/shared/myApps/ProBiz"
REMOTE_DIR="/home/opc/ProBiz"
BACKUP_DIR="/data/data/com.termux/files/home/storage/shared/myApps/ProBiz_backups"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_color() {
    printf "${1}${2}${NC}\n"
}

# Function to print header
print_header() {
    clear
    print_color $CYAN "================================================"
    print_color $CYAN "         ProBiz File Management Tool"
    print_color $CYAN "   Termux ↔ Oracle Linux Server Sync"
    print_color $CYAN "================================================"
    echo
}

# Function to check if directories exist
check_directories() {
    # Create local directory if it doesn't exist
    if [ ! -d "$LOCAL_DIR" ]; then
        print_color $YELLOW "Creating local directory: $LOCAL_DIR"
        mkdir -p "$LOCAL_DIR"
    fi
    
    # Create backup directory if it doesn't exist
    if [ ! -d "$BACKUP_DIR" ]; then
        mkdir -p "$BACKUP_DIR"
    fi
}

# Function to test SSH connection
test_connection() {
    print_color $BLUE "Testing SSH connection to Oracle server..."
    if ssh -o ConnectTimeout=5 "$SSH_HOST" "echo 'Connection successful'" 2>/dev/null; then
        print_color $GREEN "✓ SSH connection successful"
        return 0
    else
        print_color $RED "✗ SSH connection failed"
        print_color $YELLOW "Please check your internet connection and SSH configuration"
        return 1
    fi
}

# Function to create remote directory if needed
ensure_remote_dir() {
    print_color $BLUE "Ensuring remote directory exists..."
    ssh "$SSH_HOST" "mkdir -p $REMOTE_DIR" 2>/dev/null
    if [ $? -eq 0 ]; then
        print_color $GREEN "✓ Remote directory ready"
    else
        print_color $RED "✗ Failed to create remote directory"
    fi
}

# Function to upload files to server
upload_files() {
    print_header
    print_color $GREEN "📤 UPLOADING FILES TO ORACLE SERVER"
    echo
    
    if ! test_connection; then
        return 1
    fi
    
    ensure_remote_dir
    
    echo
    print_color $BLUE "Uploading from: $LOCAL_DIR"
    print_color $BLUE "Uploading to: $SSH_HOST:$REMOTE_DIR"
    echo
    
    # Use rsync for efficient transfer with progress
    rsync -avz --progress --human-readable \
          "$LOCAL_DIR/" \
          "$SSH_HOST:$REMOTE_DIR/"
    
    if [ $? -eq 0 ]; then
        print_color $GREEN "✓ Upload completed successfully!"
    else
        print_color $RED "✗ Upload failed!"
    fi
}

# Function to download files from server
download_files() {
    print_header
    print_color $GREEN "📥 DOWNLOADING FILES FROM ORACLE SERVER"
    echo
    
    if ! test_connection; then
        return 1
    fi
    
    echo
    print_color $BLUE "Downloading from: $SSH_HOST:$REMOTE_DIR"
    print_color $BLUE "Downloading to: $LOCAL_DIR"
    echo
    
    # Use rsync for efficient transfer with progress
    rsync -avz --progress --human-readable \
          "$SSH_HOST:$REMOTE_DIR/" \
          "$LOCAL_DIR/"
    
    if [ $? -eq 0 ]; then
        print_color $GREEN "✓ Download completed successfully!"
    else
        print_color $RED "✗ Download failed!"
    fi
}

# Function to sync directories (bidirectional)
sync_directories() {
    print_header
    print_color $GREEN "🔄 SYNCING DIRECTORIES"
    echo
    
    if ! test_connection; then
        return 1
    fi
    
    ensure_remote_dir
    
    print_color $YELLOW "This will sync files in both directions."
    print_color $YELLOW "Newer files will overwrite older ones."
    echo
    read -p "Continue? (y/N): " confirm
    
    if [[ $confirm =~ ^[Yy]$ ]]; then
        echo
        print_color $BLUE "Syncing directories..."
        
        # First sync: local to remote (upload newer local files)
        print_color $CYAN "Step 1: Uploading newer local files..."
        rsync -avz --update --progress --human-readable \
              "$LOCAL_DIR/" \
              "$SSH_HOST:$REMOTE_DIR/"
        
        # Second sync: remote to local (download newer remote files)
        print_color $CYAN "Step 2: Downloading newer remote files..."
        rsync -avz --update --progress --human-readable \
              "$SSH_HOST:$REMOTE_DIR/" \
              "$LOCAL_DIR/"
        
        if [ $? -eq 0 ]; then
            print_color $GREEN "✓ Sync completed successfully!"
        else
            print_color $RED "✗ Sync failed!"
        fi
    else
        print_color $YELLOW "Sync cancelled."
    fi
}

# Function to view local directory contents
view_local_files() {
    print_header
    print_color $GREEN "📁 LOCAL DIRECTORY CONTENTS"
    echo
    print_color $BLUE "Directory: $LOCAL_DIR"
    echo
    
    if [ -d "$LOCAL_DIR" ] && [ "$(ls -A $LOCAL_DIR 2>/dev/null)" ]; then
        ls -la "$LOCAL_DIR"
        echo
        # Show disk usage
        print_color $CYAN "Disk usage:"
        du -sh "$LOCAL_DIR"
    else
        print_color $YELLOW "Directory is empty or doesn't exist."
    fi
}

# Function to view remote directory contents
view_remote_files() {
    print_header
    print_color $GREEN "📁 REMOTE DIRECTORY CONTENTS"
    echo
    
    if ! test_connection; then
        return 1
    fi
    
    print_color $BLUE "Directory: $SSH_HOST:$REMOTE_DIR"
    echo
    
    ssh "$SSH_HOST" "
        if [ -d '$REMOTE_DIR' ] && [ \"\$(ls -A $REMOTE_DIR 2>/dev/null)\" ]; then
            ls -la '$REMOTE_DIR'
            echo
            echo 'Disk usage:'
            du -sh '$REMOTE_DIR'
        else
            echo 'Directory is empty or doesn'\''t exist.'
        fi
    "
}

# Function to create backup
create_backup() {
    print_header
    print_color $GREEN "💾 CREATING LOCAL BACKUP"
    echo
    
    if [ ! -d "$LOCAL_DIR" ] || [ ! "$(ls -A $LOCAL_DIR 2>/dev/null)" ]; then
        print_color $YELLOW "No local files to backup."
        return 1
    fi
    
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    BACKUP_PATH="$BACKUP_DIR/backup_$TIMESTAMP"
    
    print_color $BLUE "Creating backup: $BACKUP_PATH"
    
    cp -r "$LOCAL_DIR" "$BACKUP_PATH"
    
    if [ $? -eq 0 ]; then
        print_color $GREEN "✓ Backup created successfully!"
        print_color $CYAN "Backup location: $BACKUP_PATH"
    else
        print_color $RED "✗ Backup failed!"
    fi
}

# Function to restore from backup
restore_backup() {
    print_header
    print_color $GREEN "📦 RESTORE FROM BACKUP"
    echo
    
    if [ ! -d "$BACKUP_DIR" ] || [ ! "$(ls -A $BACKUP_DIR 2>/dev/null)" ]; then
        print_color $YELLOW "No backups found."
        return 1
    fi
    
    print_color $BLUE "Available backups:"
    echo
    ls -1t "$BACKUP_DIR" | head -10
    echo
    
    read -p "Enter backup name to restore (or 'q' to quit): " backup_name
    
    if [ "$backup_name" = "q" ]; then
        return 0
    fi
    
    BACKUP_PATH="$BACKUP_DIR/$backup_name"
    
    if [ ! -d "$BACKUP_PATH" ]; then
        print_color $RED "Backup not found: $backup_name"
        return 1
    fi
    
    print_color $YELLOW "This will overwrite current local files."
    read -p "Continue? (y/N): " confirm
    
    if [[ $confirm =~ ^[Yy]$ ]]; then
        rm -rf "$LOCAL_DIR"
        cp -r "$BACKUP_PATH" "$LOCAL_DIR"
        
        if [ $? -eq 0 ]; then
            print_color $GREEN "✓ Restore completed successfully!"
        else
            print_color $RED "✗ Restore failed!"
        fi
    else
        print_color $YELLOW "Restore cancelled."
    fi
}

# Function to check system info
system_info() {
    print_header
    print_color $GREEN "🔧 SYSTEM INFORMATION"
    echo
    
    print_color $CYAN "Local System (Termux):"
    echo "Date: $(date)"
    echo "Storage space:"
    df -h "$LOCAL_DIR" 2>/dev/null | tail -1
    echo
    
    if test_connection; then
        print_color $CYAN "Remote System (Oracle Server):"
        ssh "$SSH_HOST" "
            echo 'Date: \$(date)'
            echo 'System: \$(cat /etc/os-release | grep PRETTY_NAME | cut -d'\"' -f2)'
            echo 'Uptime: \$(uptime | cut -d',' -f1 | cut -d' ' -f4-)'
            echo 'Storage space:'
            df -h '$REMOTE_DIR' 2>/dev/null | tail -1
        "
    fi
}

# Function to show help
show_help() {
    print_header
    print_color $GREEN "📖 HELP & USAGE"
    echo
    print_color $CYAN "This script helps you manage files between:"
    echo "  • Local (Termux):  $LOCAL_DIR"
    echo "  • Remote (Oracle): $SSH_HOST:$REMOTE_DIR"
    echo
    print_color $CYAN "Available Options:"
    echo "  1. Upload    - Copy files from Termux to Oracle server"
    echo "  2. Download  - Copy files from Oracle server to Termux"
    echo "  3. Sync      - Sync both directories (newer files win)"
    echo "  4. View Local - Show local directory contents"
    echo "  5. View Remote - Show remote directory contents"
    echo "  6. Backup    - Create local backup"
    echo "  7. Restore   - Restore from backup"
    echo "  8. System Info - Show system information"
    echo "  9. Help      - Show this help"
    echo "  0. Exit      - Quit the script"
    echo
    print_color $YELLOW "Tips:"
    echo "  • Make sure you have internet connection"
    echo "  • SSH key should be properly configured"
    echo "  • Use 'Sync' for regular development workflow"
    echo "  • Create backups before major changes"
}

# Main menu function
show_menu() {
    echo
    print_color $PURPLE "═══════════════════════════════════════════════"
    print_color $YELLOW "  What would you like to do?"
    print_color $PURPLE "═══════════════════════════════════════════════"
    echo "  1) 📤 Upload files to server"
    echo "  2) 📥 Download files from server"
    echo "  3) 🔄 Sync directories"
    echo "  4) 📁 View local files"
    echo "  5) 🌐 View remote files"
    echo "  6) 💾 Create backup"
    echo "  7) 📦 Restore backup"
    echo "  8) 🔧 System info"
    echo "  9) 📖 Help"
    echo "  0) 🚪 Exit"
    print_color $PURPLE "═══════════════════════════════════════════════"
    echo
}

# Main function
main() {
    # Check and create directories
    check_directories
    
    # Main loop
    while true; do
        print_header
        show_menu
        
        read -p "Enter your choice (0-9): " choice
        
        case $choice in
            1) upload_files ;;
            2) download_files ;;
            3) sync_directories ;;
            4) view_local_files ;;
            5) view_remote_files ;;
            6) create_backup ;;
            7) restore_backup ;;
            8) system_info ;;
            9) show_help ;;
            0) 
                print_color $GREEN "👋 Goodbye! Happy coding!"
                exit 0
                ;;
            *)
                print_color $RED "Invalid choice. Please enter 0-9."
                ;;
        esac
        
        echo
        read -p "Press Enter to continue..."
    done
}

# Run the script
main