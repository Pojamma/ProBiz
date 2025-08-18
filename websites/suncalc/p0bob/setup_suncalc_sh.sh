#!/bin/bash

# Setup script for SunCalc application
echo "Setting up SunCalc application..."

# Create directory structure
SUNCALC_DIR="/home/opc/ProBiz/nodejs/suncalc"
echo "Creating directory: $SUNCALC_DIR"
mkdir -p "$SUNCALC_DIR/public"

# Change to the directory
cd "$SUNCALC_DIR"

# Create package.json
cat > package.json << 'EOF'
{
  "name": "suncalc-app",
  "version": "1.0.0",
  "description": "SunCalc application for calculating sun and moon times",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js",
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "keywords": [
    "suncalc",
    "astronomy",
    "sun",
    "moon",
    "times"
  ],
  "author": "Bob Robles",
  "license": "MIT",
  "dependencies": {
    "express": "^4.18.2",
    "dotenv": "^16.3.1"
  },
  "devDependencies": {
    "nodemon": "^3.0.1"
  },
  "engines": {
    "node": ">=14.0.0"
  }
}
EOF

# Create .env.example
cat > .env.example << 'EOF'
# Google Maps API Key
# Get your API key from: https://developers.google.com/maps/documentation/javascript/get-api-key
GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here

# Port for the Express server (optional, defaults to 3001)
PORT=3001
EOF

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "Node.js is not installed. Installing Node.js..."
    
    # Install Node.js using NodeSource repository for Oracle Linux
    curl -fsSL https://rpm.nodesource.com/setup_lts.x | sudo bash -
    sudo yum install -y nodejs
    
    echo "Node.js installed successfully!"
    node --version
    npm --version
else
    echo "Node.js is already installed: $(node --version)"
fi

# Install npm dependencies
echo "Installing npm dependencies..."
npm install

# Create systemd service file
echo "Creating systemd service file..."
sudo tee /etc/systemd/system/suncalc.service > /dev/null << EOF
[Unit]
Description=SunCalc Node.js Application
After=network.target

[Service]
Type=simple
User=opc
WorkingDirectory=$SUNCALC_DIR
Environment=NODE_ENV=production
ExecStart=/usr/bin/node server.js
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Set proper permissions
sudo chown -R opc:opc "$SUNCALC_DIR"
chmod +x "$SUNCALC_DIR/setup-suncalc.sh"

echo ""
echo "============================================="
echo "SunCalc setup completed!"
echo "============================================="
echo ""
echo "Next steps:"
echo "1. Create a .env file with your Google Maps API key:"
echo "   cp .env.example .env"
echo "   # Edit .env and add your actual API key"
echo ""
echo "2. Add the following location block to your nginx config:"
echo "   location /suncalc/ {"
echo "       proxy_pass http://localhost:3001/;"
echo "       proxy_http_version 1.1;"
echo "       proxy_set_header Upgrade \$http_upgrade;"
echo "       proxy_set_header Connection 'upgrade';"
echo "       proxy_set_header Host \$host;"
echo "       proxy_set_header X-Real-IP \$remote_addr;"
echo "       proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;"
echo "       proxy_set_header X-Forwarded-Proto \$scheme;"
echo "       proxy_cache_bypass \$http_upgrade;"
echo "   }"
echo ""
echo "3. Enable and start the service:"
echo "   sudo systemctl enable suncalc"
echo "   sudo systemctl start suncalc"
echo ""
echo "4. Test the application:"
echo "   # Start manually for testing:"
echo "   npm start"
echo "   # Or visit: http://your-server-ip/suncalc/"
echo ""
echo "Location: $SUNCALC_DIR"