#!/data/data/com.termux/files/usr/bin/bash

# Development helper script - Updated for your ProBiz directory
DEV_DIR="/data/data/com.termux/files/home/ProBiz"  # Your actual path

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to ensure directory structure exists
ensure_structure() {
    local dirs=(
        "$DEV_DIR/websites/main/public"
        "$DEV_DIR/websites/main/src"
        "$DEV_DIR/websites/main/config"
        "$DEV_DIR/websites/projects"
        "$DEV_DIR/websites/games"
        "$DEV_DIR/nodejs/api-server"
        "$DEV_DIR/nodejs/websocket-apps"
        "$DEV_DIR/nodejs/utilities"
        "$DEV_DIR/shared/css"
        "$DEV_DIR/shared/js"
        "$DEV_DIR/shared/images"
        "$DEV_DIR/shared/templates"
        "$DEV_DIR/scripts"
        "$DEV_DIR/logs"
        "$DEV_DIR/docs"
        "$DEV_DIR/backups"
    )
    
    for dir in "${dirs[@]}"; do
        mkdir -p "$dir"
    done
}

# Function to create new project structure
new_project() {
    local type="$1"
    local name="$2"
    
    # Ensure base structure exists
    ensure_structure
    
    case "$type" in
        "website")
            local project_dir="$DEV_DIR/websites/$name"
            mkdir -p "$project_dir"/{public,src,config}
            mkdir -p "$project_dir/public"/{css,js,images}
            
            # Create basic index.html
            cat > "$project_dir/public/index.html" << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$name</title>
    <link rel="stylesheet" href="css/style.css">
    <link rel="stylesheet" href="/shared/css/common.css">
</head>
<body>
    <header>
        <h1>Welcome to $name</h1>
    </header>
    <main>
        <p>Project created on $(date)</p>
        <p>Ready for development!</p>
    </main>
    <footer>
        <p>&copy; $(date +%Y) ProBiz Projects</p>
    </footer>
    
    <script src="/shared/js/common.js"></script>
    <script src="js/main.js"></script>
</body>
</html>
EOF
            
            # Create basic CSS
            cat > "$project_dir/public/css/style.css" << EOF
/* $name specific styles */
:root {
    --primary-color: #007bff;
    --secondary-color: #6c757d;
    --success-color: #28a745;
    --danger-color: #dc3545;
    --warning-color: #ffc107;
    --info-color: #17a2b8;
    --light-color: #f8f9fa;
    --dark-color: #343a40;
}

* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
}

body {
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
    line-height: 1.6;
    color: var(--dark-color);
    background-color: var(--light-color);
}

header {
    background: linear-gradient(135deg, var(--primary-color), var(--info-color));
    color: white;
    text-align: center;
    padding: 2rem 0;
    margin-bottom: 2rem;
}

header h1 {
    font-size: 2.5rem;
    text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
}

main {
    max-width: 1200px;
    margin: 0 auto;
    padding: 0 2rem;
}

footer {
    background-color: var(--dark-color);
    color: white;
    text-align: center;
    padding: 1rem 0;
    margin-top: 3rem;
}

/* Responsive design */
@media (max-width: 768px) {
    header h1 {
        font-size: 2rem;
    }
    
    main {
        padding: 0 1rem;
    }
}
EOF
            
            # Create basic JS
            cat > "$project_dir/public/js/main.js" << EOF
// $name main JavaScript
console.log('$name loaded successfully');

class ${name}App {
    constructor() {
        this.initializeApp();
    }
    
    initializeApp() {
        console.log('Initializing $name application...');
        this.setupEventListeners();
        this.loadContent();
    }
    
    setupEventListeners() {
        // Add your event listeners here
        document.addEventListener('DOMContentLoaded', () => {
            console.log('DOM fully loaded for $name');
        });
    }
    
    loadContent() {
        // Load dynamic content here
        console.log('Loading content for $name');
    }
}

// Initialize the application
const app = new ${name}App();
EOF

            # Create config file
            cat > "$project_dir/config/config.json" << EOF
{
    "project": {
        "name": "$name",
        "version": "1.0.0",
        "description": "$name website project",
        "created": "$(date -I)",
        "type": "website"
    },
    "build": {
        "publicDir": "public",
        "sourceDir": "src"
    },
    "deployment": {
        "target": "oracle-server",
        "path": "/home/opc/ProBiz/websites/$name"
    }
}
EOF
            echo -e "${GREEN}✅ Website project '$name' created${NC}"
            echo -e "${BLUE}Location: $project_dir${NC}"
            ;;
            
        "game")
            local game_dir="$DEV_DIR/websites/games/$name"
            mkdir -p "$game_dir"/{assets,src,config}
            mkdir -p "$game_dir/assets"/{images,sounds,data}
            
            # Create basic game HTML
            cat > "$game_dir/index.html" << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$name Game</title>
    <style>
        body {
            margin: 0;
            padding: 20px;
            font-family: Arial, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            text-align: center;
        }
        
        .game-container {
            max-width: 900px;
            margin: 0 auto;
        }
        
        #gameCanvas {
            border: 3px solid #fff;
            border-radius: 10px;
            background: #000;
            box-shadow: 0 10px 30px rgba(0,0,0,0.3);
        }
        
        .controls {
            margin-top: 20px;
        }
        
        button {
            background: #4CAF50;
            color: white;
            border: none;
            padding: 10px 20px;
            margin: 5px;
            border-radius: 5px;
            cursor: pointer;
            font-size: 16px;
        }
        
        button:hover {
            background: #45a049;
        }
        
        .score {
            font-size: 24px;
            margin: 10px 0;
        }
    </style>
</head>
<body>
    <div class="game-container">
        <h1>$name</h1>
        <div class="score">Score: <span id="score">0</span></div>
        <canvas id="gameCanvas" width="800" height="600"></canvas>
        <div class="controls">
            <button onclick="game.start()">Start Game</button>
            <button onclick="game.pause()">Pause</button>
            <button onclick="game.reset()">Reset</button>
        </div>
        <div class="instructions">
            <p>Use arrow keys or WASD to move</p>
        </div>
    </div>
    
    <script src="src/game.js"></script>
</body>
</html>
EOF
            
            # Create game logic
            cat > "$game_dir/src/game.js" << EOF
// $name Game Logic
class ${name}Game {
    constructor() {
        this.canvas = document.getElementById('gameCanvas');
        this.ctx = this.canvas.getContext('2d');
        this.score = 0;
        this.gameRunning = false;
        this.gameLoop = null;
        
        this.setupControls();
        this.init();
    }
    
    init() {
        console.log('$name game initialized');
        this.reset();
    }
    
    setupControls() {
        document.addEventListener('keydown', (e) => {
            this.handleKeyPress(e.key);
        });
    }
    
    handleKeyPress(key) {
        if (!this.gameRunning) return;
        
        switch(key) {
            case 'ArrowUp':
            case 'w':
            case 'W':
                this.moveUp();
                break;
            case 'ArrowDown':
            case 's':
            case 'S':
                this.moveDown();
                break;
            case 'ArrowLeft':
            case 'a':
            case 'A':
                this.moveLeft();
                break;
            case 'ArrowRight':
            case 'd':
            case 'D':
                this.moveRight();
                break;
        }
    }
    
    moveUp() { console.log('Moving up'); }
    moveDown() { console.log('Moving down'); }
    moveLeft() { console.log('Moving left'); }
    moveRight() { console.log('Moving right'); }
    
    start() {
        if (this.gameRunning) return;
        
        this.gameRunning = true;
        console.log('Starting $name game');
        this.gameLoop = setInterval(() => this.update(), 1000/60); // 60 FPS
    }
    
    pause() {
        this.gameRunning = !this.gameRunning;
        if (this.gameRunning) {
            this.gameLoop = setInterval(() => this.update(), 1000/60);
        } else {
            clearInterval(this.gameLoop);
        }
        console.log('Game paused:', !this.gameRunning);
    }
    
    reset() {
        this.gameRunning = false;
        if (this.gameLoop) {
            clearInterval(this.gameLoop);
        }
        this.score = 0;
        this.updateScore();
        this.draw();
        console.log('Game reset');
    }
    
    update() {
        if (!this.gameRunning) return;
        
        // Game logic goes here
        this.draw();
    }
    
    draw() {
        // Clear canvas
        this.ctx.fillStyle = '#000033';
        this.ctx.fillRect(0, 0, this.canvas.width, this.canvas.height);
        
        // Draw game elements
        this.ctx.fillStyle = '#00ff00';
        this.ctx.fillRect(50, 50, 100, 100);
        
        // Draw text
        this.ctx.fillStyle = '#ffffff';
        this.ctx.font = '20px Arial';
        this.ctx.textAlign = 'center';
        this.ctx.fillText('$name Game', this.canvas.width/2, 50);
        
        if (!this.gameRunning) {
            this.ctx.fillText('Press Start to Play', this.canvas.width/2, this.canvas.height/2);
        }
    }
    
    updateScore() {
        document.getElementById('score').textContent = this.score;
    }
    
    addScore(points) {
        this.score += points;
        this.updateScore();
    }
}

// Initialize the game
const game = new ${name}Game();
EOF

            # Create game config
            cat > "$game_dir/config/game-config.json" << EOF
{
    "game": {
        "name": "$name",
        "version": "1.0.0",
        "type": "html5-canvas-game",
        "created": "$(date -I)"
    },
    "settings": {
        "canvasWidth": 800,
        "canvasHeight": 600,
        "fps": 60,
        "difficulty": "normal"
    },
    "controls": {
        "movement": ["arrow-keys", "wasd"],
        "actions": ["space", "enter"]
    }
}
EOF
            echo -e "${GREEN}✅ Game project '$name' created${NC}"
            echo -e "${BLUE}Location: $game_dir${NC}"
            ;;
            
        "nodejs")
            local node_dir="$DEV_DIR/nodejs/$name"
            mkdir -p "$node_dir"/{src,config,tests,public}
            
            # Create package.json
            cat > "$node_dir/package.json" << EOF
{
    "name": "$name",
    "version": "1.0.0",
    "description": "$name Node.js project for ProBiz",
    "main": "src/index.js",
    "scripts": {
        "start": "node src/index.js",
        "dev": "nodemon src/index.js",
        "test": "echo \"Error: no test specified\" && exit 1"
    },
    "dependencies": {
        "express": "^4.18.0",
        "cors": "^2.8.5",
        "dotenv": "^16.0.0"
    },
    "devDependencies": {
        "nodemon": "^2.0.0"
    },
    "author": "ProBiz Developer",
    "license": "MIT"
}
EOF
            
            # Create main server file
            cat > "$node_dir/src/index.js" << EOF
// $name Node.js Server
const express = require('express');
const cors = require('cors');
const path = require('path');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(express.static('public'));

// Routes
app.get('/', (req, res) => {
    res.json({ 
        message: 'Welcome to $name API',
        version: '1.0.0',
        status: 'running',
        timestamp: new Date().toISOString()
    });
});

app.get('/api/health', (req, res) => {
    res.json({ 
        status: 'healthy',
        uptime: process.uptime(),
        memory: process.memoryUsage()
    });
});

// Error handling middleware
app.use((err, req, res, next) => {
    console.error('Error:', err.stack);
    res.status(500).json({ error: 'Something went wrong!' });
});

// 404 handler
app.use((req, res) => {
    res.status(404).json({ error: 'Route not found' });
});

app.listen(PORT, () => {
    console.log(\`🚀 $name server running on port \${PORT}\`);
    console.log(\`📍 Local: http://localhost:\${PORT}\`);
    console.log(\`🌍 External: http://144.24.7.55:\${PORT}\`);
});
EOF
            
            # Create environment file
            cat > "$node_dir/.env" << EOF
# $name Environment Variables
PORT=3000
NODE_ENV=development

# Database (if needed)
# DB_HOST=localhost
# DB_PORT=5432
# DB_NAME=$name
# DB_USER=admin
# DB_PASS=password

# API Keys (if needed)
# API_KEY=your-api-key-here
EOF
            
            # Create config file
            cat > "$node_dir/config/config.js" << EOF
// $name Configuration
module.exports = {
    development: {
        port: process.env.PORT || 3000,
        host: 'localhost'
    },
    production: {
        port: process.env.PORT || 8080,
        host: '144.24.7.55'
    }
};
EOF
            
            echo -e "${GREEN}✅ Node.js project '$name' created${NC}"
            echo -e "${BLUE}Location: $node_dir${NC}"
            echo -e "${YELLOW}Next steps:${NC}"
            echo "  1. cd $node_dir"
            echo "  2. npm install (if you have Node.js in Termux)"
            echo "  3. Upload to server and run npm install there"
            ;;
            
        *)
            echo "Usage: $0 new [website|game|nodejs] <project-name>"
            exit 1
            ;;
    esac
}

# Function to list projects
list_projects() {
    echo -e "${BLUE}=== ProBiz Projects ===${NC}"
    echo -e "${YELLOW}Location: $DEV_DIR${NC}"
    echo ""
    
    echo -e "${GREEN}Websites:${NC}"
    if [ -d "$DEV_DIR/websites" ]; then
        for item in $(ls "$DEV_DIR/websites/" 2>/dev/null); do
            if [ -d "$DEV_DIR/websites/$item" ] && [ "$item" != "games" ]; then
                echo "  📄 $item"
            fi
        done
    fi
    
    echo -e "\n${GREEN}Games:${NC}"
    if [ -d "$DEV_DIR/websites/games" ]; then
        for item in $(ls "$DEV_DIR/websites/games/" 2>/dev/null); do
            if [ -d "$DEV_DIR/websites/games/$item" ]; then
                echo "  🎮 $item"
            fi
        done
    fi
    
    echo -e "\n${GREEN}Node.js Projects:${NC}"
    if [ -d "$DEV_DIR/nodejs" ]; then
        for item in $(ls "$DEV_DIR/nodejs/" 2>/dev/null); do
            if [ -d "$DEV_DIR/nodejs/$item" ]; then
                echo "  ⚙️ $item"
            fi
        done
    fi
    
    echo -e "\n${GREEN}Shared Resources:${NC}"
    if [ -d "$DEV_DIR/shared" ]; then
        echo "  📁 CSS: $(ls "$DEV_DIR/shared/css/" 2>/dev/null | wc -l) files"
        echo "  📁 JS: $(ls "$DEV_DIR/shared/js/" 2>/dev/null | wc -l) files"
        echo "  📁 Images: $(ls "$DEV_DIR/shared/images/" 2>/dev/null | wc -l) files"
        echo "  📁 Templates: $(ls "$DEV_DIR/shared/templates/" 2>/dev/null | wc -l) files"
    fi
}

# Function to show directory structure
show_tree() {
    echo -e "${BLUE}ProBiz Directory Structure:${NC}"
    if command -v tree >/dev/null 2>&1; then
        tree "$DEV_DIR" -L 3
    else
        find "$DEV_DIR" -type d | head -30 | sed 's/[^-][^\/]*\//  /g' 2>/dev/null
    fi
}

# Function to edit project
edit_project() {
    local type="$1"
    local name="$2"
    local editor="${EDITOR:-nano}"
    
    case "$type" in
        "website")
            local project_dir="$DEV_DIR/websites/$name"
            ;;
        "game")
            local project_dir="$DEV_DIR/websites/games/$name"
            ;;
        "nodejs")
            local project_dir="$DEV_DIR/nodejs/$name"
            ;;
        *)
            echo "Usage: $0 edit [website|game|nodejs] <project-name>"
            exit 1
            ;;
    esac
    
    if [ -d "$project_dir" ]; then
        cd "$project_dir"
        echo -e "${BLUE}Editing $name in $editor${NC}"
        echo -e "${YELLOW}Current directory: $project_dir${NC}"
        echo ""
        echo "Available files:"
        find . -type f \( -name "*.html" -o -name "*.css" -o -name "*.js" -o -name "*.json" \) | head -10
        echo ""
        echo "Enter filename to edit (or press Enter for directory listing):"
        read filename
        
        if [ -n "$filename" ] && [ -f "$filename" ]; then
            $editor "$filename"
        else
            ls -la
            echo ""
            echo "Enter filename to edit:"
            read filename
            if [ -n "$filename" ] && [ -f "$filename" ]; then
                $editor "$filename"
            fi
        fi
    else
        echo -e "${RED}Project $name not found in $type projects${NC}"
        echo "Available projects:"
        case "$type" in
            "website") ls "$DEV_DIR/websites/" 2>/dev/null ;;
            "game") ls "$DEV_DIR/websites/games/" 2>/dev/null ;;
            "nodejs") ls "$DEV_DIR/nodejs/" 2>/dev/null ;;
        esac
    fi
}

# Main script logic
case "$1" in
    "new")
        new_project "$2" "$3"
        ;;
    "list"|"ls")
        list_projects
        ;;
    "tree")
        show_tree
        ;;
    "edit")
        edit_project "$2" "$3"
        ;;
    "init")
        ensure_structure
        echo -e "${GREEN}✅ ProBiz directory structure initialized${NC}"
        ;;
    *)
        echo "ProBiz Development Helper"
        echo "Usage: $0 [command] [options]"
        echo ""
        echo "Commands:"
        echo "  new [website|game|nodejs] <name>  - Create new project"
        echo "  list                               - List all projects"
        echo "  tree                               - Show directory structure"
        echo "  edit [website|game|nodejs] <name> - Edit project"
        echo "  init                               - Initialize directory structure"
        echo ""
        echo "Examples:"
        echo "  $0 new website portfolio"
        echo "  $0 new game snake"
        echo "  $0 new nodejs chat-api"
        echo "  $0 edit website portfolio"
        echo "  $0 list"
        ;;
esac

