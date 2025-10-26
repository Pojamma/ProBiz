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

### Environment Setup
The server requires:
- Node.js 14.0.0 or higher
- Google Maps API key in environment variables
- Optional: Nginx for production deployment with SSL certificates

## Development Workflow
1. **ALWAYS create a new branch before making changes** - Use `git checkout -b feature/description` after any commit
2. Most changes involve editing standalone HTML applications
3. For SunCalc or API changes, modify `src/server.js` and restart with `npm run dev`
4. Static assets are served directly without build process
5. Don't use scripts in `scripts/` directory as they are for me.