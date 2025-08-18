#!/bin/bash

# File copy script: Google Pixel Tablet -> Termux -> Oracle Server
# Based on copyfile2nb.sh structure with rsync integration
# Usage: ./copy_to_oracle.sh [filename] [subdirectory] [oracle_host] [log_file]

# Define base directories (matching copyfile2nb.sh)
TERMUX_HOME="/data/data/com.termux/files/home"
APP_DIR="$TERMUX_HOME/NewBiz"
STORAGE_DIR="$TERMUX_HOME/storage/shared/myApps/NewBiz"
ORACLE_PATH="/home/opc/NewBiz"

# Default Oracle server settings
DEFAULT_ORACLE_HOST="oracle-instance"

# Rsync options
RSYNC_OPTS="-avh --progress"

# Initialize session variables
LAST_DIRECTORY=""
SESSION_COUNT=0

# Function to display usage
usage() {
    echo "Usage: $0 [filename] [subdirectory] [oracle_host] [log_file]"
    echo ""
    echo "Parameters (all optional for interactive mode):"
    echo "  filename        - Name of the file to copy (prompts if not provided)"
    echo "  subdirectory    - Subdirectory within NewBiz (prompts if not provided)"
    echo "  oracle_host     - Oracle server SSH config alias (default: $DEFAULT_ORACLE_HOST)"
    echo "  log_file        - Optional log file path for rsync output"
    echo ""
    echo "Examples:"
    echo "  $0                           # Interactive mode"
    echo "  $0 myfile.txt               # Copy specific file from root"
    echo "  $0 document.pdf src         # Copy from src subdirectory"
    echo "  $0 data.json src oracle-instance /tmp/copy.log"
    echo ""
    echo "Interactive mode allows browsing and selecting files like copyfile2nb.sh"
    exit 1
}

# Function to list directory contents
list_contents() {
    local dir_path="$1"
    local context="$2"
    
    if [ -d "$dir_path" ]; then
        echo ""
        echo "Contents of $context:"
        echo "======================================"
        ls -la "$dir_path" 2>/dev/null | grep -E "^[d-]" | while read -r line; do
            # Extract filename and show file/directory indicator
            filename=$(echo "$line" | awk '{print $NF}')
            if [[ "$line" =~ ^d ]]; then
                echo "📁 $filename/"
            else
                size=$(echo "$line" | awk '{print $5}')
                echo "📄 $filename ($size bytes)"
            fi
        done
        echo "======================================"
    else
        echo "Directory '$dir_path' does not exist."
    fi
}

# Function to copy item from storage to app directory (like copyfile2nb.sh)
copy_to_app() {
    local item_name="$1"
    local current_dir="$2"
    
    # Remove leading/trailing whitespace and forward slashes
    item_name=$(echo "$item_name" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//;s/^\/\+//;s/\/\+$//')
    
    # Check if input is empty
    if [ -z "$item_name" ]; then
        echo "Error: No file or directory name provided."
        return 1
    fi
    
    # Construct full paths
    if [ -n "$current_dir" ]; then
        SOURCE_PATH="$STORAGE_DIR/$current_dir/$item_name"
        DEST_PATH="$APP_DIR/$current_dir/$item_name"
    else
        SOURCE_PATH="$STORAGE_DIR/$item_name"
        DEST_PATH="$APP_DIR/$item_name"
    fi
    
    echo ""
    echo "Step 1/2: Copying from storage to app directory..."
    echo "Source: $SOURCE_PATH"
    echo "Destination: $DEST_PATH"
    
    # Check if source exists
    if [ ! -e "$SOURCE_PATH" ]; then
        echo "Error: Source '$SOURCE_PATH' does not exist."
        if [ -n "$current_dir" ]; then
            list_contents "$STORAGE_DIR/$current_dir" "$STORAGE_DIR/$current_dir"
        else
            list_contents "$STORAGE_DIR" "$STORAGE_DIR"
        fi
        return 1
    fi
    
    # Create destination directory if needed
    dest_dir=$(dirname "$DEST_PATH")
    mkdir -p "$dest_dir"
    
    # Copy the item
    if [ -f "$SOURCE_PATH" ]; then
        cp "$SOURCE_PATH" "$DEST_PATH"
    elif [ -d "$SOURCE_PATH" ]; then
        mkdir -p "$DEST_PATH"
        cp -rf "$SOURCE_PATH/." "$DEST_PATH/"
    else
        echo "Error: '$SOURCE_PATH' is neither a regular file nor a directory."
        return 1
    fi
    
    if [ $? -eq 0 ]; then
        echo "✓ Successfully copied to app directory"
        return 0
    else
        echo "✗ Error copying to app directory"
        return 1
    fi
}

# Function to copy from app directory to Oracle server
copy_to_oracle() {
    local item_name="$1"
    local current_dir="$2"
    local oracle_host="$3"
    local log_file="$4"
    
    # Construct paths
    if [ -n "$current_dir" ]; then
        SOURCE_PATH="$APP_DIR/$current_dir/$item_name"
        ORACLE_FILE="$ORACLE_PATH/$current_dir/$item_name"
    else
        SOURCE_PATH="$APP_DIR/$item_name"
        ORACLE_FILE="$ORACLE_PATH/$item_name"
    fi
    
    echo ""
    echo "Step 2/2: Copying from app directory to Oracle server..."
    echo "Source: $SOURCE_PATH"
    echo "Oracle: $oracle_host:$ORACLE_FILE"
    
    # Test SSH connection
    echo "Testing connection to $oracle_host..."
    ssh -o ConnectTimeout=5 -o BatchMode=yes "$oracle_host" "echo 'Connection successful'" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "✓ Oracle server is reachable"
    else
        echo "Warning: Cannot connect to Oracle server. Check your SSH config."
        echo "Make sure '$oracle_host' is defined in ~/.ssh/config"
    fi
    
    # Create remote directory structure
    if [ -n "$current_dir" ]; then
        remote_dir="$ORACLE_PATH/$current_dir"
    else
        remote_dir="$ORACLE_PATH"
    fi
    
    echo "Ensuring remote directory exists: $remote_dir"
    ssh "$oracle_host" "mkdir -p '$remote_dir'" 2>/dev/null
    
    # Use rsync to copy
    echo "Using rsync to transfer..."
    if [ -n "$log_file" ]; then
        echo "Logging rsync output to: $log_file"
        mkdir -p "$(dirname "$log_file")" 2>/dev/null
        
        if [ -d "$SOURCE_PATH" ]; then
            # For directories, sync contents
            rsync $RSYNC_OPTS "$SOURCE_PATH/" "$oracle_host:$ORACLE_FILE/" >> "$log_file" 2>&1
        else
            # For files
            rsync $RSYNC_OPTS "$SOURCE_PATH" "$oracle_host:$ORACLE_FILE" >> "$log_file" 2>&1
        fi
    else
        if [ -d "$SOURCE_PATH" ]; then
            rsync $RSYNC_OPTS "$SOURCE_PATH/" "$oracle_host:$ORACLE_FILE/"
        else
            rsync $RSYNC_OPTS "$SOURCE_PATH" "$oracle_host:$ORACLE_FILE"
        fi
    fi
    
    rsync_exit_code=$?
    
    if [ $rsync_exit_code -eq 0 ]; then
        echo "✓ Successfully copied to Oracle server"
        
        # Verify the transfer
        if [ -f "$SOURCE_PATH" ]; then
            LOCAL_SIZE=$(ls -l "$SOURCE_PATH" | awk '{print $5}')
            REMOTE_SIZE=$(ssh "$oracle_host" "ls -l '$ORACLE_FILE' 2>/dev/null | awk '{print \$5}'")
            
            if [ "$REMOTE_SIZE" = "$LOCAL_SIZE" ]; then
                echo "✓ File verification successful (size: $LOCAL_SIZE bytes)"
            else
                echo "Warning: File size mismatch (local: $LOCAL_SIZE, remote: $REMOTE_SIZE)"
            fi
        else
            echo "✓ Directory transfer completed"
        fi
        
        return 0
    else
        echo "✗ Error: Rsync failed with exit code $rsync_exit_code"
        if [ -n "$log_file" ] && [ -f "$log_file" ]; then
            echo "Last few lines of log:"
            tail -5 "$log_file"
        fi
        return 1
    fi
}

# Function for interactive mode
interactive_mode() {
    local oracle_host="${1:-$DEFAULT_ORACLE_HOST}"
    local log_file="$2"
    
    while true; do
        SESSION_COUNT=$((SESSION_COUNT + 1))
        
        if [ $SESSION_COUNT -gt 1 ]; then
            echo ""
            echo "----------------------------------------"
        fi
        
        echo "Interactive Copy Tool - Storage to Oracle Server (Session #$SESSION_COUNT)"
        echo "========================================================================="
        echo "Source: $STORAGE_DIR"
        echo "Oracle: $oracle_host:$ORACLE_PATH"
        echo ""
        
        # Handle directory selection
        if [ -n "$LAST_DIRECTORY" ]; then
            echo "Last directory used: $LAST_DIRECTORY"
            echo ""
            echo "Options:"
            echo "1. Continue in '$LAST_DIRECTORY' directory"
            echo "2. Change to a different directory"
            echo "3. Work in root directory"
            echo ""
            echo "Enter your choice (1/2/3) or press Enter for option 1:"
            read -r choice
            
            case "$choice" in
                "2")
                    echo ""
                    echo "Enter the directory path (e.g., 'src', 'docs/api'):"
                    read -r new_dir
                    LAST_DIRECTORY=$(echo "$new_dir" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//;s/^\/\+//;s/\/\+$//')
                    ;;
                "3")
                    LAST_DIRECTORY=""
                    ;;
                ""|"1")
                    # Keep using LAST_DIRECTORY
                    ;;
                *)
                    echo "Invalid choice. Using last directory."
                    ;;
            esac
        else
            echo "Enter the directory to work in (or press Enter for root directory):"
            echo "Examples: 'src', 'docs/api', 'components'"
            read -r dir_input
            LAST_DIRECTORY=$(echo "$dir_input" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//;s/^\/\+//;s/\/\+$//')
        fi
        
        # Show current working directory and contents
        if [ -n "$LAST_DIRECTORY" ]; then
            echo ""
            echo "Working in directory: $LAST_DIRECTORY"
            list_contents "$STORAGE_DIR/$LAST_DIRECTORY" "$STORAGE_DIR/$LAST_DIRECTORY"
        else
            echo ""
            echo "Working in root directory"
            list_contents "$STORAGE_DIR" "$STORAGE_DIR"
        fi
        
        echo ""
        echo "Enter the name of the file or directory you want to copy:"
        echo "(Enter just the filename, e.g., 'myfile.txt' or 'subfolder')"
        read -r item_name
        
        # Perform the copy operations
        if copy_to_app "$item_name" "$LAST_DIRECTORY"; then
            if copy_to_oracle "$item_name" "$LAST_DIRECTORY" "$oracle_host" "$log_file"; then
                echo ""
                echo "🎉 Complete! File successfully copied to Oracle server."
            else
                echo "❌ Failed to copy to Oracle server"
            fi
        else
            echo "❌ Failed to copy to app directory"
        fi
        
        echo ""
        echo "What would you like to do next?"
        echo "1. Copy another file/directory"
        echo "2. Exit"
        echo ""
        echo "Enter your choice (1/2) or press Enter to continue:"
        read -r next_action
        
        case "$next_action" in
            "2")
                echo "Goodbye!"
                exit 0
                ;;
            ""|"1")
                # Continue the loop
                ;;
            *)
                echo "Invalid choice. Continuing..."
                ;;
        esac
    done
}

# Main script logic
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    usage
fi

# Get parameters
FILENAME="$1"
SUBDIRECTORY="$2"
ORACLE_HOST="${3:-$DEFAULT_ORACLE_HOST}"
LOG_FILE="$4"

# Check if running in interactive mode (no filename provided)
if [ -z "$FILENAME" ]; then
    echo "=== Interactive Mode ==="
    echo "No filename provided. Starting interactive mode..."
    echo ""
    interactive_mode "$ORACLE_HOST" "$LOG_FILE"
else
    echo "=== Direct Mode ==="
    echo "Filename: $FILENAME"
    echo "Subdirectory: ${SUBDIRECTORY:-'(root)'}"
    echo "Oracle host: $ORACLE_HOST"
    if [ -n "$LOG_FILE" ]; then
        echo "Log file: $LOG_FILE"
    fi
    echo ""
    
    # Perform direct copy
    if copy_to_app "$FILENAME" "$SUBDIRECTORY"; then
        if copy_to_oracle "$FILENAME" "$SUBDIRECTORY" "$ORACLE_HOST" "$LOG_FILE"; then
            echo ""
            echo "🎉 Success! File copied to Oracle server."
            
            # Optional cleanup
            echo ""
            echo "Remove local app directory copy? (y/N):"
            read -r cleanup
            if [[ "$cleanup" =~ ^[Yy]$ ]]; then
                if [ -n "$SUBDIRECTORY" ]; then
                    rm -rf "$APP_DIR/$SUBDIRECTORY/$FILENAME"
                else
                    rm -rf "$APP_DIR/$FILENAME"
                fi
                echo "✓ Local app copy removed"
            fi
        else
            echo "❌ Failed to copy to Oracle server"
            exit 1
        fi
    else
        echo "❌ Failed to copy to app directory"
        exit 1
    fi
fi
