#!/bin/bash

# Define base directories
TERMUX_HOME="/data/data/com.termux/files/home"
APP_DIR="$TERMUX_HOME/NewBiz"
STORAGE_DIR="$TERMUX_HOME/storage/shared/myApps/NewBiz"
CONFIG_FILE="$STORAGE_DIR/directories.conf"

echo "Starting file copy from Android storage to Termux..."

# Create the base app directory
mkdir -p "$APP_DIR"

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Config file not found at $CONFIG_FILE"
    echo "Please create a file with a list of directories to sync."
    exit 1
fi

# Create all required directories from config file
echo "Creating directories..."
while read -r dir; do
    # Skip empty lines or lines starting with #
    if [ -n "$dir" ] && [[ ! "$dir" =~ ^# ]]; then
        echo "Creating directory: $APP_DIR/$dir"
        mkdir -p "$APP_DIR/$dir"
    fi
done < "$CONFIG_FILE"

# Copy root files
echo "Copying root files..."
find "$STORAGE_DIR" -maxdepth 1 -type f -not -name "directories.conf" -exec cp {} "$APP_DIR/" \;

# Copy files from each directory in the config file
while read -r dir; do
    # Skip empty lines or lines starting with #
    if [ -n "$dir" ] && [[ ! "$dir" =~ ^# ]]; then
        # Check if source directory exists before attempting to copy
        if [ -d "$STORAGE_DIR/$dir" ]; then
            # Use cp with recursive and force flags to overwrite existing files
            echo "Copying $dir files (including subdirectories)..."
            cp -rf "$STORAGE_DIR/$dir/." "$APP_DIR/$dir/"
        else
            echo "Warning: Source directory $STORAGE_DIR/$dir does not exist. Skipping..."
        fi
    fi
done < "$CONFIG_FILE"

echo "File copy complete!"

# Change to the app directory
cd "$APP_DIR"

# Print status message
echo "Files copied to $APP_DIR"
echo "To run the server: cd $APP_DIR && nodemon src/server.js"