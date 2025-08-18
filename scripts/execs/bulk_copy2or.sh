#!/bin/bash
# bulk_copy.sh
# This script copies all files in the current directory to the Oracle server
# Skips subdirectories, automatically replaces files, only asks for confirmation

# Define the remote paths for Oracle
ORACLE_HOME="/home/opc"
TERMUX_HOME="/data/data/com.termux/files/home"

# Get the relative path from home to current directory
rel_path=$(realpath --relative-to="$TERMUX_HOME" "$(pwd)")
remote_path="$ORACLE_HOME/$rel_path"

# Check if there are any files to copy (excluding directories)
file_count=$(find . -maxdepth 1 -type f | wc -l)

if [ "$file_count" -eq 0 ]; then
    echo "No files found in the current directory to copy."
    exit 0
fi

echo "Found $file_count file(s) to copy from current directory."
echo "Destination: oracle-instance:$remote_path/"
echo "Note: This will overwrite existing files on the server."

# Show what will be copied
echo ""
echo "Files to be copied:"
find . -maxdepth 1 -type f -exec basename {} \;

echo ""
read -p "Proceed with copy? (y/n): " confirm
if [[ ! "$confirm" =~ ^[Yy] ]]; then
    echo "Operation cancelled."
    exit 0
fi

# Build rsync options
# -a: archive mode (preserves permissions, times, etc.)
# -v: verbose
# --no-dirs: don't create directories
# --no-recursive: don't recurse into directories
# --progress: show progress
rsync_opts="-av --no-dirs --no-recursive --progress"

# Copy all files in current directory
echo "Copying files..."
rsync $rsync_opts ./* oracle-instance:$remote_path/

# Check if rsync returned an error
if [ $? -ne 0 ]; then
    echo "Error during copy operation."
    exit 1
else
    echo "Bulk copy operation completed successfully."
    echo "All files from current directory have been copied to Oracle server."
fi