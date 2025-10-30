#!/bin/bash

# ng.sh - Nginx Management Menu Script
# Make executable with: chmod +x ng.sh

# Color codes for better visual output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_color() {
    echo -e "${1}${2}${NC}"
}

# Function to check if nginx is installed
check_nginx() {
    if ! command -v nginx &> /dev/null; then
        print_color $RED "Error: nginx is not installed or not in PATH"
        return 1
    fi
    return 0
}

# Function to check if running as root/sudo for privileged operations
check_privileges() {
    if [[ $EUID -ne 0 ]]; then
        print_color $YELLOW "Note: Some operations may require sudo privileges"
    fi
}

# Function to pause and wait for user input
pause() {
    print_color $CYAN "\nPress Enter to continue..."
    read -r
}

# Function to start nginx
start_nginx() {
    print_color $BLUE "Starting nginx..."
    if sudo systemctl start nginx 2>/dev/null || sudo service nginx start 2>/dev/null || sudo nginx; then
        print_color $GREEN "✓ Nginx started successfully"
    else
        print_color $RED "✗ Failed to start nginx"
    fi
    pause
}

# Function to stop nginx
stop_nginx() {
    print_color $BLUE "Stopping nginx..."
    if sudo systemctl stop nginx 2>/dev/null || sudo service nginx stop 2>/dev/null || sudo nginx -s quit; then
        print_color $GREEN "✓ Nginx stopped successfully"
    else
        print_color $RED "✗ Failed to stop nginx"
    fi
    pause
}

# Function to restart nginx
restart_nginx() {
    print_color $BLUE "Restarting nginx..."
    if sudo systemctl restart nginx 2>/dev/null || sudo service nginx restart 2>/dev/null; then
        print_color $GREEN "✓ Nginx restarted successfully"
    else
        print_color $RED "✗ Failed to restart nginx"
    fi
    pause
}

# Function to reload nginx configuration
reload_nginx() {
    print_color $BLUE "Reloading nginx configuration..."
    if sudo systemctl reload nginx 2>/dev/null || sudo service nginx reload 2>/dev/null || sudo nginx -s reload; then
        print_color $GREEN "✓ Nginx configuration reloaded successfully"
    else
        print_color $RED "✗ Failed to reload nginx configuration"
    fi
    pause
}

# Function to check nginx status
status_nginx() {
    print_color $BLUE "Checking nginx status..."
    echo
    
    # Try systemctl first, then service, then manual check
    if systemctl is-active nginx &>/dev/null; then
        systemctl status nginx --no-pager
    elif service nginx status &>/dev/null; then
        service nginx status
    else
        # Manual process check
        if pgrep nginx > /dev/null; then
            print_color $GREEN "✓ Nginx is running"
            echo "Process details:"
            ps aux | grep nginx | grep -v grep
        else
            print_color $RED "✗ Nginx is not running"
        fi
    fi
    pause
}

# Function to test nginx configuration
test_config() {
    print_color $BLUE "Testing nginx configuration..."
    echo
    if sudo nginx -t; then
        print_color $GREEN "✓ Configuration test passed"
    else
        print_color $RED "✗ Configuration test failed"
    fi
    pause
}

# Function to show nginx version and build info
show_version() {
    print_color $BLUE "Nginx version and build information:"
    echo
    nginx -V
    pause
}

# Function to view nginx error log
view_error_log() {
    print_color $BLUE "Viewing nginx error log..."
    echo
    
    # Common error log locations
    ERROR_LOGS=(
        "/var/log/nginx/error.log"
        "/usr/local/nginx/logs/error.log"
        "/etc/nginx/logs/error.log"
    )
    
    LOG_FOUND=false
    for log in "${ERROR_LOGS[@]}"; do
        if [[ -f "$log" ]]; then
            print_color $GREEN "Found error log: $log"
            echo
            read -p "How many lines to show? (default: 50): " lines
            lines=${lines:-50}
            echo
            sudo tail -n "$lines" "$log"
            LOG_FOUND=true
            break
        fi
    done
    
    if [[ "$LOG_FOUND" == false ]]; then
        print_color $RED "Error log not found in common locations"
        echo "Try checking: /var/log/nginx/ or your custom log path"
    fi
    pause
}

# Function to view nginx access log
view_access_log() {
    print_color $BLUE "Viewing nginx access log..."
    echo
    
    # Common access log locations
    ACCESS_LOGS=(
        "/var/log/nginx/access.log"
        "/usr/local/nginx/logs/access.log"
        "/etc/nginx/logs/access.log"
    )
    
    LOG_FOUND=false
    for log in "${ACCESS_LOGS[@]}"; do
        if [[ -f "$log" ]]; then
            print_color $GREEN "Found access log: $log"
            echo
            read -p "How many lines to show? (default: 50): " lines
            lines=${lines:-50}
            echo
            sudo tail -n "$lines" "$log"
            LOG_FOUND=true
            break
        fi
    done
    
    if [[ "$LOG_FOUND" == false ]]; then
        print_color $RED "Access log not found in common locations"
        echo "Try checking: /var/log/nginx/ or your custom log path"
    fi
    pause
}

# Function to edit main nginx configuration
edit_main_config() {
    print_color $BLUE "Opening main nginx configuration file..."
    
    # Common nginx.conf locations
    CONFIG_PATHS=(
        "/etc/nginx/nginx.conf"
        "/usr/local/nginx/conf/nginx.conf"
        "/usr/local/etc/nginx/nginx.conf"
    )
    
    CONFIG_FOUND=false
    for config in "${CONFIG_PATHS[@]}"; do
        if [[ -f "$config" ]]; then
            print_color $GREEN "Found config: $config"
            
            # Determine available editor
            if command -v nano &> /dev/null; then
                EDITOR="nano"
            elif command -v vim &> /dev/null; then
                EDITOR="vim"
            elif command -v vi &> /dev/null; then
                EDITOR="vi"
            else
                print_color $RED "No suitable editor found (nano, vim, or vi)"
                pause
                return
            fi
            
            print_color $YELLOW "Opening with $EDITOR..."
            sudo "$EDITOR" "$config"
            CONFIG_FOUND=true
            break
        fi
    done
    
    if [[ "$CONFIG_FOUND" == false ]]; then
        print_color $RED "Main nginx configuration not found in common locations"
    fi
    pause
}

# Function to list and edit site configurations
edit_site_config() {
    print_color $BLUE "Available site configurations:"
    echo
    
    # Common sites directories
    SITES_DIRS=(
        "/etc/nginx/sites-available"
        "/etc/nginx/conf.d"
        "/usr/local/nginx/conf/sites-available"
    )
    
    SITES_FOUND=false
    for sites_dir in "${SITES_DIRS[@]}"; do
        if [[ -d "$sites_dir" ]]; then
            print_color $GREEN "Found sites directory: $sites_dir"
            echo
            
            # List configuration files
            configs=($(find "$sites_dir" -name "*.conf" -o -name "*" -type f 2>/dev/null | head -20))
            
            if [[ ${#configs[@]} -eq 0 ]]; then
                print_color $YELLOW "No configuration files found in $sites_dir"
                continue
            fi
            
            echo "Available configurations:"
            for i in "${!configs[@]}"; do
                basename_config=$(basename "${configs[$i]}")
                echo "  $((i+1)). $basename_config"
            done
            echo
            
            read -p "Enter the number of the config to edit (or 'q' to quit): " choice
            
            if [[ "$choice" == "q" ]]; then
                return
            fi
            
            if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 ]] && [[ "$choice" -le ${#configs[@]} ]]; then
                selected_config="${configs[$((choice-1))]}"
                
                # Determine available editor
                if command -v nano &> /dev/null; then
                    EDITOR="nano"
                elif command -v vim &> /dev/null; then
                    EDITOR="vim"
                elif command -v vi &> /dev/null; then
                    EDITOR="vi"
                else
                    print_color $RED "No suitable editor found (nano, vim, or vi)"
                    pause
                    return
                fi
                
                print_color $YELLOW "Opening $(basename "$selected_config") with $EDITOR..."
                sudo "$EDITOR" "$selected_config"
                SITES_FOUND=true
                break
            else
                print_color $RED "Invalid selection"
            fi
        fi
    done
    
    if [[ "$SITES_FOUND" == false ]]; then
        print_color $RED "No sites configuration directories found"
    fi
    pause
}

# Function to enable/disable sites (for Debian/Ubuntu style configs)
manage_sites() {
    print_color $BLUE "Site Management (Debian/Ubuntu style)"
    echo
    
    if [[ ! -d "/etc/nginx/sites-available" ]] || [[ ! -d "/etc/nginx/sites-enabled" ]]; then
        print_color $RED "This system doesn't appear to use sites-available/sites-enabled structure"
        pause
        return
    fi
    
    echo "1. Enable a site"
    echo "2. Disable a site"
    echo "3. List available sites"
    echo "4. List enabled sites"
    echo
    read -p "Choose an option (1-4): " site_choice
    
    case $site_choice in
        1)
            echo
            print_color $BLUE "Available sites to enable:"
            available_sites=($(ls /etc/nginx/sites-available/ 2>/dev/null))
            
            if [[ ${#available_sites[@]} -eq 0 ]]; then
                print_color $RED "No sites found in sites-available"
                pause
                return
            fi
            
            for i in "${!available_sites[@]}"; do
                echo "  $((i+1)). ${available_sites[$i]}"
            done
            echo
            read -p "Enter the number of the site to enable: " enable_choice
            
            if [[ "$enable_choice" =~ ^[0-9]+$ ]] && [[ "$enable_choice" -ge 1 ]] && [[ "$enable_choice" -le ${#available_sites[@]} ]]; then
                site_name="${available_sites[$((enable_choice-1))]}"
                if sudo ln -sf "/etc/nginx/sites-available/$site_name" "/etc/nginx/sites-enabled/$site_name"; then
                    print_color $GREEN "✓ Site '$site_name' enabled successfully"
                    print_color $YELLOW "Remember to reload nginx configuration"
                else
                    print_color $RED "✗ Failed to enable site '$site_name'"
                fi
            else
                print_color $RED "Invalid selection"
            fi
            ;;
        2)
            echo
            print_color $BLUE "Enabled sites to disable:"
            enabled_sites=($(ls /etc/nginx/sites-enabled/ 2>/dev/null))
            
            if [[ ${#enabled_sites[@]} -eq 0 ]]; then
                print_color $RED "No enabled sites found"
                pause
                return
            fi
            
            for i in "${!enabled_sites[@]}"; do
                echo "  $((i+1)). ${enabled_sites[$i]}"
            done
            echo
            read -p "Enter the number of the site to disable: " disable_choice
            
            if [[ "$disable_choice" =~ ^[0-9]+$ ]] && [[ "$disable_choice" -ge 1 ]] && [[ "$disable_choice" -le ${#enabled_sites[@]} ]]; then
                site_name="${enabled_sites[$((disable_choice-1))]}"
                if sudo rm "/etc/nginx/sites-enabled/$site_name"; then
                    print_color $GREEN "✓ Site '$site_name' disabled successfully"
                    print_color $YELLOW "Remember to reload nginx configuration"
                else
                    print_color $RED "✗ Failed to disable site '$site_name'"
                fi
            else
                print_color $RED "Invalid selection"
            fi
            ;;
        3)
            echo
            print_color $BLUE "Available sites:"
            ls -la /etc/nginx/sites-available/ 2>/dev/null || print_color $RED "No sites-available directory found"
            ;;
        4)
            echo
            print_color $BLUE "Enabled sites:"
            ls -la /etc/nginx/sites-enabled/ 2>/dev/null || print_color $RED "No sites-enabled directory found"
            ;;
        *)
            print_color $RED "Invalid option"
            ;;
    esac
    pause
}

# Function to show nginx processes and connections
show_processes() {
    print_color $BLUE "Nginx processes and connections:"
    echo
    
    print_color $CYAN "=== Nginx Processes ==="
    ps aux | grep nginx | grep -v grep
    echo
    
    print_color $CYAN "=== Active Connections ==="
    if command -v ss &> /dev/null; then
        ss -tlnp | grep nginx
    elif command -v netstat &> /dev/null; then
        netstat -tlnp | grep nginx
    else
        print_color $YELLOW "ss or netstat not available to show connections"
    fi
    
    pause
}

# Function to show disk usage of logs
show_log_usage() {
    print_color $BLUE "Nginx log disk usage:"
    echo
    
    LOG_DIRS=(
        "/var/log/nginx"
        "/usr/local/nginx/logs"
        "/etc/nginx/logs"
    )
    
    for log_dir in "${LOG_DIRS[@]}"; do
        if [[ -d "$log_dir" ]]; then
            print_color $GREEN "Log directory: $log_dir"
            du -sh "$log_dir"/* 2>/dev/null || echo "  (empty or no accessible files)"
            echo
        fi
    done
    
    pause
}

# Function to display the menu
show_menu() {
    clear
    print_color $CYAN "╔════════════════════════════════════╗"
    print_color $CYAN "║        NGINX MANAGEMENT MENU       ║"
    print_color $CYAN "╚════════════════════════════════════╝"
    echo
    print_color $GREEN "Service Control:"
    echo "  1.  Start nginx"
    echo "  2.  Stop nginx"
    echo "  3.  Restart nginx"
    echo "  4.  Reload configuration"
    echo "  5.  Check status"
    echo
    print_color $GREEN "Configuration:"
    echo "  6.  Test configuration"
    echo "  7.  Edit main config (nginx.conf)"
    echo "  8.  Edit site configuration"
    echo "  9.  Manage sites (enable/disable)"
    echo
    print_color $GREEN "Monitoring & Logs:"
    echo "  10. View error log"
    echo "  11. View access log"
    echo "  12. Show processes & connections"
    echo "  13. Show log disk usage"
    echo
    print_color $GREEN "Information:"
    echo "  14. Show nginx version"
    echo
    print_color $RED "  0.  Exit"
    echo
    print_color $BLUE "════════════════════════════════════"
}

# Main script execution
main() {
    # Check if nginx is installed
    if ! check_nginx; then
        exit 1
    fi
    
    # Check privileges
    check_privileges
    
    while true; do
        show_menu
        read -p "Enter your choice (0-14): " choice
        
        case $choice in
            1) start_nginx ;;
            2) stop_nginx ;;
            3) restart_nginx ;;
            4) reload_nginx ;;
            5) status_nginx ;;
            6) test_config ;;
            7) edit_main_config ;;
            8) edit_site_config ;;
            9) manage_sites ;;
            10) view_error_log ;;
            11) view_access_log ;;
            12) show_processes ;;
            13) show_log_usage ;;
            14) show_version ;;
            0) 
                print_color $GREEN "Goodbye!"
                exit 0
                ;;
            *)
                print_color $RED "Invalid option. Please try again."
                sleep 2
                ;;
        esac
    done
}

# Run the main function
main
