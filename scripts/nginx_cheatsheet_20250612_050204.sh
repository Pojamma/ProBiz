#!/bin/bash

# NGINX CHEAT SHEET - USEFUL COMMANDS, CONFIGS, AND TIPS
# Save this script as a reference file. It is not meant to be executed directly.

echo "📘 NGINX CHEAT SHEET"

# ------------------------------
# 📦 INSTALL NGINX
# ------------------------------
# Debian/Ubuntu:
# sudo apt update && sudo apt install nginx
# CentOS/RHEL:
# sudo yum install nginx
# Oracle Linux:
# sudo dnf install nginx

# ------------------------------
# 🔄 START / STOP / ENABLE
# ------------------------------
# Start NGINX:
# sudo systemctl start nginx

# Stop NGINX:
# sudo systemctl stop nginx

# Restart NGINX:
# sudo systemctl restart nginx

# Reload config (without downtime):
# sudo systemctl reload nginx

# Enable on boot:
# sudo systemctl enable nginx

# ------------------------------
# 📂 DEFAULT DIRECTORIES
# ------------------------------
# Config directory: /etc/nginx/
# Main config file: /etc/nginx/nginx.conf
# Sites available:  /etc/nginx/sites-available/
# Sites enabled:    /etc/nginx/sites-enabled/
# HTML files:       /usr/share/nginx/html/
# Logs:             /var/log/nginx/

# ------------------------------
# 🧪 TEST CONFIG
# ------------------------------
# Check config syntax:
# sudo nginx -t

# ------------------------------
# 🔁 BASIC SERVER BLOCK (VIRTUAL HOST)
# ------------------------------
# Example for serving a basic site:
#
# server {
#     listen 80;
#     server_name example.com;
#     root /var/www/example.com;
#     index index.html;
#
#     location / {
#         try_files $uri $uri/ =404;
#     }
# }

# ------------------------------
# 🔁 REDIRECT HTTP TO HTTPS
# ------------------------------
# server {
#     listen 80;
#     server_name example.com;
#     return 301 https://$host$request_uri;
# }

# ------------------------------
# 🔐 SSL CONFIGURATION
# ------------------------------
# server {
#     listen 443 ssl;
#     server_name example.com;
#
#     ssl_certificate     /etc/ssl/certs/example.com.crt;
#     ssl_certificate_key /etc/ssl/private/example.com.key;
#
#     location / {
#         proxy_pass http://localhost:3000;
#     }
# }

# ------------------------------
# 🔃 REVERSE PROXY (e.g., Node.js)
# ------------------------------
# server {
#     listen 80;
#     server_name example.com;
#
#     location / {
#         proxy_pass http://localhost:3000;
#         proxy_http_version 1.1;
#         proxy_set_header Upgrade $http_upgrade;
#         proxy_set_header Connection 'upgrade';
#         proxy_set_header Host $host;
#         proxy_cache_bypass $http_upgrade;
#     }
# }

# ------------------------------
# 🔧 CACHING STATIC FILES
# ------------------------------
# location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
#     expires 7d;
#     add_header Cache-Control "public";
# }

# ------------------------------
# 🕵️ BLOCK USER AGENTS
# ------------------------------
# if ($http_user_agent ~* (badbot|evilcrawler|scraper)) {
#     return 403;
# }

# ------------------------------
# 🔁 LOAD BALANCING (ROUND ROBIN)
# ------------------------------
# upstream backend {
#     server backend1.example.com;
#     server backend2.example.com;
# }
#
# server {
#     location / {
#         proxy_pass http://backend;
#     }
# }

# ------------------------------
# 📊 MONITORING AND STATUS
# ------------------------------
# Enable stub status:
#
# location /nginx_status {
#     stub_status;
#     allow 127.0.0.1;
#     deny all;
# }

# ------------------------------
# 🧩 ENABLE COMPRESSION
# ------------------------------
# gzip on;
# gzip_types text/plain application/json application/javascript text/css;

# ------------------------------
# 🚫 LIMIT REQUEST RATE
# ------------------------------
# limit_req_zone $binary_remote_addr zone=mylimit:10m rate=1r/s;
# server {
#     location /login {
#         limit_req zone=mylimit;
#     }
# }

# ------------------------------
# 👀 BASIC AUTH
# ------------------------------
# location /admin {
#     auth_basic "Restricted";
#     auth_basic_user_file /etc/nginx/.htpasswd;
# }

# ------------------------------
# 🧠 TIPS
# ------------------------------
# - Use relative paths and environment variables in server configs
# - Always test configuration with `nginx -t` before reload
# - Use `tail -f /var/log/nginx/access.log` to monitor traffic
# - Disable server tokens to hide version: `server_tokens off;`

# ------------------------------
# 🗂️ CACHING SECTION
# ------------------------------

# 📦 STATIC FILE CACHING (browser-level)
# Cache JS, CSS, image files for 7 days
location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
    expires 7d;
    add_header Cache-Control "public, no-transform";
}

# 🔁 PROXY CACHING (backend API responses)
# Cache responses from a backend server like Node.js
proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=my_cache:10m max_size=100m inactive=60m use_temp_path=off;

server {
    location /api/ {
        proxy_pass http://localhost:3000;
        proxy_cache my_cache;
        proxy_cache_valid 200 302 10m;
        proxy_cache_valid 404 1m;
        add_header X-Proxy-Cache $upstream_cache_status;
    }
}

# ⚡ MICRO-CACHING (e.g., for high-traffic APIs)
# Cache dynamic responses briefly to reduce server load
location /fast-api/ {
    proxy_pass http://localhost:3000;
    proxy_cache my_cache;
    proxy_cache_valid 200 1s;
    proxy_ignore_headers Cache-Control Expires;
    add_header X-Proxy-Cache $upstream_cache_status;
}

# 🔍 MONITORING CACHE
# Add this header to responses to track cache behavior
# Values can be: HIT | MISS | EXPIRED | BYPASS | STALE
add_header X-Proxy-Cache $upstream_cache_status;

# 🚫 CACHE BYPASS (e.g., POST/PUT/DELETE)
map $request_method $no_cache {
    default 0;
    POST    1;
    PUT     1;
    DELETE  1;
}

# Apply bypass rule
location /api/ {
    proxy_cache my_cache;
    proxy_cache_bypass $no_cache;
    proxy_no_cache $no_cache;
}

# ------------------------------
# 🧹 CLEARING THE NGINX CACHE
# ------------------------------
# Manually delete the cache directory contents:
# sudo rm -rf /var/cache/nginx/*
# Then reload NGINX to resume clean cache:
# sudo nginx -s reload

# (Optional) Add a cron job or script to clean periodically:
# echo "0 3 * * * root rm -rf /var/cache/nginx/*" | sudo tee -a /etc/crontab
