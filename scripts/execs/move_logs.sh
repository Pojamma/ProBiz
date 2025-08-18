#!/bin/bash
# move_logs.sh
# This script finds all bulk_copy log files in subdirectories and moves them
# to the centralized logs directory in home

# Define paths
TERMUX_HOME="/data/data/com.termux/files/home"
LOGS_DIR="$TERMUX_HOME/logs"

# Create logs directory if it doesn't exist
mkdir -p "$LOGS_DIR"

echo "Moving existing bulk_copy log files to $LOGS_DIR"
echo "Searching from directory: $(pwd)"
echo ""

# Find all bulk_copy log files in current directory and subdirectories
# Exclude the target logs directory to avoid moving files to themselves
log_files=$(find . -name "bulk_copy_*.log" -type f ! -path "./logs/*" 2>/dev/null)

if [ -z "$log_files" ]; then
    echo "No bulk_copy log files found in subdirectories."
    exit 0
fi

# Count files found
file_count=$(echo "$log_files" | wc -l)
echo "Found $file_count log file(s):"

# Show what will be moved
echo "$log_files" | while read -r file; do
    echo "  $file"
done

echo ""
read -p "Move these files to $LOGS_DIR? (y/n): " confirm
if [[ ! "$confirm" =~ ^[Yy] ]]; then
    echo "Operation cancelled."
    exit 0
fi

echo ""
echo "Moving files..."

# Move each log file
moved_count=0
failed_count=0

echo "$log_files" | while read -r file; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        destination="$LOGS_DIR/$filename"
        
        # Check if destination already exists
        if [ -f "$destination" ]; then
            # Add timestamp suffix to avoid conflicts
            timestamp=$(date +%s)
            destination="$LOGS_DIR/${filename%.log}_moved_${timestamp}.log"
            echo "  $file -> $destination (renamed to avoid conflict)"
        else
            echo "  $file -> $destination"
        fi
        
        if mv "$file" "$destination"; then
            ((moved_count++))
        else
            echo "    ERROR: Failed to move $file"
            ((failed_count++))
        fi
    fi
done

echo ""
echo "Operation completed:"
echo "  Files moved successfully: $moved_count"
if [ $failed_count -gt 0 ]; then
    echo "  Files failed to move: $failed_count"
fi

echo ""
echo "All log files are now in: $LOGS_DIR"