#!/bin/bash

# Oracle Server Project Directory Setup Script
# Run this script from your main project directory (e.g., /home/opc/ProBiz)
# Usage: ./setup-project-structure.sh

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}$1${NC}"
}

# Check if we're in the right location
if [[ ! $(pwd) =~ ProBiz$ ]]; then
    print_warning "You should run this script from your ProBiz directory"
    print_warning "Current directory: $(pwd)"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_error "Exiting..."
        exit 1
    fi
fi

print_header "=== Oracle Server Project Structure Setup ==="
print_status "Creating directory structure..."

# Create main directories
print_status "Creating main project directories..."
mkdir -p websites/main/{public,src,config}
mkdir -p websites/project1
mkdir -p websites/project2
mkdir -p websites/games/{game1,game2}
mkdir -p nodejs/{api-server,websocket-apps,utilities}
mkdir -p shared/{css,js,images,templates}
mkdir -p scripts
mkdir -p logs
mkdir -p backups
mkdir -p docs

print_status "Creating starter files..."

# Create main website files
cat > websites/main/public/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Personal Website</title>
    <link rel="stylesheet" href="/shared/css/main.css">
</head>
<body>
    <header>
        <h1>Welcome to My Personal Website</h1>
        <nav>
            <ul>
                <li><a href="/">Home</a></li>
                <li><a href="/projects">Projects</a></li>
                <li><a href="/games">Games</a></li>
                <li><a href="/about">About</a></li>
            </ul>
        </nav>
    </header>
    
    <main>
        <section>
            <h2>Projects & Experiments</h2>
            <p>This is my personal website where I showcase various projects and games.</p>
        </section>
    </main>
    
    <footer>
        <p>&copy; 2025 My Personal Website</p>
    </footer>
    
    <script src="/shared/js/main.js"></script>
</body>
</html>
EOF

# Create basic CSS
cat > shared/css/main.css << 'EOF'
/* Main stylesheet for personal website */
* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
}

body {
    font-family: 'Arial', sans-serif;
    line-height: 1.6;
    color: #333;
    background-color: #f4f4f4;
}

header {
    background: #2c3e50;
    color: white;
    padding: 1rem 0;
    text-align: center;
}

nav ul {
    list-style: none;
    display: flex;
    justify-content: center;
    margin-top: 1rem;
}

nav ul li {
    margin: 0 1rem;
}

nav ul li a {
    color: white;
    text-decoration: none;
    padding: 0.5rem 1rem;
    border-radius: 5px;
    transition: background 0.3s;
}

nav ul li a:hover {
    background: #34495e;
}

main {
    max-width: 1200px;
    margin: 2rem auto;
    padding: 0 1rem;
    background: white;
    border-radius: 10px;
    box-shadow: 0 0 10px rgba(0,0,0,0.1);
    padding: 2rem;
}

footer {
    text-align: center;
    padding: 1rem;
    background: #2c3e50;
    color: white;
    margin-top: 2rem;
}
EOF

# Create basic JavaScript
cat > shared/js/main.js << 'EOF'
// Main JavaScript for personal website
document.addEventListener('DOMContentLoaded', function() {
    console.log('Personal website loaded successfully!');
    
    // Add some basic interactivity
    const navLinks = document.querySelectorAll('nav a');
    navLinks.forEach(link => {
        link.addEventListener('click', function(e) {
            console.log('Navigating to:', this.href);
        });
    });
});
EOF

# Create deployment script
cat > scripts/deploy.sh << 'EOF'
#!/bin/bash

# Deployment script for personal website
# Usage: ./deploy.sh [environment]

ENVIRONMENT=${1:-production}
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

echo "Deploying to $ENVIRONMENT environment..."

# Create backup before deployment
echo "Creating backup..."
cp -r websites/main/public ../backups/main_backup_$TIMESTAMP

# Add your deployment logic here
echo "Deployment logic goes here..."

# Restart web server if needed
# sudo systemctl restart nginx

echo "Deployment completed at $(date)"
EOF

# Create backup script
cat > scripts/backup.sh << 'EOF'
#!/bin/bash

# Backup script for Oracle server projects
BACKUP_DIR="../backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_NAME="full_backup_$TIMESTAMP.tar.gz"

echo "Creating backup: $BACKUP_NAME"

# Create compressed backup
tar -czf "$BACKUP_DIR/$BACKUP_NAME" \
    --exclude="logs/*" \
    --exclude="node_modules" \
    --exclude=".git" \
    websites/ nodejs/ shared/ scripts/ docs/

echo "Backup created: $BACKUP_DIR/$BACKUP_NAME"

# Keep only last 10 backups
cd "$BACKUP_DIR"
ls -t full_backup_*.tar.gz | tail -n +11 | xargs -r rm --

echo "Backup completed at $(date)"
EOF

# Create server setup script
cat > scripts/server-setup.sh << 'EOF'
#!/bin/bash

# Server setup script for Oracle Linux
# Run with sudo privileges

echo "Setting up Oracle Linux server for web development..."

# Update system
dnf update -y

# Install essential packages
dnf install -y curl wget git vim nginx nodejs npm

# Install Node.js (latest LTS)
curl -fsSL https://rpm.nodesource.com/setup_lts.x | bash -
dnf install -y nodejs

# Configure firewall for web traffic
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --reload

# Enable and start nginx
systemctl enable nginx
systemctl start nginx

echo "Basic server setup completed!"
echo "Remember to configure nginx and SSL certificates"
EOF

# Create documentation files
cat > docs/README.md << 'EOF'
# Personal Website Project

This is my personal website and development environment hosted on Oracle Cloud Infrastructure.

## Structure

- `websites/` - Web projects and static sites
- `nodejs/` - Node.js applications and APIs
- `shared/` - Common resources (CSS, JS, images)
- `scripts/` - Server management and deployment scripts
- `logs/` - Application logs
- `backups/` - Local backups
- `docs/` - Project documentation

## Getting Started

1. Run the initial server setup: `sudo ./scripts/server-setup.sh`
2. Configure your web server to serve from `websites/main/public/`
3. Start developing!

## Deployment

Use `./scripts/deploy.sh` to deploy your changes.

## Backup

Run `./scripts/backup.sh` to create backups of your projects.
EOF

cat > docs/setup-notes.md << 'EOF'
# Server Setup Notes

## Oracle Cloud Configuration

- Instance: ProBiz
- IP: 144.24.7.55
- OS: Oracle Linux Server 9.6
- User: opc

## SSH Configuration

```
Host oracle-instance-probiz
    HostName 144.24.7.55
    User opc
    IdentityFile ~/.ssh/ssh-key-2025-04-19.key
```

## Web Server Configuration

TODO: Add nginx configuration details

## Security Notes

- Keep SSH keys secure
- Regularly update system packages
- Monitor access logs
- Set up fail2ban for SSH protection

## Development Workflow

1. Develop on Android tablet
2. Transfer to Termux
3. SCP to Oracle server
4. Deploy using scripts
EOF

cat > docs/project-ideas.md << 'EOF'
# Project Ideas

## Web Projects
- [ ] Personal portfolio website
- [ ] Blog with markdown support
- [ ] Photo gallery
- [ ] Resume/CV site

## Games
- [ ] Simple HTML5 games
- [ ] JavaScript puzzles
- [ ] WebGL experiments
- [ ] Browser-based multiplayer games

## Node.js Applications
- [ ] REST API for mobile apps
- [ ] WebSocket chat application
- [ ] File sharing service
- [ ] Development tools and utilities

## Learning Projects
- [ ] CSS animation experiments
- [ ] JavaScript framework testing
- [ ] Progressive Web App (PWA)
- [ ] WebAssembly experiments

## Utilities
- [ ] Server monitoring dashboard
- [ ] Automated backup scripts
- [ ] Development environment setup
- [ ] Performance monitoring tools
EOF

# Make scripts executable
chmod +x scripts/*.sh

# Create .gitignore for potential git repositories
cat > .gitignore << 'EOF'
# Logs
logs/
*.log

# Backups
backups/

# Node modules
node_modules/

# Environment variables
.env
.env.local

# Temporary files
*.tmp
*.temp

# OS generated files
.DS_Store
Thumbs.db

# Editor files
*.swp
*.swo
*~
EOF

print_status "Directory structure created successfully!"
print_header "=== Summary ==="
echo "Created the following structure:"
tree . 2>/dev/null || find . -type d | sed 's/[^-][^\/]*\//  /g;s/^  //'

print_header "=== Next Steps ==="
echo "1. Run 'sudo ./scripts/server-setup.sh' to install basic packages"
echo "2. Configure your web server to serve from 'websites/main/public/'"
echo "3. Set up SSL certificates for HTTPS"
echo "4. Configure firewall rules as needed"
echo "5. Start developing your projects!"

print_header "=== Quick Commands ==="
echo "• Deploy website: ./scripts/deploy.sh"
echo "• Create backup: ./scripts/backup.sh"
echo "• View logs: tail -f logs/*.log"
echo "• Start development: cd websites/main && python3 -m http.server 8000"

print_status "Setup completed successfully!"
EOF