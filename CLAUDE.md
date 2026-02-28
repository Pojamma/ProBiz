# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ProBiz is a personal collection of web-based games, utilities, and tools primarily created for entertainment and educational purposes. The project consists of standalone HTML applications, a Node.js/Express server for specific features like SunCalc, and various utility scripts for deployment and maintenance.

## Development Commands

```bash
# Start the development server with auto-reload
npm run dev

# Start the production server
npm start

# Start the SunCalc-specific server
npm run suncalc
```

## Architecture

### Server Architecture (`src/server.js`)
- Express.js server serving static files from the `websites/` directory
- Main purpose is to serve the SunCalc application with Google Maps API integration
- Provides `/api/maps-key` endpoint to securely serve Google Maps API keys
- Health check endpoint at `/health`
- Serves SunCalc as the default route (`/`)

### Website Structure
The project is organized into several distinct categories:

#### Main Applications
- **SunCalc** (`websites/suncalc/`): Astronomical calculator using Google Maps API for location selection
- **Main Portal** (`websites/main/public/index.html`): "Distraction Central" - categorized menu system for all applications

#### Games (`websites/games/`)
- Standalone HTML5 games using JavaScript and p5.js library
- Games include: Asteroids, Flight Game, Guess Capitals, Kaleidoscope variants, Maze, Pacman, Snake, Space Invaders, Tetris, Word Search, Wordle
- Each game is self-contained with its own assets (images, sounds, scripts)

#### Educational Tools (`websites/EJ-EV/`)
- Interactive educational applications for children
- Includes: Animal Sounds Match, Alphabet Search, Bubbles, Scribble, Trace, Speak Text
- Each application has its own HTML, CSS, JavaScript, and media assets

#### Utilities (`websites/utility/`)
- Development and text processing tools
- Letter Frequency Counter and Local Storage utilities

### Shared Resources (`shared/`)
- **CSS**: Common stylesheets (`shared/css/main.css`)
- **JavaScript**: Shared libraries including p5.js and Eruda debugger
- **Images**: Common image assets
- **Templates**: Reusable HTML templates

### Configuration and Deployment
- **Scripts** (`scripts/`): Extensive collection of deployment, backup, and management scripts
- **Nginx Configuration**: Security-hardened configuration with SSL, rate limiting, and security headers
- **Environment**: Uses `.env` for sensitive configuration like Google Maps API keys

## Key Development Patterns

### Static File Serving
Most applications are standalone HTML files that can be served directly. The Express server primarily handles:
1. Static file serving for all websites
2. API endpoints for external service integration (Google Maps)
3. Development features like Eruda debugger integration

### Security Considerations
- API keys are served through server endpoints, not embedded in client code
- Nginx configuration includes comprehensive security headers and rate limiting
- Authentication is configured for sensitive areas like `/docs/` and `/nodejs/`

### Asset Organization
- Each application maintains its own assets (images, sounds, scripts) in subdirectories
- Shared resources (p5.js, Eruda) are centralized in `/shared/js/`
- Games use consistent file organization patterns

### File Permissions
**IMPORTANT:** When adding new files to `websites/` directories, ensure proper permissions for Nginx to serve them:
- Use `chmod 660` for HTML, CSS, JS files (read/write for owner and group)
- Command: `chmod 660 /path/to/newfile.html`
- Verify with: `ls -la /path/to/newfile.html`
- Correct format: `-rw-rw----` (660)
- Without group read permissions, Nginx will return 403 Forbidden errors

### Environment Setup
The server requires:
- Node.js 14.0.0 or higher
- Google Maps API key in environment variables
- Optional: Nginx for production deployment with SSL certificates

### SSL Certificate Management
The production deployment uses Let's Encrypt certificates managed by certbot:

**Certificate Details:**
- `probiz.duckdns.org` — config: `/etc/nginx/conf.d/probiz.conf`, webroot: `/home/opc/ProBiz/websites/main/public`
- `help.pojammaapps.com` — config: `/etc/nginx/conf.d/jsoneditor-help.conf`, webroot: `/var/www/letsencrypt`
- Certificates stored in `/etc/letsencrypt/live/<domain>/`
- Expires: Every 90 days (automatically renewed)
- Challenge method: HTTP-01 via webroot

**Auto-Renewal:**
- Cron job runs daily at 2 AM: `0 2 * * * /usr/local/bin/certbot renew --quiet --nginx`
- Manual renewal: `sudo /usr/local/bin/certbot renew`
- Force immediate renewal: `sudo /usr/local/bin/certbot renew --cert-name <domain> --force-renewal --no-random-sleep-on-renew`
- Test renewal: `sudo /usr/local/bin/certbot renew --dry-run`

**Nginx ACME Challenge Configuration:**
Both nginx configs require two things for Let's Encrypt HTTP-01 validation to work:
1. **HTTP block**: A `location /.well-known/acme-challenge/` with the correct webroot `root` directive (must match the certbot `[[webroot_map]]` in `/etc/letsencrypt/renewal/<domain>.conf`)
2. **HTTPS block**: A `location ^~ /.well-known/acme-challenge/` **before** the `location ~ /\.` hidden files deny rule — the `^~` prefix ensures it takes priority over the regex deny

Without the HTTPS exception, the HTTP-to-HTTPS redirect causes Let's Encrypt to hit the hidden files deny rule and get a 403.

**Important Notes:**
- DuckDNS must point to correct server IP for HTTP-01 challenges to work
- Certificate files are symlinked and auto-updated during renewal
- Do not use `\$` in nginx `return` directives — it produces a literal backslash in the redirect URL

## Development Workflow
1. **ALWAYS create a new branch before making changes** - Use `git checkout -b feature/description` after any commit
2. Most changes involve editing standalone HTML applications
3. For SunCalc or API changes, modify `src/server.js` and restart with `npm run dev`
4. Static assets are served directly without build process
5. Don't use scripts in `scripts/` directory as they are for me.

## End-of-Session Protocol
At the end of every session, always:
1. **Update `sessions.md`** in the project root — add a new entry using the date and time as the session header (e.g., `## Session: YYYY-MM-DD HH:MM GMT`) with a summary of what was done
2. **Commit and push to GitHub** — include `sessions.md` and any other modified files