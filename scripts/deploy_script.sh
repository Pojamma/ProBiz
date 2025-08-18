#!/bin/bash

# ProBiz Website Deployment Script
echo "🚀 Deploying ProBiz Website..."

# Set proper permissions
echo "📁 Setting permissions..."
chmod 755 /home/opc/ProBiz
chmod -R 755 /home/opc/ProBiz/websites
chgrp -R opc /home/opc/ProBiz/websites
chmod -R g+r /home/opc/ProBiz/websites

# Fix file permissions
find /home/opc/ProBiz/websites -type f \( -name "*.html" -o -name "*.css" -o -name "*.js" \) -exec chmod 644 {} \;

# Test nginx configuration
echo "🔧 Testing nginx configuration..."
sudo nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Configuration test passed"
    echo "🔄 Reloading nginx..."
    sudo systemctl reload nginx
    echo "✅ Deployment complete!"
    echo "🌐 Website available at: http://144.24.7.55"
    echo "🎨 Drawing game at: http://144.24.7.55/games/kids_drawing_pad.html"
else
    echo "❌ Configuration test failed. Please check nginx config."
    exit 1
fi