#!/bin/bash

# Copy Programs Menu Script
# -------------------------
# Provides a simple menu to run your copy scripts (in execs/)
# or edit your directories.conf (in the NewBiz root), regardless
# of where you invoke this script from.

# 1) Figure out where this script lives:
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 2) If it's inside execs/, back out one level to the NewBiz root:
if [[ "$(basename "$SCRIPT_DIR")" == "execs" ]]; then
    BASE_DIR="$(dirname "$SCRIPT_DIR")"
else
    BASE_DIR="$SCRIPT_DIR"
fi

# 3) Define your menu items: "filename:Description"
menu_items=(
    "bulk_copy2or.sh:Bulk copy current directory to Oracle"
    "bulk_copy_silent2or.sh:Silent bulk copy to Oracle"
    "copy2nb.sh:Copy files to Termux from Android"
    "copy2or.sh:Copy files to Oracle from Termux"
    "copy_file.sh:Single directory or file copy bidirectional NB↔OR"
    "copyfile2nb.sh:Copy single file to Termux from Android"
    "copynbto.sh:Auto copy from Android → NB → OR"
    "copyonefile.sh:Copy a single file from Android Termux Oracle "
    "directories.conf:Edit directory configuration"
)

# 4) (Optional) Color codes for nicer menu display
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'  # No Color

# Function to display the menu
show_menu() {
    clear
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}    Copy Programs Menu${NC}"
    echo -e "${BLUE}================================${NC}"
    echo
    for i in "${!menu_items[@]}"; do
        IFS=':' read -r filename description <<< "${menu_items[$i]}"
        printf "${GREEN}%2d)${NC} %-25s ${YELLOW}%s${NC}\n" $((i+1)) "$filename" "$description"
    done
    echo
    echo -e "${GREEN} 0)${NC} Exit"
    echo
    echo -e "${BLUE}================================${NC}"
}

# Function to handle the user's choice
execute_program() {
    local filename="$1"

    echo -e "\n${YELLOW}>>> Processing: $filename${NC}"
    echo "================================"

    if [[ "$filename" == "directories.conf" ]]; then
        # --- Special case: config file lives in BASE_DIR, not in execs/
        config_path="$BASE_DIR/directories.conf"
        if [[ -f "$config_path" ]]; then
            nano "$config_path"
        else
            echo -e "${RED}Note: $config_path not found. Creating it now.${NC}"
            touch "$config_path"
            nano "$config_path"
        fi
    else
        # --- All other scripts live under BASE_DIR/execs/
        script_path="$BASE_DIR/execs/$filename"
        if [[ -f "$script_path" ]]; then
            # Make sure it's executable
            if [[ ! -x "$script_path" ]]; then
                echo -e "${YELLOW}Making $script_path executable...${NC}"
                chmod +x "$script_path"
            fi
            # Run it
            "$script_path"
        else
            echo -e "${RED}Error: $script_path not found.${NC}"
        fi
    fi

    echo
    echo -e "${BLUE}================================${NC}"
    echo -e "${YELLOW}Press Enter to return to the menu...${NC}"
    read -r
}

# Main loop
main() {
    while true; do
        show_menu
        echo -n "Enter your choice (0-${#menu_items[@]}): "
        read -r choice

        if [[ "$choice" =~ ^[0-9]+$ ]]; then
            if (( choice == 0 )); then
                echo -e "\n${GREEN}Goodbye!${NC}"
                exit 0
            elif (( choice >= 1 && choice <= ${#menu_items[@]} )); then
                IFS=':' read -r filename _ <<< "${menu_items[$((choice-1))]}"
                execute_program "$filename"
            else
                echo -e "\n${RED}Invalid choice. Please try again.${NC}"
                sleep 1
            fi
        else
            echo -e "\n${RED}Please enter a number.${NC}"
            sleep 1
        fi
    done
}

# Kick things off
main
