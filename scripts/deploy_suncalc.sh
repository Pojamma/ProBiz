#!/bin/bash

# Deploy script for SunCalc application files
# This script copies the application files to their correct locations
# Run this after setup-suncalc.sh

echo "Deploying SunCalc application files..."

# Define directories
PROBIZ_DIR="/data/data/com.termux/files/home/ProBiz"
SRC_DIR="$PROBIZ_DIR/src"
SUNCALC_DIR="$PROBIZ_DIR/websites/suncalc"

# Check if directories exist
if [ ! -d "$PROBIZ_DIR" ]; then
    echo "Error: ProBiz directory not found at $PROBIZ_DIR"
    echo "Please run setup-suncalc.sh first"
    exit 1
fi

if [ ! -d "$SRC_DIR" ]; then
    echo "Error: src directory not found at $SRC_DIR"
    echo "Please run setup-suncalc.sh first"
    exit 1
fi

if [ ! -d "$SUNCALC_DIR" ]; then
    echo "Error: suncalc directory not found at $SUNCALC_DIR"
    echo "Please run setup-suncalc.sh first"
    exit 1
fi

# Function to copy file if it exists in current directory
copy_if_exists() {
    local source_file="$1"
    local dest_path="$2"
    
    if [ -f "$source_file" ]; then
        echo "Copying $source_file to $dest_path"
        cp "$source_file" "$dest_path"
        return 0
    else
        echo "Warning: $source_file not found in current directory"
        return 1
    fi
}

echo "Current directory: $(pwd)"
echo "Copying files to ProBiz structure..."

# Copy server.js to src directory
copy_if_exists "server.js" "$SRC_DIR/"

# Copy web application files to websites/suncalc directory
copy_if_exists "suncalc.html" "$SUNCALC_DIR/"
copy_if_exists "suncalc.css" "$SUNCALC_DIR/"
copy_if_exists "suncalc.js" "$SUNCALC_DIR/"

# Copy package.json to ProBiz root if it doesn't exist or is older
if [ -f "package.json" ]; then
    if [ ! -f "$PROBIZ_DIR/package.json" ] || [ "package.json" -nt "$PROBIZ_DIR/package.json" ]; then
        echo "Copying package.json to $PROBIZ_DIR/"
        cp "package.json" "$PROBIZ_DIR/"
    else
        echo "ProBiz package.json is up to date"
    fi
fi

# Copy .env.example to ProBiz root if it doesn't exist
if [ -f ".env.example" ] && [ ! -f "$PROBIZ_DIR/.env.example" ]; then
    echo "Copying .env.example to $PROBIZ_DIR/"
    cp ".env.example" "$PROBIZ_DIR/"
fi

# Set proper permissions
echo "Setting proper permissions..."
sudo chown -R opc:opc "$PROBIZ_DIR"
chmod 644 "$SUNCALC_DIR"/*.html "$SUNCALC_DIR"/*.css "$SUNCALC_DIR"/*.js 2>/dev/null || true
chmod 644 "$SRC_DIR"/*.js 2>/dev/null || true

# Check if .env file exists and has API key
echo ""
echo "Checking configuration..."
if [ -f "$PROBIZ_DIR/.env" ]; then
    if grep -q "GOOGLE_MAPS_API_KEY=your_" "$PROBIZ_DIR/.env"; then
        echo "⚠️  WARNING: Please update your .env file with a real Google Maps API key"
        echo "   Edit: $PROBIZ_DIR/.env"
    else
        echo "✅ .env file found with API key configured"
    fi
else
    echo "⚠️  WARNING: .env file not found. Creating from example..."
    if [ -f "$PROBIZ_DIR/.env.example" ]; then
        cp "$PROBIZ_DIR/.env.example" "$PROBIZ_DIR/.env"
        echo "   Please edit: $PROBIZ_DIR/.env"
    fi
fi

# Install/update dependencies
echo ""
echo "Installing dependencies..."
cd "$PROBIZ_DIR"
npm install

echo ""
echo "============================================="
echo "SunCalc deployment completed!"
echo "============================================="
echo ""
echo "Files deployed to:"
echo "  📁 Server: $SRC_DIR/server.js"
echo "  📁 Web app: $SUNCALC_DIR/"
echo "  📁 Config: $PROBIZ_DIR/.env"
echo ""
echo "Next steps:"
echo "1. Configure your API key (if not done already):"
echo "   nano $PROBIZ_DIR/.env"
echo ""
echo "2. Update nginx configuration with the location blocks"
echo ""
echo "3. Start the service:"
echo "   sudo systemctl restart suncalc"
echo "   sudo systemctl status suncalc"
echo ""
echo "4. Test the application:"
echo "   curl http://localhost:3001/health"
echo "   # Visit: http://144.24.7.55/suncalc/"
echo ""
echo "To manually test:"
echo "   cd $PROBIZ_DIR && npm start"
