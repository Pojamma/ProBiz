# SunCalc Application Setup

This is a web application that calculates sun and moon times for any location on Earth. It's been split into separate HTML, CSS, and JavaScript files and uses Express.js to serve the application securely.

## Features

- **Interactive Google Maps**: Click anywhere to get sun/moon times for that location
- **Automatic Location Detection**: Starts with your current location
- **Comprehensive Sun Times**: Sunrise, sunset, golden hour, twilight periods, and more
- **Moon Information**: Moonrise, moonset, and moon phase calculations
- **Responsive Design**: Works on desktop and mobile devices
- **Secure API Key Management**: Google Maps API key is stored server-side

## Project Structure

```
/home/opc/ProBiz/nodejs/suncalc/
├── server.js              # Express server
├── package.json           # Node.js dependencies
├── .env                   # Environment variables (create this)
├── .env.example          # Template for environment variables
├── public/               # Static files served by Express
│   ├── suncalc.html     # Main HTML file
│   ├── suncalc.css      # Styles
│   └── suncalc.js       # Client-side JavaScript with SunCalc library
└── setup-suncalc.sh     # Automated setup script
```

## Quick Setup

### Option 1: Automated Setup (Recommended)

1. **Download and run the setup script**:
   ```bash
   cd /home/opc/ProBiz/nodejs
   chmod +x setup-suncalc.sh
   ./setup-suncalc.sh
   ```

2. **Configure your Google Maps API key**:
   ```bash
   cd /home/opc/ProBiz/nodejs/suncalc
   cp .env.example .env
   nano .env  # Add your actual Google Maps API key
   ```

3. **Update nginx configuration**:
   ```bash
   sudo nano /etc/nginx/conf.d/probiz.conf
   # Add the location blocks from nginx-suncalc-addition.conf
   sudo nginx -t  # Test configuration
   sudo systemctl reload nginx
   ```

4. **Start the service**:
   ```bash
   sudo systemctl enable suncalc
   sudo systemctl start suncalc
   ```

### Option 2: Manual Setup

1. **Create directory structure**:
   ```bash
   mkdir -p /home/opc/ProBiz/nodejs/suncalc/public
   cd /home/opc/ProBiz/nodejs/suncalc
   ```

2. **Create the files** (copy the content from the artifacts above):
   - `package.json`
   - `server.js`
   - `public/suncalc.html`
   - `public/suncalc.css`
   - `public/suncalc.js`
   - `.env.example`

3. **Install Node.js** (if not already installed):
   ```bash
   curl -fsSL https://rpm.nodesource.com/setup_lts.x | sudo bash -
   sudo yum install -y nodejs
   ```

4. **Install dependencies**:
   ```bash
   npm install
   ```

5. **Configure environment**:
   ```bash
   cp .env.example .env
   nano .env  # Add your Google Maps API key
   ```

## Getting Google Maps API Key

1. Go to the [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the "Maps JavaScript API"
4. Create credentials (API Key)
5. Restrict the key to your domain (144.24.7.55) for security
6. Add the key to your `.env` file

## Nginx Configuration

Add this to your existing `/etc/nginx/conf.d/probiz.conf` file inside the main server block:

```nginx
# ========== SunCalc Node.js Application ==========
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
}

location /suncalc/api/ {
    proxy_pass http://localhost:3001/api/;
    proxy_http_version 1.1;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}
```

Then reload nginx:
```bash
sudo nginx -t
sudo systemctl reload nginx
```

## Running the Application

### Development Mode
```bash
cd /home/opc/ProBiz/nodejs/suncalc
npm start
```

### Production Mode (with systemd)
```bash
sudo systemctl start suncalc
sudo systemctl enable suncalc  # Start on boot
```

### Check Status
```bash
sudo systemctl status suncalc
sudo journalctl -u suncalc -f  # View logs
```

## Accessing the Application

- **Local testing**: http://localhost:3001
- **Public access**: http://144.24.7.55/suncalc/

## Troubleshooting

### Check if the service is running:
```bash
sudo systemctl status suncalc
curl http://localhost:3001/health
```

### View logs:
```bash
sudo journalctl -u suncalc -f
```

### Test nginx configuration:
```bash
sudo nginx -t
```

### Common issues:

1. **"Failed to get API key"**: Check that your `.env` file has the correct `GOOGLE_MAPS_API_KEY`
2. **"Error loading Google Maps"**: Verify your API key is valid and the Maps JavaScript API is enabled
3. **Service won't start**: Check the logs with `journalctl -u suncalc`
4. **Can't access from browser**: Ensure nginx is configured correctly and the service is running

## Security Notes

- The Google Maps API key is stored server-side and never exposed to the client
- Consider restricting your API key to your specific domain in the Google Cloud Console
- The application uses HTTPS-ready configuration for production use

## Adding to Your Main Website

To add a link to SunCalc in your main website menu, update your main `index.html` file to include:

```javascript
{ name: "SunCalc", path: "suncalc/", category: "utilities" }
```

## Credits

- Original SunCalc library by Vladimir Agafonkin
- Application developed by Bob Robles
- Refactored and enhanced for ProBiz website