#!/bin/bash

# ProBiz File Manager - Development Workflow Script
# Manages files between Android, Termux, and Oracle Server

# Configuration
ANDROID_DIR="/data/data/com.termux/files/home/storage/shared/myApps/ProBiz"
TERMUX_DIR="/data/data/com.termux/files/home/ProBiz"
ORACLE_HOST="oracle-instance-probiz"
ORACLE_DIR="/home/opc/ProBiz"
LOG_FILE="$HOME/probiz_sync.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging function
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
    echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1"
}

# Error logging function
log_error() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: $1" >> "$LOG_FILE"
    echo -e "${RED}[ERROR]${NC} $1"
}

# Warning logging function
log_warning() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - WARNING: $1" >> "$LOG_FILE"
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if directories exist and create if needed
check_and_create_dirs() {
    log_message "Checking directories..."
    
    # Check Android directory
    if [ ! -d "$ANDROID_DIR" ]; then
        log_warning "Android directory doesn't exist: $ANDROID_DIR"
        mkdir -p "$ANDROID_DIR" 2>/dev/null || log_error "Cannot create Android directory"
    fi
    
    # Check Termux directory
    if [ ! -d "$TERMUX_DIR" ]; then
        log_warning "Termux directory doesn't exist: $TERMUX_DIR"
        mkdir -p "$TERMUX_DIR" || log_error "Cannot create Termux directory"
    fi
    
    # Check Oracle connection and directory
    if ssh "$ORACLE_HOST" "[ ! -d '$ORACLE_DIR' ]" 2>/dev/null; then
        log_warning "Oracle directory doesn't exist: $ORACLE_DIR"
        ssh "$ORACLE_HOST" "mkdir -p '$ORACLE_DIR'" 2>/dev/null || log_error "Cannot create Oracle directory"
    fi
}

# Test Oracle connection
test_oracle_connection() {
    echo -e "${BLUE}Testing Oracle server connection...${NC}"
    if ssh -o ConnectTimeout=10 "$ORACLE_HOST" "echo 'Connection successful'" >/dev/null 2>&1; then
        log_message "Oracle server connection: OK"
        return 0
    else
        log_error "Cannot connect to Oracle server"
        return 1
    fi
}

# Copy files/directories with rsync
rsync_copy() {
    local source="$1"
    local dest="$2"
    local description="$3"
    local dry_run="$4"
    
    local rsync_opts="-avz --progress"
    if [ "$dry_run" = "true" ]; then
        rsync_opts="$rsync_opts --dry-run"
        echo -e "${YELLOW}DRY RUN MODE - No files will be copied${NC}"
    fi
    
    log_message "Starting $description..."
    echo -e "${CYAN}Source: $source${NC}"
    echo -e "${CYAN}Destination: $dest${NC}"
    
    if rsync $rsync_opts "$source" "$dest"; then
        log_message "$description completed successfully"
        return 0
    else
        log_error "$description failed"
        return 1
    fi
}

# Android to Termux
android_to_termux() {
    local dry_run="$1"
    rsync_copy "$ANDROID_DIR/" "$TERMUX_DIR/" "Android → Termux copy" "$dry_run"
}

# Termux to Android
termux_to_android() {
    local dry_run="$1"
    rsync_copy "$TERMUX_DIR/" "$ANDROID_DIR/" "Termux → Android copy" "$dry_run"
}

# Termux to Oracle
termux_to_oracle() {
    local dry_run="$1"
    if ! test_oracle_connection; then
        return 1
    fi
    rsync_copy "$TERMUX_DIR/" "$ORACLE_HOST:$ORACLE_DIR/" "Termux → Oracle copy" "$dry_run"
}

# Oracle to Termux
oracle_to_termux() {
    local dry_run="$1"
    if ! test_oracle_connection; then
        return 1
    fi
    rsync_copy "$ORACLE_HOST:$ORACLE_DIR/" "$TERMUX_DIR/" "Oracle → Termux copy" "$dry_run"
}

# Android to Oracle (via Termux staging)
android_to_oracle() {
    local dry_run="$1"
    echo -e "${PURPLE}Two-step process: Android → Termux → Oracle${NC}"
    if android_to_termux "$dry_run" && termux_to_oracle "$dry_run"; then
        log_message "Android → Oracle (via Termux) completed successfully"
    else
        log_error "Android → Oracle (via Termux) failed"
    fi
}

# Oracle to Android (via Termux staging)
oracle_to_android() {
    local dry_run="$1"
    echo -e "${PURPLE}Two-step process: Oracle → Termux → Android${NC}"
    if oracle_to_termux "$dry_run" && termux_to_android "$dry_run"; then
        log_message "Oracle → Android (via Termux) completed successfully"
    else
        log_error "Oracle → Android (via Termux) failed"
    fi
}

# Full sync workflow (Android → Termux → Oracle)
full_sync_workflow() {
    local dry_run="$1"
    echo -e "${PURPLE}Full development workflow sync: Android → Termux → Oracle${NC}"
    if android_to_termux "$dry_run" && termux_to_oracle "$dry_run"; then
        log_message "Full workflow sync completed successfully"
    else
        log_error "Full workflow sync failed"
    fi
}

# Backup function
create_backup() {
    local backup_dir="$HOME/ProBiz_backups/$(date '+%Y%m%d_%H%M%S')"
    mkdir -p "$backup_dir"
    
    echo -e "${BLUE}Creating backup in: $backup_dir${NC}"
    
    # Backup Termux directory
    if [ -d "$TERMUX_DIR" ]; then
        cp -r "$TERMUX_DIR" "$backup_dir/termux_backup"
        log_message "Termux backup created"
    fi
    
    # Backup Oracle directory
    if test_oracle_connection; then
        scp -r "$ORACLE_HOST:$ORACLE_DIR" "$backup_dir/oracle_backup" 2>/dev/null
        if [ $? -eq 0 ]; then
            log_message "Oracle backup created"
        else
            log_warning "Oracle backup failed"
        fi
    fi
    
    log_message "Backup completed in: $backup_dir"
}

# Show directory sizes and file counts
show_status() {
    echo -e "${CYAN}=== ProBiz Directory Status ===${NC}"
    
    # Android directory
    if [ -d "$ANDROID_DIR" ]; then
        local android_size=$(du -sh "$ANDROID_DIR" 2>/dev/null | cut -f1)
        local android_files=$(find "$ANDROID_DIR" -type f 2>/dev/null | wc -l)
        echo -e "${GREEN}Android:${NC} $android_size ($android_files files) - $ANDROID_DIR"
    else
        echo -e "${RED}Android:${NC} Directory not found - $ANDROID_DIR"
    fi
    
    # Termux directory
    if [ -d "$TERMUX_DIR" ]; then
        local termux_size=$(du -sh "$TERMUX_DIR" 2>/dev/null | cut -f1)
        local termux_files=$(find "$TERMUX_DIR" -type f 2>/dev/null | wc -l)
        echo -e "${GREEN}Termux:${NC} $termux_size ($termux_files files) - $TERMUX_DIR"
    else
        echo -e "${RED}Termux:${NC} Directory not found - $TERMUX_DIR"
    fi
    
    # Oracle directory
    if test_oracle_connection; then
        local oracle_info=$(ssh "$ORACLE_HOST" "du -sh '$ORACLE_DIR' 2>/dev/null && find '$ORACLE_DIR' -type f 2>/dev/null | wc -l" 2>/dev/null)
        if [ $? -eq 0 ]; then
            local oracle_size=$(echo "$oracle_info" | head -1 | cut -f1)
            local oracle_files=$(echo "$oracle_info" | tail -1)
            echo -e "${GREEN}Oracle:${NC} $oracle_size ($oracle_files files) - $ORACLE_HOST:$ORACLE_DIR"
        else
            echo -e "${RED}Oracle:${NC} Cannot access directory"
        fi
    else
        echo -e "${RED}Oracle:${NC} Connection failed - $ORACLE_HOST:$ORACLE_DIR"
    fi
    
    echo ""
}

# Show recent log entries
show_recent_logs() {
    if [ -f "$LOG_FILE" ]; then
        echo -e "${CYAN}=== Recent Activity (last 10 entries) ===${NC}"
        tail -10 "$LOG_FILE"
    else
        echo -e "${YELLOW}No log file found${NC}"
    fi
    echo ""
}

# Interactive file selection
select_specific_file() {
    local source_dir="$1"
    local dest_func="$2"
    
    echo -e "${BLUE}Files in $source_dir:${NC}"
    find "$source_dir" -type f -printf "%P\n" 2>/dev/null | nl
    echo ""
    read -p "Enter file number (or 'q' to quit): " selection
    
    if [ "$selection" = "q" ]; then
        return
    fi
    
    local selected_file=$(find "$source_dir" -type f -printf "%P\n" 2>/dev/null | sed -n "${selection}p")
    if [ -n "$selected_file" ]; then
        echo "Selected: $selected_file"
        # This would need more implementation for specific file copying
        log_message "File selection: $selected_file"
    else
        echo -e "${RED}Invalid selection${NC}"
    fi
}

# Main menu
show_menu() {
    clear
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║                     ProBiz File Manager v2.0                        ║${NC}"
    echo -e "${PURPLE}║                Development Workflow Assistant                       ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}Quick Actions:${NC}"
    echo -e "${GREEN} 1)${NC} Android → Termux (Development to Testing)"
    echo -e "${GREEN} 2)${NC} Termux → Oracle (Testing to Production)"
    echo -e "${GREEN} 3)${NC} Full Workflow (Android → Termux → Oracle)"
    echo ""
    echo -e "${CYAN}All Copy Options:${NC}"
    echo -e "${YELLOW} 4)${NC} Termux → Android"
    echo -e "${YELLOW} 5)${NC} Oracle → Termux"
    echo -e "${YELLOW} 6)${NC} Android → Oracle (direct via Termux)"
    echo -e "${YELLOW} 7)${NC} Oracle → Android (direct via Termux)"
    echo ""
    echo -e "${CYAN}Utilities:${NC}"
    echo -e "${BLUE} 8)${NC} Show Status & Directory Info"
    echo -e "${BLUE} 9)${NC} Create Backup"
    echo -e "${BLUE}10)${NC} Test Oracle Connection"
    echo -e "${BLUE}11)${NC} Show Recent Logs"
    echo -e "${BLUE}12)${NC} Dry Run Mode (preview changes)"
    echo ""
    echo -e "${RED}13)${NC} Exit"
    echo ""
}

# Dry run menu
dry_run_menu() {
    while true; do
        echo -e "${YELLOW}=== DRY RUN MODE ===${NC}"
        echo "Choose operation to preview:"
        echo "1) Android → Termux"
        echo "2) Termux → Oracle"
        echo "3) Full Workflow"
        echo "4) Termux → Android"
        echo "5) Oracle → Termux"
        echo "6) Back to main menu"
        echo ""
        read -p "Enter choice (1-6): " dry_choice
        
        case $dry_choice in
            1) android_to_termux "true" ;;
            2) termux_to_oracle "true" ;;
            3) full_sync_workflow "true" ;;
            4) termux_to_android "true" ;;
            5) oracle_to_termux "true" ;;
            6) break ;;
            *) echo -e "${RED}Invalid choice${NC}" ;;
        esac
        echo ""
        read -p "Press Enter to continue..."
    done
}

# Main execution
main() {
    # Initialize
    check_and_create_dirs
    
    while true; do
        show_menu
        read -p "Enter your choice (1-13): " choice
        echo ""
        
        case $choice in
            1) android_to_termux ;;
            2) termux_to_oracle ;;
            3) full_sync_workflow ;;
            4) termux_to_android ;;
            5) oracle_to_termux ;;
            6) android_to_oracle ;;
            7) oracle_to_android ;;
            8) show_status ;;
            9) create_backup ;;
            10) test_oracle_connection ;;
            11) show_recent_logs ;;
            12) dry_run_menu ;;
            13) 
                echo -e "${GREEN}Thanks for using ProBiz File Manager!${NC}"
                log_message "Session ended"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid choice. Please try again.${NC}"
                ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
    done
}

# Run the script
main

