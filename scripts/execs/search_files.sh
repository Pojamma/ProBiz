#!/bin/bash

# File String Search Script
# Searches for strings in files with various options

# Function to display usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "This script searches for a string in files within a directory."
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo ""
    echo "The script will prompt you for:"
    echo "  - Search directory (default: current directory)"
    echo "  - Search string"
    echo "  - Recursive search (y/n)"
    echo "  - Exclude node_modules directory (Y/n, default: Y)"
    echo "  - Output format (filenames only or full paths)"
    echo ""
}

# Function to get yes/no input
get_yes_no() {
    local prompt="$1"
    local response
    while true; do
        read -p "$prompt (y/n): " response
        case $response in
            [Yy]|[Yy][Ee][Ss]) return 0 ;;  # yes
            [Nn]|[Nn][Oo]) return 1 ;;     # no
            *) echo "Please answer y or n." ;;
        esac
    done
}

# Function to get output format choice
get_output_format() {
    local choice

    echo ""
    echo "Output format options:"
    echo "1) Filenames only"
    echo "2) Full paths with filenames"

    while true; do
        read -p "Choose output format (1 or 2): " choice
        case $choice in
            1) return 1 ;;  # filenames only
            2) return 2 ;;  # full paths
            *) echo "Please enter 1 or 2." ;;
        esac
    done
}

# Check for help flag
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_usage
    exit 0
fi

essh_echo "=== File String Search Tool ==="

# Get search directory
echo ""
read -p "Enter directory to search (press Enter for current directory): " search_dir

# Use current directory if no input provided
if [[ -z "$search_dir" ]]; then
    search_dir="."
    echo "Using current directory: $(pwd)"
else
    if [[ ! -d "$search_dir" ]]; then
        echo "Error: Directory '$search_dir' does not exist."
        exit 1
    fi
    echo "Using directory: $(realpath "$search_dir")"
fi

echo ""
# Get search string
read -p "Enter the string to search for: " search_string
if [[ -z "$search_string" ]]; then
    echo "Error: Search string cannot be empty."
    exit 1
fi

echo ""
# Get recursive option
if get_yes_no "Search recursively in subdirectories?"; then
    recursive=true
    echo "Will search recursively."
else
    recursive=false
    echo "Will search only in the specified directory."
fi

# Get exclude node_modules option (default yes)
exclude_node_modules=true
read -p "Exclude node_modules directory? (Y/n): " exclude_response
if [[ -z "$exclude_response" || "$exclude_response" =~ ^[Yy] ]]; then
    exclude_node_modules=true
    echo "Will exclude node_modules directory."
else
    exclude_node_modules=false
    echo "Will include node_modules directory."
fi

# Get output format
get_output_format
output_format=$?

echo ""
echo "Searching for: '$search_string'"
echo "==========================================="

# Build base grep command
grep_cmd=(grep -l --binary-files=without-match)

# Add recursive and exclude options
if [[ "$recursive" == true ]]; then
    grep_cmd+=( -r )
    if [[ "$exclude_node_modules" == true ]]; then
        grep_cmd+=( --exclude-dir=node_modules )
    fi
fi

# Execute search
if [[ "$recursive" == true ]]; then
    results=$("${grep_cmd[@]}" -- "$search_string" "$search_dir" 2>/dev/null)
else
    # Non-recursive: search only files in directory
    if [[ "$exclude_node_modules" == true ]]; then
        # in non-recursive, skip node_modules dir entirely
        results=$(find "$search_dir" -maxdepth 1 -type f -exec grep -l --binary-files=without-match -- "$search_string" {} + 2>/dev/null)
    else
        results=$(find "$search_dir" -maxdepth 1 -type f -exec grep -l --binary-files=without-match -- "$search_string" {} + 2>/dev/null)
    fi
fi

# Check for results
if [[ -z "$results" ]]; then
    echo "No files found containing the string '$search_string'."
    exit 0
fi

# Display results
echo "Files containing '$search_string':"
echo ""
if [[ $output_format -eq 1 ]]; then
    echo "$results" | while read -r file; do
        basename "$file"
    done
else
    echo "$results"
fi

# Summary
file_count=$(echo "$results" | wc -l)
echo ""
echo "==========================================="
echo "Found $file_count file(s) containing the search string."
