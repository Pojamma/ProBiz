# Oracle A1 ARM Migration Checklist

Migration from AMD Micro (503 MB RAM) to Ampere A1 Flex (up to 24 GB RAM) — both Oracle Cloud Free Tier.

---

## Why Migrate

| | AMD Micro (current) | A1 Flex (target) |
|---|---|---|
| RAM | 503 MB | Up to 24 GB (free) |
| OCPUs | 1 | Up to 4 (free) |
| Architecture | x86_64 | ARM64 |
| CPU steal | ~59% (hypervisor throttling) | Much lower |
| Cost | Free | Free |

The current server hangs because:
- Only 503 MB total RAM
- Claude Code alone uses ~144 MB (29%)
- Oracle's cloud agents use ~46 MB
- High CPU steal time from the hypervisor
- System falls into swap under normal load

**Recommended A1 config: 2 OCPUs / 12 GB RAM** (comfortable headroom, still free tier)

---

## Phase 1 — Prepare on the OLD Server

### 1.1 Back up your .env file (API keys)
```bash
cat /home/opc/ProBiz/.env
```
> Copy the contents somewhere safe — you'll need the Google Maps API key on the new server.

### 1.2 Back up nginx configs
```bash
sudo cat /etc/nginx/conf.d/probiz.conf
sudo cat /etc/nginx/conf.d/jsoneditor-help.conf
```
> Both configs are documented in full at the bottom of this file.

### 1.3 Back up the help.pojammaapps.com web content
```bash
ls /var/www/jsoneditor-help/
sudo tar -czf /home/opc/jsoneditor-help-backup.tar.gz /var/www/jsoneditor-help/
```
> This directory is NOT in the GitHub repo — back it up manually.

### 1.4 Back up the letsencrypt webroot directory
```bash
sudo ls /var/www/letsencrypt/
```

### 1.5 Make sure all ProBiz code is pushed to GitHub
```bash
cd /home/opc/ProBiz
git status
git push origin master
```

### 1.6 Note your current public IP (for comparison)
```bash
curl -s ifconfig.me
```

---

## Phase 2 — Create the New A1 Instance in OCI Console

1. Log into **OCI Console** → Compute → Instances → **Create Instance**
2. Give it a name (e.g., `probiz-a1`)
3. Click **Edit** next to Image and Shape:
   - **Image**: Oracle Linux 9 (same as current — easiest migration)
   - **Shape**: Click **Change Shape** → Select **Ampere** → `VM.Standard.A1.Flex`
   - Set **2 OCPUs** and **12 GB RAM** (or up to 4/24 if you want maximum)
4. **Networking**: Use default VCN, assign a public IP
5. **SSH Keys**: Paste your existing public SSH key (so same key works)
6. Click **Create**
7. Wait for the instance to reach **Running** state
8. Note the new public IP address

---

## Phase 3 — Initial Setup on the NEW Server

SSH into the new A1 instance:
```bash
ssh opc@<NEW_PUBLIC_IP>
```

### 3.1 Update the system
```bash
sudo dnf update -y
```

### 3.2 Install required packages
```bash
# Install nginx
sudo dnf install -y nginx

# Install Node.js 22 (match current version)
sudo dnf install -y nodejs npm

# Verify versions
node --version    # should be v22.x
nginx -v          # should be 1.20.x or newer

# Install nodemon globally for dev server
sudo npm install -g nodemon

# Install certbot
sudo dnf install -y certbot python3-certbot-nginx
```

### 3.3 Install git and clone the repo
```bash
sudo dnf install -y git

cd /home/opc
git clone https://github.com/Pojamma/ProBiz.git
cd ProBiz
npm install
```

### 3.4 Create the .env file
```bash
nano /home/opc/ProBiz/.env
```
> Paste in your Google Maps API key and any other env vars from the old server.

### 3.5 Set file permissions (CRITICAL — nginx needs group read)
```bash
find /home/opc/ProBiz/websites -type f \( -name "*.html" -o -name "*.css" -o -name "*.js" \) -exec chmod 660 {} \;
find /home/opc/ProBiz/websites -type d -exec chmod 755 {} \;
find /home/opc/ProBiz/shared -type f -exec chmod 660 {} \;
```
> Without `chmod 660`, nginx returns 403 Forbidden on all files.

---

## Phase 4 — Configure Nginx

### 4.1 Set up the nginx user/group for file access
```bash
# Add nginx user to opc group so it can read 660 files
sudo usermod -aG opc nginx
```

### 4.2 Create the probiz.conf
```bash
sudo nano /etc/nginx/conf.d/probiz.conf
```
Paste the full config (see **Appendix A** at the bottom of this file).
> Remember to update the IP address on line: `server_name probiz.duckdns.org <NEW_IP>;`

### 4.3 Create the jsoneditor-help.conf
```bash
sudo nano /etc/nginx/conf.d/jsoneditor-help.conf
```
Paste the full config (see **Appendix B** at the bottom of this file).

### 4.4 Create required web directories
```bash
sudo mkdir -p /var/www/letsencrypt
sudo mkdir -p /var/www/jsoneditor-help
sudo chown -R opc:opc /var/www/jsoneditor-help
```

### 4.5 Test and enable nginx
```bash
sudo nginx -t          # must say "syntax is ok"
sudo systemctl enable nginx
sudo systemctl start nginx
```

---

## Phase 5 — Set Up the Node.js Server (SunCalc)

### 5.1 Create a systemd service so it auto-starts
```bash
sudo nano /etc/systemd/system/probiz.service
```
Paste:
```ini
[Unit]
Description=ProBiz Node.js Server
After=network.target

[Service]
Type=simple
User=opc
WorkingDirectory=/home/opc/ProBiz
ExecStart=/usr/bin/node src/server.js
Restart=on-failure
RestartSec=10
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable probiz
sudo systemctl start probiz
sudo systemctl status probiz   # verify it's running
```

> The Node.js server listens on port 3001. Nginx proxies `/suncalc/` to it.

---

## Phase 6 — Open Firewall Ports (OCI Security Rules)

OCI blocks ports by default. You must open them in two places:

### 6.1 OCI Console — Security List / Network Security Group
In OCI Console → Networking → Virtual Cloud Networks → your VCN → Security Lists:
- Add **Ingress Rule**: TCP port **80** from `0.0.0.0/0`
- Add **Ingress Rule**: TCP port **443** from `0.0.0.0/0`

### 6.2 OS-level firewall on the new server
```bash
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
sudo firewall-cmd --list-all   # verify http and https are listed
```

---

## Phase 7 — Migrate help.pojammaapps.com Content

Copy the JSON/Markdown help files from the old server:
```bash
# On the OLD server — create a tarball
sudo tar -czf /home/opc/jsoneditor-help-backup.tar.gz /var/www/jsoneditor-help/

# Transfer to new server (run from your local machine or old server)
scp opc@<OLD_IP>:/home/opc/jsoneditor-help-backup.tar.gz opc@<NEW_IP>:/home/opc/

# On the NEW server — extract
sudo tar -xzf /home/opc/jsoneditor-help-backup.tar.gz -C /
sudo chown -R nginx:nginx /var/www/jsoneditor-help
```

---

## Phase 8 — Update DNS and Get SSL Certificates

### 8.1 Update DuckDNS
- Log into DuckDNS → update `probiz.duckdns.org` to point to the **new server's public IP**
- Wait a few minutes for propagation

### 8.2 Update help.pojammaapps.com DNS
- Log into your domain registrar → update the A record for `help.pojammaapps.com` to the **new server's public IP**
- DNS propagation can take up to 24 hours (usually much faster)

### 8.3 Verify DNS is pointing to the new server
```bash
curl -s http://probiz.duckdns.org     # should hit new server
```

### 8.4 Issue SSL certificates
```bash
# For probiz.duckdns.org
sudo certbot --nginx -d probiz.duckdns.org

# For help.pojammaapps.com
sudo certbot --nginx -d help.pojammaapps.com --webroot -w /var/www/letsencrypt
```

### 8.5 Set up the certbot auto-renewal cron job
```bash
sudo crontab -e
```
Add:
```
0 2 * * * /usr/local/bin/certbot renew --quiet --nginx
```

### 8.6 Test renewal
```bash
sudo certbot renew --dry-run
```

---

## Phase 9 — Verify Everything Works

```bash
# Check nginx is running
sudo systemctl status nginx

# Check Node.js server is running
sudo systemctl status probiz

# Check ports are listening
ss -tlnp | grep -E '80|443|3001'

# Test the sites
curl -I https://probiz.duckdns.org
curl -I https://help.pojammaapps.com

# Check nginx logs for errors
sudo tail -f /var/log/nginx/probiz_error.log
```

Manually test in a browser:
- [ ] `https://probiz.duckdns.org` — main portal loads
- [ ] `https://probiz.duckdns.org/suncalc/` — SunCalc loads with map
- [ ] `https://probiz.duckdns.org/games/` — games load
- [ ] `https://probiz.duckdns.org/EJ-EV/` — kids apps load
- [ ] `https://help.pojammaapps.com` — help content loads
- [ ] SSL padlock shows valid for both domains

---

## Phase 10 — Decommission the Old Server

Only do this AFTER everything is verified working on the new server.

1. In OCI Console → Compute → Instances → find old AMD Micro instance
2. Click **Terminate**
3. Check **Permanently delete the attached boot volume** (to avoid storage charges)

> Keeping both instances running is fine temporarily — Oracle Free Tier allows 2 AMD micros AND the A1 allocation separately. But once verified, terminate the old one to keep things clean.

---

## Post-Migration — Expected Resource Usage

With 12 GB RAM on A1, you should see:

| Process | RAM Used |
|---|---|
| Oracle Cloud Agents (4 processes) | ~46 MB |
| nginx (master + workers) | ~10 MB |
| Node.js (src/server.js) | ~4 MB |
| OS overhead | ~200 MB |
| **Total idle** | **~260 MB** |
| **Available headroom** | **~11.7 GB** |

Claude Code sessions (~144 MB) will barely register on a 12 GB system.

---

## Appendix A — /etc/nginx/conf.d/probiz.conf

```nginx
# /etc/nginx/conf.d/probiz.conf
# HTTP server - redirects to HTTPS
server {
    listen 80;
    server_name probiz.duckdns.org <NEW_SERVER_IP>;

    # Let's Encrypt webroot
    location /.well-known/acme-challenge/ {
        root /home/opc/ProBiz/websites/main/public;
    }

    # Redirect all HTTP traffic to HTTPS
    return 301 https://probiz.duckdns.org$request_uri;
}

# HTTPS server - main configuration
server {
    listen 443 ssl http2;
    server_name probiz.duckdns.org;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/probiz.duckdns.org/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/probiz.duckdns.org/privkey.pem;

    # Modern SSL configuration
    ssl_session_cache shared:SSL:1m;
    ssl_session_timeout 10m;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-CHACHA20-POLY1305;
    ssl_prefer_server_ciphers off;

    # Security Headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Content-Security-Policy "default-src 'self' https://probiz.duckdns.org; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self'; connect-src 'self'; media-src 'self';" always;

    server_tokens off;

    root /home/opc/ProBiz/websites/main/public;
    index index.html index.htm;

    # ACME challenge — MUST be before the hidden files deny rule
    location ^~ /.well-known/acme-challenge/ {
        root /home/opc/ProBiz/websites/main/public;
        allow all;
    }

    # Block hidden files
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }

    # Block backup files
    location ~* \.(bak|backup|old|orig|tmp)$ {
        deny all;
        access_log off;
        log_not_found off;
    }

    location / {
        try_files $uri $uri/ =404;
    }

    location /games/ {
        alias /home/opc/ProBiz/websites/games/;
        try_files $uri $uri/ =404;
    }

    location /games/WordSearchGPT/ {
        alias /home/opc/ProBiz/websites/games/WordSearchGPT/;
        try_files $uri $uri/ =404;
    }

    location /games/GuessCapitals/ {
        alias /home/opc/ProBiz/websites/games/GuessCapitals/;
        try_files $uri $uri/ =404;
    }

    location /games/Wordle/ {
        alias /home/opc/ProBiz/websites/games/Wordle/;
        try_files $uri $uri/ =404;
    }

    location /docs/ {
        alias /home/opc/ProBiz/docs/;
        try_files $uri $uri/ =404;
    }

    location /nodejs/ {
        alias /home/opc/ProBiz/nodejs/;
        try_files $uri $uri/ =404;
    }

    location /utility/ {
        alias /home/opc/ProBiz/websites/utility/;
        try_files $uri $uri/ =404;
    }

    location /EJ-EV/ {
        alias /home/opc/ProBiz/websites/EJ-EV/;
        try_files $uri $uri/ =404;
    }

    location /EJ-EV/Scribble/ {
        alias /home/opc/ProBiz/websites/EJ-EV/Scribble/;
        try_files $uri $uri/ =404;
    }

    location /EJ-EV/AlphabetSearch/ {
        alias /home/opc/ProBiz/websites/EJ-EV/AlphabetSearch/;
        try_files $uri $uri/ =404;
    }

    location /EJ-EV/AnimalSoundsMatch/ {
        alias /home/opc/ProBiz/websites/EJ-EV/AnimalSoundsMatch/;
        try_files $uri $uri/ =404;
    }

    location /EJ-EV/Bubbles/ {
        alias /home/opc/ProBiz/websites/EJ-EV/Bubbles/;
        try_files $uri $uri/ =404;
    }

    location /EJ-EV/Maze/ {
        alias /home/opc/ProBiz/websites/EJ-EV/Maze/;
        try_files $uri $uri/ =404;
    }

    location /EJ-EV/Trace/ {
        alias /home/opc/ProBiz/websites/EJ-EV/Trace/;
        try_files $uri $uri/ =404;
    }

    location /EJ-EV/speakText/ {
        alias /home/opc/ProBiz/websites/EJ-EV/speakText/;
        try_files $uri $uri/ =404;
    }

    # SunCalc Node.js proxy
    location /suncalc/ {
        proxy_pass http://localhost:3001/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        add_header Access-Control-Allow-Origin *;
        add_header Access-Control-Allow-Methods "GET, POST, OPTIONS";
        add_header Access-Control-Allow-Headers "Origin, X-Requested-With, Content-Type, Accept";
    }

    location /suncalc/api/ {
        if ($request_method = 'OPTIONS') {
            add_header Access-Control-Allow-Origin *;
            add_header Access-Control-Allow-Methods "GET, POST, OPTIONS";
            add_header Access-Control-Allow-Headers "Origin, X-Requested-With, Content-Type, Accept";
            add_header Content-Length 0;
            add_header Content-Type text/plain;
            return 200;
        }
        proxy_pass http://localhost:3001/api/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /shared/ {
        alias /home/opc/ProBiz/shared/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/json image/svg+xml;

    error_log /var/log/nginx/probiz_error.log;
    access_log /var/log/nginx/probiz_access.log;
}
```

---

## Appendix B — /etc/nginx/conf.d/jsoneditor-help.conf

```nginx
# /etc/nginx/conf.d/jsoneditor-help.conf
# HTTP server - redirects to HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name help.pojammaapps.com;

    # Let's Encrypt webroot
    location ^~ /.well-known/acme-challenge/ {
        default_type "text/plain";
        root /var/www/letsencrypt;
        allow all;
    }

    return 301 https://help.pojammaapps.com$request_uri;
}

# HTTPS server
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name help.pojammaapps.com;

    ssl_certificate /etc/letsencrypt/live/help.pojammaapps.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/help.pojammaapps.com/privkey.pem;

    ssl_session_cache shared:SSL:1m;
    ssl_session_timeout 10m;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-CHACHA20-POLY1305;
    ssl_prefer_server_ciphers off;

    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header 'Access-Control-Allow-Origin' '*' always;
    add_header 'Access-Control-Allow-Methods' 'GET, OPTIONS' always;
    add_header 'Access-Control-Allow-Headers' 'Accept, Content-Type' always;

    root /var/www/jsoneditor-help;
    index index.json;

    location / {
        if ($request_method = 'OPTIONS') {
            add_header 'Access-Control-Allow-Origin' '*';
            add_header 'Access-Control-Allow-Methods' 'GET, OPTIONS';
            add_header 'Access-Control-Max-Age' 1728000;
            add_header 'Content-Type' 'text/plain; charset=utf-8';
            add_header 'Content-Length' 0;
            return 204;
        }
        try_files $uri $uri/ =404;
    }

    location ~* \.(md|json)$ {
        expires 1h;
        add_header Cache-Control "public, max-age=3600, must-revalidate";
        add_header 'Access-Control-Allow-Origin' '*' always;
        types {
            text/markdown md;
            application/json json;
        }
    }

    location ^~ /.well-known/acme-challenge/ {
        root /var/www/letsencrypt;
        allow all;
    }

    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }

    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/markdown application/json;

    access_log /var/log/nginx/jsoneditor-help-access.log;
    error_log /var/log/nginx/jsoneditor-help-error.log;
}
```

---

## Appendix C — SSL Key Notes

- **Do not use `\$` in nginx `return` directives** — it produces a literal backslash in the redirect URL
- The HTTPS block must have `location ^~ /.well-known/acme-challenge/` **before** `location ~ /\.` — the `^~` prefix takes priority over regex, so Let's Encrypt validation won't get blocked by the hidden files deny rule
- After issuing new certs, verify: `sudo certbot certificates`
