#!/bin/bash

# Search and Replace Utility
# A comprehensive tool for searching and replacing text in files

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Global variables
SEARCH_TERM=""
REPLACE_TERM=""
FILE_PATTERN="*"
RECURSIVE=false
CASE_SENSITIVE=true
BACKUP_FILES=true
OUTPUT_FILE=""

# Function to display the main menu
show_menu() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}    Search and Replace Utility v1.0    ${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo
    echo -e "${GREEN}Current Settings:${NC}"
    echo -e "  Search Term: ${YELLOW}${SEARCH_TERM:-'Not set'}${NC}"
    echo -e "  Replace Term: ${YELLOW}${REPLACE_TERM:-'Not set'}${NC}"
    echo -e "  File Pattern: ${YELLOW}${FILE_PATTERN}${NC}"
    echo -e "  Recursive: ${YELLOW}${RECURSIVE}${NC}"
    echo -e "  Case Sensitive: ${YELLOW}${CASE_SENSITIVE}${NC}"
    echo -e "  Backup Files: ${YELLOW}${BACKUP_FILES}${NC}"
    echo -e "  Output File: ${YELLOW}${OUTPUT_FILE:-'None'}${NC}"
    echo
    echo -e "${BLUE}Options:${NC}"
    echo "  1) Set search term"
    echo "  2) Set replace term"
    echo "  3) Set file pattern (e.g., *.txt, *.html)"
    echo "  4) Toggle recursive search"
    echo "  5) Toggle case sensitivity"
    echo "  6) Toggle file backup"
    echo "  7) Set output file for results"
    echo
    echo -e "${PURPLE}Actions:${NC}"
    echo "  8) Search for text (list matching files)"
    echo "  9) Search and show matches with context"
    echo " 10) Search and replace (with confirmation)"
    echo " 11) Search and replace all (no confirmation)"
    echo " 12) Clear all settings"
    echo "  0) Exit"
    echo
    echo -n "Select option: "
}

# Function to set search term
set_search_term() {
    echo -n "Enter search term: "
    read SEARCH_TERM
    echo -e "${GREEN}Search term set to: ${YELLOW}${SEARCH_TERM}${NC}"
    read -p "Press Enter to continue..."
}

# Function to set replace term
set_replace_term() {
    echo -n "Enter replace term: "
    read REPLACE_TERM
    echo -e "${GREEN}Replace term set to: ${YELLOW}${REPLACE_TERM}${NC}"
    read -p "Press Enter to continue..."
}

# Function to set file pattern
set_file_pattern() {
    echo "Examples: *.txt, *.html, *.js, *.css, * (all files)"
    echo -n "Enter file pattern: "
    read FILE_PATTERN
    if [ -z "$FILE_PATTERN" ]; then
        FILE_PATTERN="*"
    fi
    echo -e "${GREEN}File pattern set to: ${YELLOW}${FILE_PATTERN}${NC}"
    read -p "Press Enter to continue..."
}

# Function to toggle recursive search
toggle_recursive() {
    if [ "$RECURSIVE" = true ]; then
        RECURSIVE=false
        echo -e "${GREEN}Recursive search disabled${NC}"
    else
        RECURSIVE=true
        echo -e "${GREEN}Recursive search enabled${NC}"
    fi
    read -p "Press Enter to continue..."
}

# Function to toggle case sensitivity
toggle_case_sensitive() {
    if [ "$CASE_SENSITIVE" = true ]; then
        CASE_SENSITIVE=false
        echo -e "${GREEN}Case insensitive search enabled${NC}"
    else
        CASE_SENSITIVE=true
        echo -e "${GREEN}Case sensitive search enabled${NC}"
    fi
    read -p "Press Enter to continue..."
}

# Function to toggle backup
toggle_backup() {
    if [ "$BACKUP_FILES" = true ]; then
        BACKUP_FILES=false
        echo -e "${GREEN}File backup disabled${NC}"
    else
        BACKUP_FILES=true
        echo -e "${GREEN}File backup enabled${NC}"
    fi
    read -p "Press Enter to continue..."
}

# Function to set output file
set_output_file() {
    echo -n "Enter output file name (or press Enter for none): "
    read OUTPUT_FILE
    if [ -z "$OUTPUT_FILE" ]; then
        echo -e "${GREEN}Output file cleared${NC}"
    else
        echo -e "${GREEN}Output file set to: ${YELLOW}${OUTPUT_FILE}${NC}"
    fi
    read -p "Press Enter to continue..."
}

# Function to build find command options
build_find_options() {
    local find_opts=""
    
    if [ "$RECURSIVE" = false ]; then
        find_opts="$find_opts -maxdepth 1"
    fi
    
    find_opts="$find_opts -name '$FILE_PATTERN' -type f"
    echo "$find_opts"
}

# Function to build grep options
build_grep_options() {
    local grep_opts=""
    
    if [ "$CASE_SENSITIVE" = false ]; then
        grep_opts="$grep_opts -i"
    fi
    
    echo "$grep_opts"
}

# Function to search for files containing text
search_files() {
    if [ -z "$SEARCH_TERM" ]; then
        echo -e "${RED}Please set a search term first!${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    echo -e "${BLUE}Searching for files containing: ${YELLOW}${SEARCH_TERM}${NC}"
    echo
    
    local find_opts=$(build_find_options)
    local grep_opts=$(build_grep_options)
    
    local results=$(eval "find . $find_opts -exec grep -l $grep_opts '$SEARCH_TERM' {} \;")
    
    if [ -z "$results" ]; then
        echo -e "${RED}No files found containing the search term.${NC}"
    else
        echo -e "${GREEN}Files containing '${SEARCH_TERM}':${NC}"
        echo "$results"
        
        local count=$(echo "$results" | wc -l)
        echo
        echo -e "${CYAN}Total files found: $count${NC}"
        
        if [ -n "$OUTPUT_FILE" ]; then
            echo "$results" > "$OUTPUT_FILE"
            echo -e "${GREEN}Results saved to: ${YELLOW}${OUTPUT_FILE}${NC}"
        fi
    fi
    
    read -p "Press Enter to continue..."
}

# Function to search and show matches with context
search_with_context() {
    if [ -z "$SEARCH_TERM" ]; then
        echo -e "${RED}Please set a search term first!${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    echo -e "${BLUE}Searching for: ${YELLOW}${SEARCH_TERM}${NC}"
    echo
    
    local find_opts=$(build_find_options)
    local grep_opts=$(build_grep_options)
    
    local results=$(eval "find . $find_opts -exec grep -n -C 2 $grep_opts '$SEARCH_TERM' {} \;")
    
    if [ -z "$results" ]; then
        echo -e "${RED}No matches found.${NC}"
    else
        echo -e "${GREEN}Matches with context:${NC}"
        echo "$results"
        
        if [ -n "$OUTPUT_FILE" ]; then
            echo "$results" > "$OUTPUT_FILE"
            echo -e "${GREEN}Results saved to: ${YELLOW}${OUTPUT_FILE}${NC}"
        fi
    fi
    
    read -p "Press Enter to continue..."
}

# Function to create backup
create_backup() {
    local file="$1"
    local backup_file="${file}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$file" "$backup_file"
    echo -e "${GREEN}Backup created: ${YELLOW}${backup_file}${NC}"
}

# Function to search and replace with confirmation
search_replace_confirm() {
    if [ -z "$SEARCH_TERM" ] || [ -z "$REPLACE_TERM" ]; then
        echo -e "${RED}Please set both search and replace terms first!${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    echo -e "${BLUE}Search: ${YELLOW}${SEARCH_TERM}${NC}"
    echo -e "${BLUE}Replace: ${YELLOW}${REPLACE_TERM}${NC}"
    echo
    
    local find_opts=$(build_find_options)
    local grep_opts=$(build_grep_options)
    
    local files=$(eval "find . $find_opts -exec grep -l $grep_opts '$SEARCH_TERM' {} \;")
    
    if [ -z "$files" ]; then
        echo -e "${RED}No files found containing the search term.${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    echo -e "${GREEN}Files that will be modified:${NC}"
    echo "$files"
    echo
    
    while IFS= read -r file; do
        echo -e "${CYAN}Processing: ${YELLOW}${file}${NC}"
        
        # Show matches
        local matches=$(eval "grep -n $grep_opts '$SEARCH_TERM' '$file'")
        echo "$matches"
        echo
        
        echo -n "Replace in this file? (y/n/a/q): "
        read answer
        
        case $answer in
            [Yy]* )
                if [ "$BACKUP_FILES" = true ]; then
                    create_backup "$file"
                fi
                
                if [ "$CASE_SENSITIVE" = true ]; then
                    sed -i "s/$SEARCH_TERM/$REPLACE_TERM/g" "$file"
                else
                    sed -i "s/$SEARCH_TERM/$REPLACE_TERM/gi" "$file"
                fi
                echo -e "${GREEN}Replaced in ${file}${NC}"
                ;;
            [Aa]* )
                # Replace in all remaining files
                while IFS= read -r remaining_file; do
                    if [ "$BACKUP_FILES" = true ]; then
                        create_backup "$remaining_file"
                    fi
                    
                    if [ "$CASE_SENSITIVE" = true ]; then
                        sed -i "s/$SEARCH_TERM/$REPLACE_TERM/g" "$remaining_file"
                    else
                        sed -i "s/$SEARCH_TERM/$REPLACE_TERM/gi" "$remaining_file"
                    fi
                    echo -e "${GREEN}Replaced in ${remaining_file}${NC}"
                done <<< "$files"
                break
                ;;
            [Qq]* )
                echo -e "${YELLOW}Operation cancelled.${NC}"
                break
                ;;
            * )
                echo -e "${YELLOW}Skipped ${file}${NC}"
                ;;
        esac
        echo
    done <<< "$files"
    
    read -p "Press Enter to continue..."
}

# Function to search and replace all without confirmation
search_replace_all() {
    if [ -z "$SEARCH_TERM" ] || [ -z "$REPLACE_TERM" ]; then
        echo -e "${RED}Please set both search and replace terms first!${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    echo -e "${BLUE}Search: ${YELLOW}${SEARCH_TERM}${NC}"
    echo -e "${BLUE}Replace: ${YELLOW}${REPLACE_TERM}${NC}"
    echo
    echo -e "${RED}WARNING: This will replace ALL occurrences without confirmation!${NC}"
    echo -n "Are you sure? (type 'YES' to confirm): "
    read confirmation
    
    if [ "$confirmation" != "YES" ]; then
        echo -e "${YELLOW}Operation cancelled.${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    local find_opts=$(build_find_options)
    local grep_opts=$(build_grep_options)
    
    local files=$(eval "find . $find_opts -exec grep -l $grep_opts '$SEARCH_TERM' {} \;")
    
    if [ -z "$files" ]; then
        echo -e "${RED}No files found containing the search term.${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    local count=0
    while IFS= read -r file; do
        if [ "$BACKUP_FILES" = true ]; then
            create_backup "$file"
        fi
        
        if [ "$CASE_SENSITIVE" = true ]; then
            sed -i "s/$SEARCH_TERM/$REPLACE_TERM/g" "$file"
        else
            sed -i "s/$SEARCH_TERM/$REPLACE_TERM/gi" "$file"
        fi
        
        echo -e "${GREEN}Replaced in: ${YELLOW}${file}${NC}"
        ((count++))
    done <<< "$files"
    
    echo
    echo -e "${CYAN}Total files modified: $count${NC}"
    read -p "Press Enter to continue..."
}

# Function to clear all settings
clear_settings() {
    SEARCH_TERM=""
    REPLACE_TERM=""
    FILE_PATTERN="*"
    RECURSIVE=false
    CASE_SENSITIVE=true
    BACKUP_FILES=true
    OUTPUT_FILE=""
    echo -e "${GREEN}All settings cleared!${NC}"
    read -p "Press Enter to continue..."
}

# Main loop
main() {
    while true; do
        show_menu
        read choice
        
        case $choice in
            1) set_search_term ;;
            2) set_replace_term ;;
            3) set_file_pattern ;;
            4) toggle_recursive ;;
            5) toggle_case_sensitive ;;
            6) toggle_backup ;;
            7) set_output_file ;;
            8) search_files ;;
            9) search_with_context ;;
            10) search_replace_confirm ;;
            11) search_replace_all ;;
            12) clear_settings ;;
            0) 
                echo -e "${GREEN}Goodbye!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option. Please try again.${NC}"
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Check if running as script
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi