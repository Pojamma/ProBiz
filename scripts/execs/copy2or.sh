#!/bin/bash
# copyor.sh
# This script copies directories between Termux and Oracle instances
# using the specific paths on each system.
#
# The directories to copy are listed in directories.conf.
#
# Usage: ./copyor.sh [to|from]
#   to: Copy from Termux to Oracle (default)
#   from: Copy from Oracle to Termux

# Set the name of the configuration file
CONF_FILE="directories.conf"

# Check for direction parameter
DIRECTION="${1:-to}"

if [ "$DIRECTION" != "to" ] && [ "$DIRECTION" != "from" ]; then
    echo "Error: Invalid direction parameter. Use 'to' or 'from'."
    echo "Usage: ./copyor.sh [to|from]"
    exit 1
fi

# Verify that directories.conf exists
if [ ! -f "$CONF_FILE" ]; then
    echo "Error: ${CONF_FILE} not found!"
    exit 1
fi

# Local and remote base directories for NewBiz with correct paths
LOCAL_BASE="/data/data/com.termux/files/home/NewBiz"
REMOTE_BASE="oracle-instance:/home/opc/NewBiz"

# Ensure the base directories exist
if [ "$DIRECTION" = "to" ]; then
    # Check if local base exists before attempting to copy
    if [ ! -d "$LOCAL_BASE" ]; then
        echo "Error: Local base directory $LOCAL_BASE does not exist."
        exit 1
    fi
    
    # When copying to Oracle, first ensure the remote directory exists
    ssh ${REMOTE_BASE%%:*} "mkdir -p ${REMOTE_BASE#*:}"
else
    # When copying from Oracle, ensure the local directory exists
    mkdir -p "$LOCAL_BASE"
fi

# Read directories.conf line by line
while IFS= read -r line || [ -n "$line" ]; do
    # Skip empty lines and comments
    if [[ "$line" =~ ^\s*# ]] || [[ -z "$line" ]]; then
        continue
    fi

    # Trim any whitespace from the line (requires xargs)
    dir=$(echo "$line" | xargs)

    if [ "$DIRECTION" = "to" ]; then
        # Copying from Termux to Oracle
        SRC="$LOCAL_BASE/$dir/"
        DEST="$REMOTE_BASE/$(dirname "$dir")/"
        
        # Check if the source directory exists locally
        if [ ! -d "$SRC" ]; then
            echo "Warning: Source directory $SRC does not exist. Skipping..."
            continue
        fi
    else
        # Copying from Oracle to Termux
        SRC="$REMOTE_BASE/$dir/"
        DEST="$LOCAL_BASE/$(dirname "$dir")/"
        
        # Create the local directory if it doesn't exist
        mkdir -p "$DEST"
    fi

    echo "Copying $SRC to $DEST"
    
    # Use cp for local-to-remote copying (this won't work for SSH)
    # So we'll use rsync but with explicit overwrite behavior
    # The -I flag forces rsync to transfer files even if they appear identical
    rsync -avI --progress "$SRC" "$DEST"
    
    # Optionally, check if rsync returned an error
    if [ $? -ne 0 ]; then
        echo "Error copying $SRC. Aborting."
        exit 1
    fi
done < "$CONF_FILE"

echo "File transfers complete."