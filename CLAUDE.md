# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ProBiz is a minimal Node.js/Express server that serves a simple landing page. All web applications (games, educational tools, utilities) that were previously hosted here have been migrated to the [DisCen](https://github.com/Pojamma/DisCen) project on a separate server at `distractioncentral.duckdns.org`.

## Development Commands

```bash
# Start the development server with auto-reload
npm run dev

# Start the production server
npm start
```

## Architecture

### Server Architecture (`src/server.js`)
- Express.js server with health check endpoint at `/health`
- Serves a minimal landing page from `websites/main/public/index.html`

### What's Here
- `src/server.js` — Express server (health check + static file serving)
- `websites/main/public/index.html` — "Welcome to ProBiz" landing page
- `scripts/` — Legacy deployment and management scripts
- `nginx_copy/` — Reference copy of the old nginx configuration

### What Moved to DisCen
All web applications were migrated to [DisCen](https://github.com/Pojamma/DisCen) in July 2026:
- Games (Asteroids, Tetris, Snake, Pacman, Wordle, etc.)
- Educational tools (EJ-EV: Animal Sounds Match, Alphabet Search, Bubbles, etc.)
- Utilities (Letter Frequency Counter, Local Storage)
- Shared resources (p5.js, Eruda, CSS)

## Deployment

### Server Details
- **Host**: Oracle Cloud AMD micro instance (144.24.7.55, 1GB RAM)
- **SSH**: `ssh probiz` (configured in ~/.ssh/config)
- **Domain**: `probiz.duckdns.org`
- **Web Server**: Nginx with Let's Encrypt SSL

### SSL Certificate Management
- Domain: `probiz.duckdns.org`
- Managed by certbot
- Auto-renewal via cron: `0 2 * * * /usr/local/bin/certbot renew --quiet --nginx`

## Development Workflow
1. **ALWAYS create a new branch before making changes** - Use `git checkout -b feature/description`
2. For server changes, modify `src/server.js` and restart with `npm run dev`
3. Don't use scripts in `scripts/` directory as they are for me.

## End-of-Session Protocol
At the end of every session, always:
1. **Update `sessions.md`** in the project root
2. **Commit and push to GitHub**
