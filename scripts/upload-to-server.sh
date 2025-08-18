#!/data/data/com.termux/files/usr/bin/bash

# Upload script for Termux to Oracle server - Updated for your directory structure
TERMUX_DEV_DIR="$HOME/ProBiz"  # Your actual ProBiz directory
SERVER_ALIAS="oracle-instance-probiz"
SERVER_UPLOAD_DIR="/home/opc/uploads"
SERVER_PROBIZ_DIR="/home/opc/ProBiz"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to display current directory structure
show_structure() {
    echo -e "${BLUE}Current ProBiz structure in Termux:${NC}"
    if [ -d "$TERMUX_DEV_DIR" ]; then
        tree "$TERMUX_DEV_DIR" 2>/dev/null || find "$TERMUX_DEV_DIR" -type d | head -20
    else
        echo -e "${RED}ProBiz directory not found at $TERMUX_DEV_DIR${NC}"
        echo "Creating directory structure..."
        mkdir -p "$TERMUX_DEV_DIR"/{websites,nodejs,shared,scripts,logs,docs}
        mkdir -p "$TERMUX_DEV_DIR/websites"/{main,projects,games}
        mkdir -p "$TERMUX_DEV_DIR/nodejs"/{api-server,websocket-apps,utilities}
        mkdir -p "$TERMUX_DEV_DIR/shared"/{css,js,images,templates}
        echo -e "${GREEN}✅ Directory structure created${NC}"
    fi
}

# Function to display usage
usage() {
    echo "Usage: $0 [option] [project-name]"
    echo "Options:"
    echo "  website <name>    - Upload website project"
    echo "  nodejs <name>     - Upload Node.js project"
    echo "  game <name>       - Upload game project"
    echo "  shared            - Upload shared resources"
    echo "  all               - Upload everything"
    echo "  deploy <website>  - Upload and deploy specific website"
    echo "  status            - Show current directory structure"
    echo "  sync              - Sync entire ProBiz directory"
    echo ""
    echo "Examples:"
    echo "  $0 website main"
    echo "  $0 nodejs api-server"
    echo "  $0 game puzzle-game"
    echo "  $0 deploy main"
    echo "  $0 sync"
}

# Function to check if file/directory exists
check_exists() {
    if [ ! -e "$1" ]; then
        echo -e "${RED}Error: $1 does not exist${NC}"
        return 1
    fi
    return 0
}

# Function to test server connection
test_connection() {
    echo -e "${BLUE}Testing connection to server...${NC}"
    if ssh -o ConnectTimeout=10 $SERVER_ALIAS "echo 'Connection successful'" 2>/dev/null; then
        echo -e "${GREEN}✅ Server connection OK${NC}"
        return 0
    else
        echo -e "${RED}❌ Cannot connect to server${NC}"
        echo "Check your SSH configuration and server status"
        return 1
    fi
}

# Function to upload website
upload_website() {
    local website_name="$1"
    local local_path="$TERMUX_DEV_DIR/websites/$website_name"
    
    if ! check_exists "$local_path"; then
        echo "Available websites:"
        ls "$TERMUX_DEV_DIR/websites/" 2>/dev/null || echo "No websites found"
        return 1
    fi
    
    echo -e "${BLUE}Uploading website: $website_name${NC}"
    echo -e "${YELLOW}Source: $local_path${NC}"
    
    # Test connection first
    if ! test_connection; then
        return 1
    fi
    
    # Create remote directory structure
    ssh $SERVER_ALIAS "mkdir -p $SERVER_UPLOAD_DIR/websites/$website_name"
    
    # Upload files with progress
    echo "Uploading files..."
    scp -r "$local_path"/* $SERVER_ALIAS:$SERVER_UPLOAD_DIR/websites/$website_name/
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Website $website_name uploaded successfully${NC}"
        
        # Organize files on server
        ssh $SERVER_ALIAS "$SERVER_PROBIZ_DIR/scripts/upload-from-termux.sh websites $website_name"
        return 0
    else
        echo -e "${RED}❌ Upload failed${NC}"
        return 1
    fi
}

# Function to upload Node.js project
upload_nodejs() {
    local project_name="$1"
    local local_path="$TERMUX_DEV_DIR/nodejs/$project_name"
    
    if ! check_exists "$local_path"; then
        echo "Available Node.js projects:"
        ls "$TERMUX_DEV_DIR/nodejs/" 2>/dev/null || echo "No Node.js projects found"
        return 1
    fi
    
    echo -e "${BLUE}Uploading Node.js project: $project_name${NC}"
    
    if ! test_connection; then
        return 1
    fi
    
    ssh $SERVER_ALIAS "mkdir -p $SERVER_UPLOAD_DIR/nodejs/$project_name"
    scp -r "$local_path"/* $SERVER_ALIAS:$SERVER_UPLOAD_DIR/nodejs/$project_name/
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Node.js project $project_name uploaded successfully${NC}"
        ssh $SERVER_ALIAS "$SERVER_PROBIZ_DIR/scripts/upload-from-termux.sh nodejs $project_name"
        return 0
    else
        echo -e "${RED}❌ Upload failed${NC}"
        return 1
    fi
}

# Function to upload game
upload_game() {
    local game_name="$1"
    local local_path="$TERMUX_DEV_DIR/websites/games/$game_name"
    
    if ! check_exists "$local_path"; then
        echo "Available games:"
        ls "$TERMUX_DEV_DIR/websites/games/" 2>/dev/null || echo "No games found"
        return 1
    fi
    
    echo -e "${BLUE}Uploading game: $game_name${NC}"
    
    if ! test_connection; then
        return 1
    fi
    
    ssh $SERVER_ALIAS "mkdir -p $SERVER_UPLOAD_DIR/websites/games/$game_name"
    scp -r "$local_path"/* $SERVER_ALIAS:$SERVER_UPLOAD_DIR/websites/games/$game_name/
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Game $game_name uploaded successfully${NC}"
        ssh $SERVER_ALIAS "$SERVER_PROBIZ_DIR/scripts/upload-from-termux.sh games $game_name"
        return 0
    else
        echo -e "${RED}❌ Upload failed${NC}"
        return 1
    fi
}

# Function to sync entire ProBiz directory
sync_probiz() {
    echo -e "${BLUE}Syncing entire ProBiz directory...${NC}"
    echo -e "${YELLOW}This will upload everything in $TERMUX_DEV_DIR${NC}"
    echo -e "${YELLOW}Continue? (y/N)${NC}"
    read -r confirm
    
    if [[ $confirm =~ ^[Yy]$ ]]; then
        if ! test_connection; then
            return 1
        fi
        
        # Create base upload directory
        ssh $SERVER_ALIAS "mkdir -p $SERVER_UPLOAD_DIR"
        
        # Sync the entire directory structure
        echo "Syncing directory structure..."
        rsync -avz --progress "$TERMUX_DEV_DIR"/ $SERVER_ALIAS:$SERVER_UPLOAD_DIR/
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Directory sync completed${NC}"
            
            # Organize everything on server
            ssh $SERVER_ALIAS "$SERVER_PROBIZ_DIR/scripts/upload-from-termux.sh"
            echo -e "${GREEN}🚀 All files organized on server${NC}"
        else
            echo -e "${RED}❌ Sync failed${NC}"
        fi
    else
        echo "Sync cancelled"
    fi
}

# Function to upload shared resources
upload_shared() {
    echo -e "${BLUE}Uploading shared resources${NC}"
    
    if ! test_connection; then
        return 1
    fi
    
    ssh $SERVER_ALIAS "mkdir -p $SERVER_UPLOAD_DIR/shared"
    scp -r "$TERMUX_DEV_DIR/shared"/* $SERVER_ALIAS:$SERVER_UPLOAD_DIR/shared/
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Shared resources uploaded successfully${NC}"
        ssh $SERVER_ALIAS "$SERVER_PROBIZ_DIR/scripts/upload-from-termux.sh shared"
        return 0
    else
        echo -e "${RED}❌ Upload failed${NC}"
        return 1
    fi
}

# Function to deploy website (upload + deploy)
deploy_website() {
    local website_name="$1"
    
    if upload_website "$website_name"; then
        echo -e "${BLUE}Deploying website: $website_name${NC}"
        ssh $SERVER_ALIAS "$SERVER_PROBIZ_DIR/scripts/deploy.sh $website_name"
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}🚀 Website $website_name deployed successfully!${NC}"
            echo -e "${BLUE}Visit: http://144.24.7.55${NC}"
        else
            echo -e "${RED}❌ Deployment failed${NC}"
        fi
    fi
}

# Main script logic
case "$1" in
    "website")
        if [ -z "$2" ]; then
            echo "Please specify website name"
            usage
            exit 1
        fi
        upload_website "$2"
        ;;
    "nodejs")
        if [ -z "$2" ]; then
            echo "Please specify Node.js project name"
            usage
            exit 1
        fi
        upload_nodejs "$2"
        ;;
    "game")
        if [ -z "$2" ]; then
            echo "Please specify game name"
            usage
            exit 1
        fi
        upload_game "$2"
        ;;
    "shared")
        upload_shared
        ;;
    "deploy")
        if [ -z "$2" ]; then
            echo "Please specify website name to deploy"
            usage
            exit 1
        fi
        deploy_website "$2"
        ;;
    "sync")
        sync_probiz
        ;;
    "status")
        show_structure
        ;;
    "all")
        echo -e "${BLUE}Uploading all projects...${NC}"
        
        if ! test_connection; then
            exit 1
        fi
        
        # Upload shared resources first
        if [ -d "$TERMUX_DEV_DIR/shared" ]; then
            upload_shared
        fi
        
        # Upload all websites
        if [ -d "$TERMUX_DEV_DIR/websites" ]; then
            for website in $(ls "$TERMUX_DEV_DIR/websites/" 2>/dev/null); do
                if [ -d "$TERMUX_DEV_DIR/websites/$website" ] && [ "$website" != "games" ]; then
                    upload_website "$website"
                fi
            done
        fi
        
        # Upload all games
        if [ -d "$TERMUX_DEV_DIR/websites/games" ]; then
            for game in $(ls "$TERMUX_DEV_DIR/websites/games/" 2>/dev/null); do
                if [ -d "$TERMUX_DEV_DIR/websites/games/$game" ]; then
                    upload_game "$game"
                fi
            done
        fi
        
        # Upload all Node.js projects
        if [ -d "$TERMUX_DEV_DIR/nodejs" ]; then
            for nodejs in $(ls "$TERMUX_DEV_DIR/nodejs/" 2>/dev/null); do
                if [ -d "$TERMUX_DEV_DIR/nodejs/$nodejs" ]; then
                    upload_nodejs "$nodejs"
                fi
            done
        fi
        
        echo -e "${GREEN}✅ All uploads completed${NC}"
        ;;
    *)
        usage
        exit 1
        ;;
esac

