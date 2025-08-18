#!/bin/bash

# Define base directories (same as copynb.sh)
TERMUX_HOME="/data/data/com.termux/files/home"
APP_DIR="$TERMUX_HOME/NewBiz"
STORAGE_DIR="$TERMUX_HOME/storage/shared/myApps/NewBiz"

# Initialize session variables
LAST_DIRECTORY=""
SESSION_COUNT=0

# Function to copy a single item
copy_item() {
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
    echo "Source path: $SOURCE_PATH"
    echo "Destination path: $DEST_PATH"
    echo ""
    
    # Check if source exists
    if [ ! -e "$SOURCE_PATH" ]; then
        echo "Error: Source '$SOURCE_PATH' does not exist."
        echo ""
        if [ -n "$current_dir" ]; then
            echo "Available items in $STORAGE_DIR/$current_dir:"
            ls -la "$STORAGE_DIR/$current_dir" 2>/dev/null || echo "Cannot list directory contents."
        else
            echo "Available items in $STORAGE_DIR:"
            ls -la "$STORAGE_DIR" 2>/dev/null || echo "Cannot list directory contents."
        fi
        return 1
    fi
    
    # Determine if it's a file or directory
    if [ -f "$SOURCE_PATH" ]; then
        # It's a file
        echo "Copying file: $item_name"
        
        # Create destination directory if needed
        dest_dir=$(dirname "$DEST_PATH")
        mkdir -p "$dest_dir"
        
        # Copy the file
        cp "$SOURCE_PATH" "$DEST_PATH"
        
        if [ $? -eq 0 ]; then
            echo "✓ File copied successfully!"
            return 0
        else
            echo "✗ Error copying file."
            return 1
        fi
        
    elif [ -d "$SOURCE_PATH" ]; then
        # It's a directory
        echo "Copying directory: $item_name"
        
        # Create the destination directory
        mkdir -p "$DEST_PATH"
        
        # Copy directory contents recursively
        cp -rf "$SOURCE_PATH/." "$DEST_PATH/"
        
        if [ $? -eq 0 ]; then
            echo "✓ Directory copied successfully!"
            return 0
        else
            echo "✗ Error copying directory."
            return 1
        fi
        
    else
        echo "Error: '$SOURCE_PATH' is neither a regular file nor a directory."
        return 1
    fi
}

# Main loop
while true; do
    SESSION_COUNT=$((SESSION_COUNT + 1))
    
    # Clear screen for better readability (except first run)
    if [ $SESSION_COUNT -gt 1 ]; then
        echo ""
        echo "----------------------------------------"
    fi
    
    echo "Interactive File/Directory Copy Tool (Session #$SESSION_COUNT)"
    echo "============================================================="
    echo "Source: $STORAGE_DIR"
    echo "Destination: $APP_DIR"
    echo ""
    
    # Create the base app directory if it doesn't exist
    mkdir -p "$APP_DIR"
    
    # Show current directory context
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
    
    # Show current working directory
    if [ -n "$LAST_DIRECTORY" ]; then
        echo ""
        echo "Working in directory: $LAST_DIRECTORY"
        echo "Full source path: $STORAGE_DIR/$LAST_DIRECTORY"
        
        # Check if directory exists and show contents
        if [ -d "$STORAGE_DIR/$LAST_DIRECTORY" ]; then
            echo ""
            echo "Contents of $STORAGE_DIR/$LAST_DIRECTORY:"
            ls -la "$STORAGE_DIR/$LAST_DIRECTORY" 2>/dev/null || echo "Cannot list directory contents."
        else
            echo ""
            echo "Warning: Directory '$STORAGE_DIR/$LAST_DIRECTORY' does not exist."
            echo "Available directories in $STORAGE_DIR:"
            find "$STORAGE_DIR" -type d -not -path "$STORAGE_DIR" | sed "s|$STORAGE_DIR/||" | head -10
        fi
    else
        echo ""
        echo "Working in root directory: $STORAGE_DIR"
        echo ""
        echo "Contents of $STORAGE_DIR:"
        ls -la "$STORAGE_DIR" 2>/dev/null || echo "Cannot list directory contents."
    fi
    
    echo ""
    echo "Enter the name of the file or directory you want to copy:"
    echo "(Enter just the filename, e.g., 'myfile.txt' or 'subfolder')"
    read -r item_name
    
    # Perform the copy operation
    copy_item "$item_name" "$LAST_DIRECTORY"
    
    echo ""
    echo "Copy operation complete!"
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