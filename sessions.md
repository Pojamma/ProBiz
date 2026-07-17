# ProBiz Session Log

---

## Session 2026-07-17 15:30 PDT

### Post-Migration Cleanup
- Created minimal "Welcome to ProBiz" landing page at `websites/main/public/index.html`
- Deployed new landing page to ProBiz server (144.24.7.55)
- Removed old game/app files from ProBiz server (`websites/games/`, `EJ-EV/`, `utility/`, `shared/`)
- Updated `CLAUDE.md` to reflect that ProBiz is now a minimal landing page server (removed all game/app/shared resource docs, updated architecture section)
- Updated home `~/CLAUDE.md` to add DisCen project entry and update ProBiz description

### Commits
- `d308a7b` — Add minimal ProBiz landing page

---

## Session 2026-07-17 14:50 PDT

### Migration to DisCen

Migrated all web applications from ProBiz to a new DisCen (Distraction Central) project on a larger Oracle A1 ARM instance (129.146.103.78, 6GB RAM).

**What moved to DisCen:**
- `websites/` (~31MB) — main portal, games, EJ-EV educational tools, utilities
- `shared/` (~1.5MB) — CSS, JS libraries (p5.js, Eruda)

**What stayed in ProBiz:**
- `src/server.js` — minimal health-check server
- `scripts/`, `nginx_copy/` — legacy deployment scripts and reference configs
- Git history, `sessions.md`, `CLAUDE.md`

**DisCen server setup:**
- Node.js v24.18, Nginx 1.20.1, Certbot 3.1.0, Fail2Ban
- SSL cert for `distractioncentral.duckdns.org` (expires 2026-10-15)
- Systemd service for Node.js health check
- SELinux configured for nginx to serve from /home/opc/DisCen
- GitHub repo: https://github.com/Pojamma/DisCen (commit `89851f3`)

**Removed from ProBiz locally:**
- All contents of `websites/` and `shared/` directories

---

## Session: 2026-06-08 GMT

### Game File Permissions Audit
- Checked permissions on all files in `websites/games/`
- Fixed 5 files with incorrect permissions to `660`:
  - `Blues_Jam_Gemini.html`: `644` → `660`
  - `kids_drawing_pad.html`: `771` → `660`
  - `kitten-pop-bugs.html`: `644` → `660`
  - `minecraft_command_builder_chatgpt.html`: `644` → `660`
  - `minecraft-command-builder-claude.html`: `644` → `660`

### Committed & Pushed
- Commit `7cfed73` — Remove executable bit from kids_drawing_pad.html

---

## Session: 2026-06-07 GMT

### New Games Review & Fix
- Reviewed 3 new games added by user: Kitten Pop Bugs, Minecraft Command Builder (Claude), Minecraft Command Builder (ChatGPT)
- Fixed typo in `index.html`: `catagory` → `category` on the Kitten Pop Bugs entry
- Fixed incorrect paths for both Minecraft entries: added missing `games/` prefix
- All three game files are well-structured, self-contained HTML apps

### Committed & Pushed
- Commit `efa1912` — Add kitten pop bugs and minecraft command builder games

---

## Session: 2026-03-27 GMT

### SunCalc Removal
- Removed SunCalc menu entry from `websites/main/public/index.html`
- Deleted entire `websites/suncalc/` directory (including API key file and all app files)
- Updated `src/server.js`: removed `/api/maps-key` Google Maps endpoint and SunCalc default route (`/`)
- Updated `package.json`: removed "suncalc" from description, keywords, and npm scripts
- Updated `CLAUDE.md`: removed all SunCalc references from architecture docs

---

## Session: 2026-02-28 02:30 GMT

### Weather App Removal
- Confirmed no weather server, directory (`websites/Weather/`), or nginx config existed — the app was already largely gone
- Removed the two remaining commented-out weather menu entries from `websites/main/public/index.html`

### System Health Check
- **Disk**: Fine — 18 GB free on root partition (41% used)
- **Memory**: Critical — only 6 MB free RAM on a 503 MB Oracle Free Tier AMD micro instance
- **Root cause of hangs**: Claude sessions consume ~144 MB (29% of total RAM); Oracle cloud agents consume another ~46 MB combined, pushing the system into swap
- **CPU steal**: 59% observed — Oracle hypervisor throttling the VM heavily (common on free tier AMD instances)
- **Node.js server** (`src/server.js`): Very lean at only 4 MB — not a contributing factor
- **Swap**: 278 MB / 2.9 GB used — system was actively swapping during session
- **Recommendation**: No manual cleanup needed after closing Claude; OS reclaims memory automatically. Consider migrating to Oracle Ampere A1 ARM free tier (up to 24 GB RAM)

### Committed & Pushed
- Commit `ba0a700` — removed weather app references and updated CLAUDE.md SSL docs
