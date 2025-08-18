#!/bin/bash

# Proot Menu for Termux
# Make sure this script is executable: chmod +x proot_menu.sh

# Colors for better UI
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Function to display header
show_header() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${WHITE}                    PROOT MENU FOR TERMUX                     ${CYAN}║${NC}"
    echo -e "${CYAN}║${WHITE}                   Google Pixel Tablet Edition               ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Function to pause and wait for user input
pause() {
    echo ""
    echo -e "${YELLOW}Press Enter to continue...${NC}"
    read
}

# Function to check if proot is installed
check_proot() {
    if ! command -v proot &> /dev/null; then
        echo -e "${RED}Error: proot is not installed!${NC}"
        echo -e "${YELLOW}Please install it first: ${WHITE}pkg install proot${NC}"
        pause
        return 1
    fi
    return 0
}

# Function to install a Linux distribution
install_distro() {
    local distro=$1
    local distro_name=$2
    
    echo -e "${GREEN}Installing $distro_name...${NC}"
    echo -e "${YELLOW}This may take a while depending on your internet connection.${NC}"
    echo ""
    
    case $distro in
        "ubuntu")
            proot-distro install ubuntu
            ;;
        "debian")
            proot-distro install debian
            ;;
        "fedora")
            proot-distro install fedora
            ;;
        "opensuse")
            proot-distro install opensuse
            ;;
        "archlinux")
            proot-distro install archlinux
            ;;
        "alpine")
            proot-distro install alpine
            ;;
        "void")
            proot-distro install void
            ;;
        "manjaro")
            proot-distro install manjaro
            ;;
    esac
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $distro_name installed successfully!${NC}"
    else
        echo -e "${RED}✗ Failed to install $distro_name${NC}"
    fi
    pause
}

# Function to login to a distribution
login_distro() {
    local distro=$1
    local distro_name=$2
    
    echo -e "${GREEN}Logging into $distro_name...${NC}"
    echo -e "${YELLOW}Type 'exit' to return to this menu${NC}"
    echo ""
    
    proot-distro login $distro
    
    echo -e "${GREEN}Returned from $distro_name${NC}"
    pause
}

# Function to remove a distribution
remove_distro() {
    local distro=$1
    local distro_name=$2
    
    echo -e "${RED}Are you sure you want to remove $distro_name? (y/N)${NC}"
    read -r response
    
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo -e "${YELLOW}Removing $distro_name...${NC}"
        proot-distro remove $distro
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ $distro_name removed successfully!${NC}"
        else
            echo -e "${RED}✗ Failed to remove $distro_name${NC}"
        fi
    else
        echo -e "${YELLOW}Removal cancelled.${NC}"
    fi
    pause
}

# Function to list installed distributions
list_distros() {
    echo -e "${GREEN}Installed distributions:${NC}"
    echo ""
    proot-distro list
    echo ""
    echo -e "${BLUE}Available distributions:${NC}"
    echo ""
    proot-distro list --available
    pause
}

# Function to backup a distribution
backup_distro() {
    echo -e "${GREEN}Enter the name of the distribution to backup:${NC}"
    read -r distro
    
    if [ -z "$distro" ]; then
        echo -e "${RED}No distribution name provided!${NC}"
        pause
        return
    fi
    
    echo -e "${YELLOW}Creating backup of $distro...${NC}"
    echo -e "${YELLOW}This may take a while...${NC}"
    
    proot-distro backup --output-file "${distro}_backup_$(date +%Y%m%d_%H%M%S).tar.gz" $distro
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Backup created successfully!${NC}"
    else
        echo -e "${RED}✗ Failed to create backup${NC}"
    fi
    pause
}

# Function to restore a distribution
restore_distro() {
    echo -e "${GREEN}Available backup files:${NC}"
    ls -la *.tar.gz 2>/dev/null || echo -e "${YELLOW}No backup files found${NC}"
    echo ""
    
    echo -e "${GREEN}Enter the backup file path:${NC}"
    read -r backup_file
    
    if [ ! -f "$backup_file" ]; then
        echo -e "${RED}Backup file not found!${NC}"
        pause
        return
    fi
    
    echo -e "${GREEN}Enter the name for the restored distribution:${NC}"
    read -r distro_name
    
    if [ -z "$distro_name" ]; then
        echo -e "${RED}No distribution name provided!${NC}"
        pause
        return
    fi
    
    echo -e "${YELLOW}Restoring from backup...${NC}"
    proot-distro restore --input-file "$backup_file" $distro_name
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Distribution restored successfully!${NC}"
    else
        echo -e "${RED}✗ Failed to restore distribution${NC}"
    fi
    pause
}

# Function to show distribution management menu
distro_menu() {
    while true; do
        show_header
        echo -e "${WHITE}Distribution Management${NC}"
        echo -e "${CYAN}═══════════════════════${NC}"
        echo ""
        echo -e "${WHITE}1.${NC} Install Ubuntu"
        echo -e "${WHITE}2.${NC} Install Debian"
        echo -e "${WHITE}3.${NC} Install Fedora"
        echo -e "${WHITE}4.${NC} Install OpenSUSE"
        echo -e "${WHITE}5.${NC} Install Arch Linux"
        echo -e "${WHITE}6.${NC} Install Alpine Linux"
        echo -e "${WHITE}7.${NC} Install Void Linux"
        echo -e "${WHITE}8.${NC} Install Manjaro"
        echo ""
        echo -e "${WHITE}9.${NC} Login to Ubuntu"
        echo -e "${WHITE}10.${NC} Login to Debian"
        echo -e "${WHITE}11.${NC} Login to Fedora"
        echo -e "${WHITE}12.${NC} Login to OpenSUSE"
        echo -e "${WHITE}13.${NC} Login to Arch Linux"
        echo -e "${WHITE}14.${NC} Login to Alpine Linux"
        echo -e "${WHITE}15.${NC} Login to Void Linux"
        echo -e "${WHITE}16.${NC} Login to Manjaro"
        echo ""
        echo -e "${WHITE}17.${NC} Remove a Distribution"
        echo -e "${WHITE}18.${NC} List Distributions"
        echo -e "${WHITE}19.${NC} Back to Main Menu"
        echo ""
        echo -e "${GREEN}Enter your choice (1-19): ${NC}"
        read -r choice
        
        case $choice in
            1) install_distro "ubuntu" "Ubuntu" ;;
            2) install_distro "debian" "Debian" ;;
            3) install_distro "fedora" "Fedora" ;;
            4) install_distro "opensuse" "OpenSUSE" ;;
            5) install_distro "archlinux" "Arch Linux" ;;
            6) install_distro "alpine" "Alpine Linux" ;;
            7) install_distro "void" "Void Linux" ;;
            8) install_distro "manjaro" "Manjaro" ;;
            9) login_distro "ubuntu" "Ubuntu" ;;
            10) login_distro "debian" "Debian" ;;
            11) login_distro "fedora" "Fedora" ;;
            12) login_distro "opensuse" "OpenSUSE" ;;
            13) login_distro "archlinux" "Arch Linux" ;;
            14) login_distro "alpine" "Alpine Linux" ;;
            15) login_distro "void" "Void Linux" ;;
            16) login_distro "manjaro" "Manjaro" ;;
            17) 
                echo -e "${GREEN}Enter distribution name to remove:${NC}"
                read -r distro
                if [ ! -z "$distro" ]; then
                    remove_distro "$distro" "$distro"
                fi
                ;;
            18) list_distros ;;
            19) break ;;
            *) 
                echo -e "${RED}Invalid choice! Please try again.${NC}"
                pause
                ;;
        esac
    done
}

# Function to show advanced proot options
advanced_menu() {
    while true; do
        show_header
        echo -e "${WHITE}Advanced Proot Options${NC}"
        echo -e "${CYAN}══════════════════════${NC}"
        echo ""
        echo -e "${WHITE}1.${NC} Custom Proot Command"
        echo -e "${WHITE}2.${NC} Mount External Storage"
        echo -e "${WHITE}3.${NC} Run with Specific User"
        echo -e "${WHITE}4.${NC} Bind Mount Directory"
        echo -e "${WHITE}5.${NC} Set Working Directory"
        echo -e "${WHITE}6.${NC} Show Proot Help"
        echo -e "${WHITE}7.${NC} Back to Main Menu"
        echo ""
        echo -e "${GREEN}Enter your choice (1-7): ${NC}"
        read -r choice
        
        case $choice in
            1)
                echo -e "${GREEN}Enter your custom proot command:${NC}"
                echo -e "${YELLOW}Example: proot -r /data/data/com.termux/files/usr/var/lib/proot-distro/installed-rootfs/ubuntu${NC}"
                read -r custom_cmd
                if [ ! -z "$custom_cmd" ]; then
                    echo -e "${YELLOW}Executing: $custom_cmd${NC}"
                    eval $custom_cmd
                fi
                pause
                ;;
            2)
                echo -e "${GREEN}Mounting external storage...${NC}"
                echo -e "${YELLOW}This will mount your external storage to /mnt/external${NC}"
                proot -b /storage/emulated/0:/mnt/external -r /data/data/com.termux/files/usr
                pause
                ;;
            3)
                echo -e "${GREEN}Enter username to run as:${NC}"
                read -r username
                if [ ! -z "$username" ]; then
                    echo -e "${YELLOW}Running proot as user: $username${NC}"
                    proot -i $username
                fi
                pause
                ;;
            4)
                echo -e "${GREEN}Enter source directory:${NC}"
                read -r src_dir
                echo -e "${GREEN}Enter destination directory:${NC}"
                read -r dst_dir
                if [ ! -z "$src_dir" ] && [ ! -z "$dst_dir" ]; then
                    echo -e "${YELLOW}Binding $src_dir to $dst_dir${NC}"
                    proot -b $src_dir:$dst_dir
                fi
                pause
                ;;
            5)
                echo -e "${GREEN}Enter working directory:${NC}"
                read -r work_dir
                if [ ! -z "$work_dir" ]; then
                    echo -e "${YELLOW}Setting working directory to: $work_dir${NC}"
                    proot -w $work_dir
                fi
                pause
                ;;
            6)
                echo -e "${GREEN}Proot Help:${NC}"
                echo ""
                proot --help
                pause
                ;;
            7) break ;;
            *) 
                echo -e "${RED}Invalid choice! Please try again.${NC}"
                pause
                ;;
        esac
    done
}

# Function to show backup/restore menu
backup_menu() {
    while true; do
        show_header
        echo -e "${WHITE}Backup & Restore${NC}"
        echo -e "${CYAN}═══════════════${NC}"
        echo ""
        echo -e "${WHITE}1.${NC} Backup Distribution"
        echo -e "${WHITE}2.${NC} Restore Distribution"
        echo -e "${WHITE}3.${NC} List Backup Files"
        echo -e "${WHITE}4.${NC} Back to Main Menu"
        echo ""
        echo -e "${GREEN}Enter your choice (1-4): ${NC}"
        read -r choice
        
        case $choice in
            1) backup_distro ;;
            2) restore_distro ;;
            3) 
                echo -e "${GREEN}Available backup files:${NC}"
                ls -la *.tar.gz 2>/dev/null || echo -e "${YELLOW}No backup files found${NC}"
                pause
                ;;
            4) break ;;
            *) 
                echo -e "${RED}Invalid choice! Please try again.${NC}"
                pause
                ;;
        esac
    done
}

# Main menu function
main_menu() {
    while true; do
        show_header
        echo -e "${WHITE}Main Menu${NC}"
        echo -e "${CYAN}═════════${NC}"
        echo ""
        echo -e "${WHITE}1.${NC} Distribution Management"
        echo -e "${WHITE}2.${NC} Advanced Proot Options"
        echo -e "${WHITE}3.${NC} Backup & Restore"
        echo -e "${WHITE}4.${NC} Install proot-distro (if not installed)"
        echo -e "${WHITE}5.${NC} Check System Info"
        echo -e "${WHITE}6.${NC} Exit"
        echo ""
        echo -e "${GREEN}Enter your choice (1-6): ${NC}"
        read -r choice
        
        case $choice in
            1) distro_menu ;;
            2) advanced_menu ;;
            3) backup_menu ;;
            4) 
                echo -e "${YELLOW}Installing proot-distro...${NC}"
                pkg install proot-distro
                if [ $? -eq 0 ]; then
                    echo -e "${GREEN}✓ proot-distro installed successfully!${NC}"
                else
                    echo -e "${RED}✗ Failed to install proot-distro${NC}"
                fi
                pause
                ;;
            5) 
                echo -e "${GREEN}System Information:${NC}"
                echo ""
                echo -e "${YELLOW}Device:${NC} $(getprop ro.product.model)"
                echo -e "${YELLOW}Android Version:${NC} $(getprop ro.build.version.release)"
                echo -e "${YELLOW}Architecture:${NC} $(uname -m)"
                echo -e "${YELLOW}Termux Version:${NC} $(pkg list-installed | grep termux-tools)"
                echo -e "${YELLOW}Proot Version:${NC} $(proot --version 2>/dev/null || echo 'Not installed')"
                echo -e "${YELLOW}Available Space:${NC} $(df -h $HOME | tail -1 | awk '{print $4}')"
                pause
                ;;
            6) 
                echo -e "${GREEN}Thank you for using Proot Menu!${NC}"
                echo -e "${YELLOW}Happy Linux-ing on your Pixel Tablet! 🐧${NC}"
                exit 0
                ;;
            *) 
                echo -e "${RED}Invalid choice! Please try again.${NC}"
                pause
                ;;
        esac
    done
}

# Main execution
if ! check_proot; then
    exit 1
fi

# Check if proot-distro is installed
if ! command -v proot-distro &> /dev/null; then
    echo -e "${YELLOW}proot-distro is not installed. Would you like to install it? (y/N)${NC}"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        pkg install proot-distro
    fi
fi

# Start the main menu
main_menu