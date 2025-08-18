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
