# ProBiz Session Log

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
