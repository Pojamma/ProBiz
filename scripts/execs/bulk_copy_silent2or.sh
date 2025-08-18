#!/bin/bash
# silent_bulk_copy.sh
# This script copies all files in the current directory to the Oracle server
# Fully automated - no user input required, all output goes to log file

# Define the remote paths for Oracle
ORACLE_HOME="/home/opc"
TERMUX_HOME="/data/data/com.termux/files/home"

# Create logs directory in home if it doesn't exist
LOGS_DIR="$TERMUX_HOME/logs"
mkdir -p "$LOGS_DIR"

# Create log file with timestamp in logs directory
LOG_FILE="$LOGS_DIR/bulk_copy_$(date +%Y%m%d_%H%M%S).log"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Start logging
log_message "=== Bulk Copy Operation Started ==="
log_message "Current directory: $(pwd)"

# Get the relative path from home to current directory
rel_path=$(realpath --relative-to="$TERMUX_HOME" "$(pwd)")
remote_path="$ORACLE_HOME/$rel_path"

log_message "Remote destination: oracle-instance:$remote_path/"

# Check if there are any files to copy (excluding directories)
file_count=$(find . -maxdepth 1 -type f | wc -l)

if [ "$file_count" -eq 0 ]; then
    log_message "No files found in the current directory to copy."
    log_message "=== Operation Completed (No Action Taken) ==="
    exit 0
fi

log_message "Found $file_count file(s) to copy from current directory."

# Log what will be copied
log_message "Files to be copied:"
find . -maxdepth 1 -type f -exec basename {} \; | while read file; do
    log_message "  - $file"
done

# Build rsync options
# -a: archive mode (preserves permissions, times, etc.)
# -v: verbose
# --no-dirs: don't create directories
# --no-recursive: don't recurse into directories
# --progress: show progress
rsync_opts="-av --no-dirs --no-recursive --progress"

log_message "Starting copy operation with options: $rsync_opts"

# Copy all files in current directory and capture output
rsync $rsync_opts ./* oracle-instance:$remote_path/ >> "$LOG_FILE" 2>&1
rsync_exit_code=$?

# Check if rsync returned an error
if [ $rsync_exit_code -ne 0 ]; then
    log_message "ERROR: Copy operation failed with exit code $rsync_exit_code"
    log_message "=== Operation Failed ==="
    exit 1
else
    log_message "SUCCESS: All files copied successfully"
    log_message "=== Operation Completed Successfully ==="
fi

# Optional: Print log file location to stdout (only output to screen)
echo "Copy operation completed. Check log file: $LOG_FILE"