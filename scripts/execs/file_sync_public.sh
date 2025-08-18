#!/bin/bash

# Public Directory Sync Script
# Syncs files and directories between NewBiz and MinaBri public folders

# Color codes for better UX
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Directory paths
NEWBIZ_DIR="/home/opc/NewBiz/public"
MINABRI_DIR="/var/www/minabri/public"

# Function to print colored output
print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Function to check if directories exist
check_directories() {
    local missing=0
    
    if [ ! -d "$NEWBIZ_DIR" ]; then
        print_error "NewBiz directory not found: $NEWBIZ_DIR"
        missing=1
    fi
    
    if [ ! -d "$MINABRI_DIR" ]; then
        print_warning "MinaBri directory not found: $MINABRI_DIR"
        read -p "Would you like to create it? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sudo mkdir -p "$MINABRI_DIR"
            sudo chown $(whoami):$(whoami) "$MINABRI_DIR"
            print_success "Created MinaBri directory"
        else
            missing=1
        fi
    fi
    
    return $missing
}

# Function to show directory contents
show_contents() {
    local dir="$1"
    local title="$2"
    
    echo -e "\n${BLUE}=== $title ===${NC}"
    if [ -d "$dir" ]; then
        ls -la "$dir" | head -20
        local count=$(find "$dir" -type f | wc -l)
        local dir_count=$(find "$dir" -type d | wc -l)
        echo -e "${YELLOW}Total: $count files, $dir_count directories${NC}"
        if [ $count -gt 20 ]; then
            echo -e "${YELLOW}(Showing first 20 entries)${NC}"
        fi
    else
        print_error "Directory not accessible: $dir"
    fi
}

# Function to copy entire directory contents
copy_all() {
    local source="$1"
    local dest="$2"
    local direction="$3"
    
    print_info "Copying all contents from $direction..."
    print_info "Source: $source"
    print_info "Destination: $dest"
    
    # Show what will be copied
    local file_count=$(find "$source" -type f 2>/dev/null | wc -l)
    local dir_count=$(find "$source" -type d 2>/dev/null | wc -l)
    
    echo -e "\n${YELLOW}This will copy:${NC}"
    echo "  - $file_count files"
    echo "  - $dir_count directories"
    echo -e "${YELLOW}Existing files will be overwritten!${NC}"
    
    read -p "Continue? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Operation cancelled"
        return
    fi
    
    # Ensure destination directory exists
    sudo mkdir -p "$dest"
    
    # Copy with rsync for better handling
    if command -v rsync >/dev/null 2>&1; then
        print_info "Using rsync for efficient copying..."
        if sudo rsync -av --progress "$source/" "$dest/"; then
            print_success "All contents copied successfully!"
        else
            print_error "Copy operation failed"
        fi
    else
        print_info "Using cp for copying..."
        if sudo cp -rf "$source/"* "$dest/" 2>/dev/null; then
            print_success "All contents copied successfully!"
        else
            print_error "Copy operation failed"
        fi
    fi
}

# Function to copy specific file or directory
copy_specific() {
    local source_base="$1"
    local dest_base="$2"
    local direction="$3"
    
    echo -e "\n${BLUE}Available items in $direction source:${NC}"
    ls -la "$source_base"
    
    echo
    read -p "Enter the name of file/directory to copy: " item_name
    
    if [ -z "$item_name" ]; then
        print_error "No item specified"
        return
    fi
    
    local source_item="$source_base/$item_name"
    local dest_item="$dest_base/$item_name"
    
    if [ ! -e "$source_item" ]; then
        print_error "Item not found: $source_item"
        return
    fi
    
    if [ -d "$source_item" ]; then
        print_info "Copying directory: $item_name"
        local file_count=$(find "$source_item" -type f 2>/dev/null | wc -l)
        print_info "This directory contains $file_count files"
    else
        print_info "Copying file: $item_name"
        local size=$(du -h "$source_item" | cut -f1)
        print_info "File size: $size"
    fi
    
    read -p "Continue with copy? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Operation cancelled"
        return
    fi
    
    # Ensure destination base directory exists
    sudo mkdir -p "$dest_base"
    
    # Copy the item
    if sudo cp -rf "$source_item" "$dest_base/"; then
        print_success "Successfully copied: $item_name"
    else
        print_error "Failed to copy: $item_name"
    fi
}

# Function to show disk usage
show_disk_usage() {
    echo -e "\n${BLUE}=== Disk Usage ===${NC}"
    echo -e "${YELLOW}NewBiz public directory:${NC}"
    du -sh "$NEWBIZ_DIR" 2>/dev/null || echo "Directory not accessible"
    
    echo -e "${YELLOW}MinaBri public directory:${NC}"
    du -sh "$MINABRI_DIR" 2>/dev/null || echo "Directory not accessible"
    
    echo -e "${YELLOW}Available disk space:${NC}"
    df -h / | grep -v Filesystem
}

# Main menu function
show_menu() {
    clear
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                 Public Directory Sync Tool               ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${BLUE}Source Directories:${NC}"
    echo -e "  NewBiz:  ${YELLOW}$NEWBIZ_DIR${NC}"
    echo -e "  MinaBri: ${YELLOW}$MINABRI_DIR${NC}"
    echo
    echo -e "${BLUE}Choose an option:${NC}"
    echo "  1) Copy ALL from NewBiz → MinaBri"
    echo "  2) Copy ALL from MinaBri → NewBiz"
    echo "  3) Copy specific item: NewBiz → MinaBri"
    echo "  4) Copy specific item: MinaBri → NewBiz"
    echo "  5) View NewBiz contents"
    echo "  6) View MinaBri contents"
    echo "  7) Show disk usage"
    echo "  8) Exit"
    echo
}

# Main execution loop
main() {
    # Check if running as root for some operations
    if [ "$EUID" -ne 0 ] && [ ! -w "$MINABRI_DIR" 2>/dev/null ]; then
        print_warning "You may need sudo privileges for some operations"
    fi
    
    # Check directories exist
    if ! check_directories; then
        print_error "Cannot proceed - required directories missing"
        exit 1
    fi
    
    while true; do
        show_menu
        read -p "Enter your choice (1-8): " choice
        
        case $choice in
            1)
                copy_all "$NEWBIZ_DIR" "$MINABRI_DIR" "NewBiz → MinaBri"
                read -p "Press Enter to continue..." -r
                ;;
            2)
                copy_all "$MINABRI_DIR" "$NEWBIZ_DIR" "MinaBri → NewBiz"
                read -p "Press Enter to continue..." -r
                ;;
            3)
                copy_specific "$NEWBIZ_DIR" "$MINABRI_DIR" "NewBiz → MinaBri"
                read -p "Press Enter to continue..." -r
                ;;
            4)
                copy_specific "$MINABRI_DIR" "$NEWBIZ_DIR" "MinaBri → NewBiz"
                read -p "Press Enter to continue..." -r
                ;;
            5)
                show_contents "$NEWBIZ_DIR" "NewBiz Public Directory Contents"
                read -p "Press Enter to continue..." -r
                ;;
            6)
                show_contents "$MINABRI_DIR" "MinaBri Public Directory Contents"
                read -p "Press Enter to continue..." -r
                ;;
            7)
                show_disk_usage
                read -p "Press Enter to continue..." -r
                ;;
            8)
                print_success "Thanks for using the sync tool!"
                exit 0
                ;;
            *)
                print_error "Invalid option. Please choose 1-8."
                sleep 2
                ;;
        esac
    done
}

# Run the main function
main