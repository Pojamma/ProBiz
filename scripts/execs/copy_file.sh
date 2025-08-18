#!/bin/bash
# smartcopy.sh
# This script copies a file or directory between your Termux device
# and the remote Oracle instance, prompting for various options.

# Define the remote paths for Oracle
ORACLE_HOME="/home/opc"
TERMUX_HOME="/data/data/com.termux/files/home"

# Prompt for direction
echo "Choose direction:"
echo "1. Termux to Oracle"
echo "2. Oracle to Termux"
read -p "Enter choice (1/2): " direction_choice

case $direction_choice in
    1) direction="to" ;;
    2) direction="from" ;;
    *) echo "Invalid choice. Exiting."; exit 1 ;;
esac

# Prompt for file or directory
read -p "Enter file or directory name (in current directory): " item_name

# Check if the item exists
if [ "$direction" = "to" ]; then
    # Check local existence
    if [ ! -e "$item_name" ]; then
        echo "Error: '$item_name' does not exist in the current directory."
        exit 1
    fi
fi

# Determine if it's a file or directory
is_directory=false
recursive=false
replace=true

if [ "$direction" = "to" ] && [ -d "$item_name" ]; then
    is_directory=true
    # Prompt for recursive option
    read -p "Copy directory recursively? (y/n): " recursive_choice
    if [[ "$recursive_choice" =~ ^[Yy] ]]; then
        recursive=true
    fi
    
    # Prompt for replace option
    read -p "Replace existing files? (y/n): " replace_choice
    if [[ "$replace_choice" =~ ^[Nn] ]]; then
        replace=false
    fi
elif [ "$direction" = "from" ]; then
    # For 'from' direction, we need to check if it's a directory on the remote
    # Get the relative path from home
    rel_path=$(realpath --relative-to="$TERMUX_HOME" "$(pwd)")
    remote_path="$ORACLE_HOME/$rel_path"
    
    remote_check=$(ssh oracle-instance "if [ -d \"$remote_path/$item_name\" ]; then echo 'dir'; elif [ -f \"$remote_path/$item_name\" ]; then echo 'file'; else echo 'none'; fi")
    
    if [ "$remote_check" = "none" ]; then
        echo "Error: '$item_name' does not exist on the remote Oracle server."
        exit 1
    elif [ "$remote_check" = "dir" ]; then
        is_directory=true
        # Prompt for recursive option
        read -p "Copy directory recursively? (y/n): " recursive_choice
        if [[ "$recursive_choice" =~ ^[Yy] ]]; then
            recursive=true
        fi
        
        # Prompt for replace option
        read -p "Replace existing files? (y/n): " replace_choice
        if [[ "$replace_choice" =~ ^[Nn] ]]; then
            replace=false
        fi
    fi
fi

# Build rsync options
rsync_opts="-av"

if [ "$is_directory" = true ] && [ "$recursive" = false ]; then
    # For non-recursive directory copies
    rsync_opts="$rsync_opts --no-recursive"
fi

if [ "$replace" = false ]; then
    # Don't overwrite existing files
    rsync_opts="$rsync_opts --ignore-existing"
fi

# Add progress indicator
rsync_opts="$rsync_opts --progress"

# Set source and destination
# Get the relative path from home
rel_path=$(realpath --relative-to="$TERMUX_HOME" "$(pwd)")
remote_path="$ORACLE_HOME/$rel_path"

if [ "$direction" = "to" ]; then
    src="$(pwd)/$item_name"
    dest="oracle-instance:$remote_path/"
else
    src="oracle-instance:$remote_path/$item_name"
    dest="$(pwd)/"
fi

# Perform the copy
echo "Copying with options: $rsync_opts"
echo "From: $src"
echo "To: $dest"

# Confirm before proceeding
read -p "Proceed with copy? (y/n): " confirm
if [[ ! "$confirm" =~ ^[Yy] ]]; then
    echo "Operation cancelled."
    exit 0
fi

# Execute rsync
rsync $rsync_opts "$src" "$dest"

# Check if rsync returned an error
if [ $? -ne 0 ]; then
    echo "Error during copy operation."
    exit 1
else
    echo "Copy operation completed successfully."
fi