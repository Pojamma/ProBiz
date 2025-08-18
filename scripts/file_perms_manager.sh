#!/bin/bash

# Interactive File Permissions and Groups Management Script
# A user-friendly menu-driven interface for managing Linux file permissions and groups

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Function to clear screen and show header
show_header() {
    clear
    echo -e "${BLUE}${BOLD}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}${BOLD}           File Permissions and Groups Manager${NC}"
    echo -e "${BLUE}${BOLD}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
}

# Function to pause and wait for user input
pause() {
    echo ""
    echo -e "${CYAN}Press Enter to continue...${NC}"
    read
}

# Function to validate file/directory exists
validate_path() {
    local path="$1"
    if [[ ! -e "$path" ]]; then
        echo -e "${RED}Error: '$path' does not exist!${NC}"
        return 1
    fi
    return 0
}

# Function to get yes/no input
get_yes_no() {
    local prompt="$1"
    local response
    
    while true; do
        echo -e "${CYAN}$prompt (y/n): ${NC}"
        read -r response
        case ${response,,} in
            y|yes) return 0 ;;
            n|no) return 1 ;;
            *) echo -e "${YELLOW}Please enter 'y' or 'n'${NC}" ;;
        esac
    done
}

# Function to show main menu
show_main_menu() {
    show_header
    echo -e "${BOLD}Main Menu:${NC}"
    echo ""
    echo "1.  View file/directory permissions"
    echo "2.  Change file/directory permissions"
    echo "3.  Change file/directory owner"
    echo "4.  Change file/directory group"
    echo "5.  Change both owner and group"
    echo "6.  Add user to group"
    echo "7.  Remove user from group"
    echo "8.  List groups (all or for specific user)"
    echo "9.  Create new user"
    echo "10. Create new group"
    echo "11. Find files by permissions"
    echo "12. Backup permissions"
    echo "13. Restore permissions from backup"
    echo "14. Help & Examples"
    echo "15. Exit"
    echo ""
    echo -e "${CYAN}Enter your choice (1-15): ${NC}"
}

# Function to list permissions
list_permissions() {
    show_header
    echo -e "${BOLD}View File/Directory Permissions${NC}"
    echo ""
    
    echo -e "${CYAN}Enter the path to view:${NC}"
    read -r target_path
    
    if ! validate_path "$target_path"; then
        pause
        return 1
    fi
    
    echo ""
    echo -e "${BLUE}Permissions for: $target_path${NC}"
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    ls -la "$target_path"
    
    if [[ -d "$target_path" ]]; then
        echo ""
        if get_yes_no "Show contents of directory?"; then
            echo ""
            echo -e "${BLUE}Directory contents:${NC}"
            echo -e "${BLUE}═══════════════════${NC}"
            ls -la "$target_path/"
        fi
    fi
    
    pause
}

# Function to change permissions
change_permissions() {
    show_header
    echo -e "${BOLD}Change File/Directory Permissions${NC}"
    echo ""
    
    echo -e "${CYAN}Enter the path:${NC}"
    read -r target_path
    
    if ! validate_path "$target_path"; then
        pause
        return 1
    fi
    
    echo ""
    echo "Current permissions:"
    ls -la "$target_path"
    echo ""
    
    echo "Choose permission format:"
    echo "1. Numeric (e.g., 755, 644)"
    echo "2. Symbolic (e.g., rwxr-xr-x, rw-r--r--)"
    echo ""
    echo -e "${CYAN}Enter choice (1-2): ${NC}"
    read -r format_choice
    
    echo ""
    case $format_choice in
        1)
            echo -e "${CYAN}Enter numeric permissions (e.g., 755, 644, 600): ${NC}"
            read -r permissions
            ;;
        2)
            echo -e "${CYAN}Enter symbolic permissions (e.g., rwxr-xr-x, rw-r--r--): ${NC}"
            read -r permissions
            ;;
        *)
            echo -e "${RED}Invalid choice!${NC}"
            pause
            return 1
            ;;
    esac
    
    local recursive=""
    if [[ -d "$target_path" ]]; then
        if get_yes_no "Apply recursively to all contents?"; then
            recursive="-R"
        fi
    fi
    
    echo ""
    if chmod $recursive "$permissions" "$target_path"; then
        echo -e "${GREEN}✓ Successfully changed permissions!${NC}"
        echo ""
        echo "New permissions:"
        ls -la "$target_path"
    else
        echo -e "${RED}✗ Failed to change permissions!${NC}"
    fi
    
    pause
}

# Function to change owner
change_owner() {
    show_header
    echo -e "${BOLD}Change File/Directory Owner${NC}"
    echo ""
    
    echo -e "${CYAN}Enter the path:${NC}"
    read -r target_path
    
    if ! validate_path "$target_path"; then
        pause
        return 1
    fi
    
    echo ""
    echo "Current ownership:"
    ls -la "$target_path"
    echo ""
    
    echo -e "${CYAN}Enter new owner username: ${NC}"
    read -r new_owner
    
    local recursive=""
    if [[ -d "$target_path" ]]; then
        if get_yes_no "Apply recursively to all contents?"; then
            recursive="-R"
        fi
    fi
    
    echo ""
    if sudo chown $recursive "$new_owner" "$target_path"; then
        echo -e "${GREEN}✓ Successfully changed owner to '$new_owner'!${NC}"
        echo ""
        echo "New ownership:"
        ls -la "$target_path"
    else
        echo -e "${RED}✗ Failed to change owner!${NC}"
    fi
    
    pause
}

# Function to change group
change_group() {
    show_header
    echo -e "${BOLD}Change File/Directory Group${NC}"
    echo ""
    
    echo -e "${CYAN}Enter the path:${NC}"
    read -r target_path
    
    if ! validate_path "$target_path"; then
        pause
        return 1
    fi
    
    echo ""
    echo "Current group:"
    ls -la "$target_path"
    echo ""
    
    echo -e "${CYAN}Enter new group name: ${NC}"
    read -r new_group
    
    local recursive=""
    if [[ -d "$target_path" ]]; then
        if get_yes_no "Apply recursively to all contents?"; then
            recursive="-R"
        fi
    fi
    
    echo ""
    if sudo chgrp $recursive "$new_group" "$target_path"; then
        echo -e "${GREEN}✓ Successfully changed group to '$new_group'!${NC}"
        echo ""
        echo "New group:"
        ls -la "$target_path"
    else
        echo -e "${RED}✗ Failed to change group!${NC}"
    fi
    
    pause
}

# Function to change both owner and group
change_owner_group() {
    show_header
    echo -e "${BOLD}Change File/Directory Owner and Group${NC}"
    echo ""
    
    echo -e "${CYAN}Enter the path:${NC}"
    read -r target_path
    
    if ! validate_path "$target_path"; then
        pause
        return 1
    fi
    
    echo ""
    echo "Current ownership:"
    ls -la "$target_path"
    echo ""
    
    echo -e "${CYAN}Enter new owner username: ${NC}"
    read -r new_owner
    
    echo -e "${CYAN}Enter new group name: ${NC}"
    read -r new_group
    
    local recursive=""
    if [[ -d "$target_path" ]]; then
        if get_yes_no "Apply recursively to all contents?"; then
            recursive="-R"
        fi
    fi
    
    echo ""
    if sudo chown $recursive "$new_owner:$new_group" "$target_path"; then
        echo -e "${GREEN}✓ Successfully changed owner to '$new_owner' and group to '$new_group'!${NC}"
        echo ""
        echo "New ownership:"
        ls -la "$target_path"
    else
        echo -e "${RED}✗ Failed to change ownership!${NC}"
    fi
    
    pause
}

# Function to add user to group
add_user_to_group() {
    show_header
    echo -e "${BOLD}Add User to Group${NC}"
    echo ""
    
    echo -e "${CYAN}Enter username to add: ${NC}"
    read -r username
    
    echo -e "${CYAN}Enter group name: ${NC}"
    read -r groupname
    
    echo ""
    if sudo usermod -a -G "$groupname" "$username"; then
        echo -e "${GREEN}✓ Successfully added user '$username' to group '$groupname'!${NC}"
        echo -e "${YELLOW}Note: User may need to log out and back in for changes to take effect.${NC}"
        echo ""
        echo "User's current groups:"
        groups "$username"
    else
        echo -e "${RED}✗ Failed to add user to group!${NC}"
    fi
    
    pause
}

# Function to remove user from group
remove_user_from_group() {
    show_header
    echo -e "${BOLD}Remove User from Group${NC}"
    echo ""
    
    echo -e "${CYAN}Enter username to remove: ${NC}"
    read -r username
    
    echo ""
    echo "User's current groups:"
    groups "$username"
    echo ""
    
    echo -e "${CYAN}Enter group name to remove from: ${NC}"
    read -r groupname
    
    echo ""
    if sudo gpasswd -d "$username" "$groupname"; then
        echo -e "${GREEN}✓ Successfully removed user '$username' from group '$groupname'!${NC}"
        echo ""
        echo "User's updated groups:"
        groups "$username"
    else
        echo -e "${RED}✗ Failed to remove user from group!${NC}"
    fi
    
    pause
}

# Function to list groups
list_groups() {
    show_header
    echo -e "${BOLD}List Groups${NC}"
    echo ""
    
    echo "Choose option:"
    echo "1. List all groups on system"
    echo "2. List groups for specific user"
    echo ""
    echo -e "${CYAN}Enter choice (1-2): ${NC}"
    read -r choice
    
    echo ""
    case $choice in
        1)
            echo -e "${BLUE}All groups on system:${NC}"
            echo -e "${BLUE}═══════════════════════${NC}"
            cut -d: -f1 /etc/group | sort | column
            ;;
        2)
            echo -e "${CYAN}Enter username: ${NC}"
            read -r username
            echo ""
            echo -e "${BLUE}Groups for user '$username':${NC}"
            echo -e "${BLUE}═══════════════════════════${NC}"
            groups "$username"
            ;;
        *)
            echo -e "${RED}Invalid choice!${NC}"
            ;;
    esac
    
    pause
}

# Function to create user
create_user() {
    show_header
    echo -e "${BOLD}Create New User${NC}"
    echo ""
    
    echo -e "${CYAN}Enter new username: ${NC}"
    read -r new_username
    
    echo ""
    if sudo useradd -m "$new_username"; then
        echo -e "${GREEN}✓ Successfully created user '$new_username'!${NC}"
        echo ""
        if get_yes_no "Set password for new user now?"; then
            sudo passwd "$new_username"
        fi
    else
        echo -e "${RED}✗ Failed to create user '$new_username'!${NC}"
    fi
    
    pause
}

# Function to create group
create_group() {
    show_header
    echo -e "${BOLD}Create New Group${NC}"
    echo ""
    
    echo -e "${CYAN}Enter new group name: ${NC}"
    read -r new_group
    
    echo ""
    if sudo groupadd "$new_group"; then
        echo -e "${GREEN}✓ Successfully created group '$new_group'!${NC}"
    else
        echo -e "${RED}✗ Failed to create group '$new_group'!${NC}"
    fi
    
    pause
}

# Function to find files by permissions
find_files_by_permissions() {
    show_header
    echo -e "${BOLD}Find Files by Permissions${NC}"
    echo ""
    
    echo -e "${CYAN}Enter directory to search in (or press Enter for current directory): ${NC}"
    read -r search_dir
    
    if [[ -z "$search_dir" ]]; then
        search_dir="."
    fi
    
    if ! validate_path "$search_dir"; then
        pause
        return 1
    fi
    
    echo ""
    echo "Permission format:"
    echo "1. Numeric (e.g., 777, 755, 644)"
    echo "2. Symbolic (e.g., -rwxrwxrwx)"
    echo ""
    echo -e "${CYAN}Enter choice (1-2): ${NC}"
    read -r format_choice
    
    echo ""
    case $format_choice in
        1)
            echo -e "${CYAN}Enter numeric permissions to search for: ${NC}"
            read -r permissions
            permissions="-$permissions"
            ;;
        2)
            echo -e "${CYAN}Enter symbolic permissions to search for: ${NC}"
            read -r permissions
            ;;
        *)
            echo -e "${RED}Invalid choice!${NC}"
            pause
            return 1
            ;;
    esac
    
    echo ""
    echo -e "${BLUE}Searching for files with permissions '$permissions' in '$search_dir':${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    
    local found_files
    found_files=$(find "$search_dir" -type f -perm "$permissions" 2>/dev/null)
    
    if [[ -z "$found_files" ]]; then
        echo -e "${YELLOW}No files found with permissions '$permissions'${NC}"
    else
        echo "$found_files" | while read -r file; do
            ls -la "$file"
        done
    fi
    
    pause
}

# Function to backup permissions
backup_permissions() {
    show_header
    echo -e "${BOLD}Backup Permissions${NC}"
    echo ""
    
    echo -e "${CYAN}Enter path to backup: ${NC}"
    read -r target_path
    
    if ! validate_path "$target_path"; then
        pause
        return 1
    fi
    
    local backup_file="permissions_backup_$(date +%Y%m%d_%H%M%S).txt"
    
    echo ""
    echo -e "${BLUE}Creating permissions backup...${NC}"
    
    if [[ -d "$target_path" ]]; then
        find "$target_path" -printf '%M %u %g %p\n' > "$backup_file"
    else
        stat -c '%A %U %G %n' "$target_path" > "$backup_file"
    fi
    
    echo -e "${GREEN}✓ Permissions backed up successfully!${NC}"
    echo -e "${BLUE}Backup file: $backup_file${NC}"
    
    pause
}

# Function to restore permissions
restore_permissions() {
    show_header
    echo -e "${BOLD}Restore Permissions from Backup${NC}"
    echo ""
    
    echo "Available backup files:"
    ls -la permissions_backup_*.txt 2>/dev/null || echo "No backup files found"
    echo ""
    
    echo -e "${CYAN}Enter backup filename: ${NC}"
    read -r backup_file
    
    if [[ ! -f "$backup_file" ]]; then
        echo -e "${RED}Error: Backup file '$backup_file' does not exist!${NC}"
        pause
        return 1
    fi
    
    echo ""
    echo -e "${BLUE}Restoring permissions from backup...${NC}"
    
    local restored=0
    local skipped=0
    
    while IFS=' ' read -r perms owner group filepath; do
        if [[ -e "$filepath" ]]; then
            sudo chown "$owner:$group" "$filepath" 2>/dev/null
            chmod "$perms" "$filepath" 2>/dev/null
            echo -e "${GREEN}✓ Restored: $filepath${NC}"
            ((restored++))
        else
            echo -e "${YELLOW}⊘ Skipped (not found): $filepath${NC}"
            ((skipped++))
        fi
    done < "$backup_file"
    
    echo ""
    echo -e "${GREEN}Restoration complete!${NC}"
    echo -e "${BLUE}Files restored: $restored${NC}"
    echo -e "${YELLOW}Files skipped: $skipped${NC}"
    
    pause
}

# Function to show help
show_help() {
    show_header
    echo -e "${BOLD}Help & Examples${NC}"
    echo ""
    echo -e "${BLUE}Common Permission Values:${NC}"
    echo "• 755 (rwxr-xr-x) - Owner: read/write/execute, Group/Others: read/execute"
    echo "• 644 (rw-r--r--) - Owner: read/write, Group/Others: read only"
    echo "• 600 (rw-------) - Owner: read/write, Group/Others: no access"
    echo "• 777 (rwxrwxrwx) - Everyone: read/write/execute (use carefully!)"
    echo ""
    echo -e "${BLUE}Permission Format:${NC}"
    echo "• First digit: Owner permissions"
    echo "• Second digit: Group permissions"
    echo "• Third digit: Other permissions"
    echo ""
    echo -e "${BLUE}Permission Values:${NC}"
    echo "• 4 = Read (r)"
    echo "• 2 = Write (w)"
    echo "• 1 = Execute (x)"
    echo "• Add them together: 7=rwx, 6=rw-, 5=r-x, 4=r--, etc."
    echo ""
    echo -e "${BLUE}Tips:${NC}"
    echo "• Use sudo when prompted for administrative operations"
    echo "• Backup permissions before making major changes"
    echo "• Be careful with recursive operations on large directories"
    echo "• Test permission changes on non-critical files first"
    
    pause
}

# Main program loop
main() {
    while true; do
        show_main_menu
        read -r choice
        
        case $choice in
            1) list_permissions ;;
            2) change_permissions ;;
            3) change_owner ;;
            4) change_group ;;
            5) change_owner_group ;;
            6) add_user_to_group ;;
            7) remove_user_from_group ;;
            8) list_groups ;;
            9) create_user ;;
            10) create_group ;;
            11) find_files_by_permissions ;;
            12) backup_permissions ;;
            13) restore_permissions ;;
            14) show_help ;;
            15) 
                show_header
                echo -e "${GREEN}Thank you for using File Permissions Manager!${NC}"
                echo ""
                exit 0
                ;;
            *)
                show_header
                echo -e "${RED}Invalid choice! Please enter a number between 1-15.${NC}"
                pause
                ;;
        esac
    done
}

# Check if script is being run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi