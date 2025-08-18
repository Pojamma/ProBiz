
export PATH=$PATH:$HOME/execs
export PATH=$PATH:$HOME/NewBiz/execs
export PATH=$PATH:$HOME/ProBiz/scripts

# green prompt showing directory
PS1='\[\033[0;32m\]\w\[\033[0m\]>'

# pretty print json
ppjj() {
  jq . "${1}.json"
}
ppj() {
  jq -M . "$1"
}

clip() {
  cat "$1" | termux-clipboard-set
}
export -f clip

# Copy a file’s contents into the Termux clipboard:
cpclip() {
  if [ -z "$1" ]; then
    echo "Usage: cpclip <file>"
    return 1
  fi
  if [ ! -r "$1" ]; then
    echo "cpclip: cannot read '$1'"
    return 1
  fi
  termux-clipboard-set < "$1"
}

# ========== alias ==========

alias ap='apachectl'
alias ba='backupall'
alias ba1='alias > alias.bak'
alias ba2='cp .bashrc bashrc.bak'
alias backupall='rsync -a --exclude ".*" --exclude "node_modules" --exclude "/storage/" ~/ /storage/emulated/0/termux-backup/termux-backup-$(date "+%Y-%m-%d-%H-%M-%S")/'
alias c='clear'
alias cdapache='cd /data/data/com.termux/files/usr/etc/apache2'
alias cds='cd $HOME/storage/shared'
alias cdapps='cd $HOME/storage/shared/myApps'
alias cdnb='cd $HOME/storage/shared/myApps/NewBiz'
alias cdnbj='echo "Hey handsome, R U High? that command only works on Oracle. You are on Termux now!  Hello?!?!?!"'
alias cdnbp='cd $HOME/storage/shared/myApps/NewBiz/public'
alias cdnbpj='cd $HOME/storage/shared/myApps/NewBiz/public/js'
alias cdnbr='cd $HOME/storage/shared/myApps/NewBiz/routes'


# ────────────────────────────────────────────────────────
# Conditional cdnb alias: Termux vs. “normal” Linux
# ────────────────────────────────────────────────────────
# If we're on Termux, the termux‑info command will exist
if command -v termux‑info >/dev/null 2>&1; then
  # Termux on Android
  alias cdnb='cd $HOME/storage/shared/myApps/NewBiz'
else
  # Otherwise assume your Oracle Linux instance
  alias cdnb='cd $HOME/NewBiz'
fi
alias cdbak='cd $HOME/storage/shared/Backups/"termux_backup_2024-12-10_20-12-14 Google drive from cell phone"/termux_backup_2024-12-10_20-12-14'
alias cpfo='copy_file.sh'
alias cpm="copy_menu.sh"
alias cl='clear;lss'
alias dspj='ps aux | grep node'
alias e='exit'
alias eb='nano $HOME/docs/bobnotes.txt'
alias es='nano ~/.bashrc'
alias ff='js-beautify -r '
alias ffp='prettier --write '
alias h='history'
alias ip='ip -br a'
alias l='ls -CF'
alias ll='ls -alF'
alias lsl="ls -l | awk '{print \$1, \$6, \$7, \$8, \$2, \$5,\$9}'"
alias lsn='exa --long --group-directories-first --git --time-style=long-iso --classify --color=always --header --sort=modified | awk "{print \$1,\$5,\$6,\$7,\$8}" | column -t'
alias lss='ls -l | awk '\''{print $1, $2, $5, $9}'\'' | sort -r'
alias lssp='stat -c '\''%n %y'\'' $(find $PREFIX -type f -name '\''*.list'\'' -print) | sort -k 2 | awk '\''{sub(/.*\//, "", $1); sub(/\.[^\.]*$/, "", $2); print $2, $1}'\'''
alias m='less'
alias md='mkdir'
alias n='nano'
alias py='python'
alias rs='python -m http.server'
alias rmlogs='rm /data/data/com.termux/files/home/logs/*.log'
alias sf='/data/data/com.termux/files/home/NewBiz/execs/search_files.sh'
alias sq='mariadb -u root -p -D biz1_db'
alias sq1='mysqld_safe &'
alias ssho='ssh oracle-instance'
alias ssho1='ssh oracle-instance-probiz'
alias t='tmux'
alias treetxt="tree -I 'node_modules|node' > tree.txt"
alias treetxt1='tree -I "node_modules|dist|build" -D -s > tree.txt'
alias treetxtd='tree -I "node_modules|dist|build" -D -s > tree_$(date +%Y%m%d_%H%M%S).txt'
alias upd='apt update && apt upgrade'
alias ss='cd ~/NewBiz && nohup node src/server.js > app.log 2>&1 &'

# ProBiz aliases
alias upload="~/scripts/upload-to-server.sh"
alias dev="~/scripts/dev-helper.sh"
alias probiz="cd ~/ProBiz"
alias gopb='ssh oracle-instance-probiz'

# =========== Shared directories ============

# ProBiz Directory Navigation Aliases

# Main ProBiz directory
alias cdpb='cd $HOME/storage/shared/myApps/ProBiz'

# Websites directory structure
alias cdpbw='cd $HOME/myApps/ProBiz/websites'
alias cdpbwm='cd $HOME/myApps/ProBiz/websites/main'
alias cdpbwmp='cd $HOME/myApps/ProBiz/websites/main/public'
alias cdpbwms='cd $HOME/myApps/ProBiz/websites/main/src'
alias cdpbwmc='cd $HOME/myApps/ProBiz/websites/main/config'
alias cdpbwp1='cd $HOME/myApps/ProBiz/websites/project1'
alias cdpbwp2='cd $HOME/myApps/ProBiz/websites/project2'
alias cdpbwg='cd $HOME/myApps/ProBiz/websites/games'
alias cdpbwgg1='cd $HOME/myApps/ProBiz/websites/games/game1'
alias cdpbwgg2='cd $HOME/myApps/ProBiz/websites/games/game2'

# Node.js directory structure
alias cdpbn='cd $HOME/myApps/ProBiz/nodejs'
alias cdpbna='cd $HOME/myApps/ProBiz/nodejs/api-server'
alias cdpbnw='cd $HOME/myApps/ProBiz/nodejs/websocket-apps'
alias cdpbnu='cd $HOME/myApps/ProBiz/nodejs/utilities'

# Shared resources directory structure
alias cdpbs='cd $HOME/myApps/ProBiz/shared'
alias cdpbsc='cd $HOME/myApps/ProBiz/shared/css'
alias cdpbsj='cd $HOME/myApps/ProBiz/shared/js'
alias cdpbsi='cd $HOME/myApps/ProBiz/shared/images'
alias cdpbst='cd $HOME/myApps/ProBiz/shared/templates'

# Other main directories
alias cdpbscr='cd $HOME/myApps/ProBiz/scripts'
alias cdpbl='cd $HOME/myApps/ProBiz/logs'
alias cdpbb='cd $HOME/myApps/ProBiz/backups'
alias cdpbd='cd $HOME/myApps/ProBiz/docs'

# =========== Shared directories ============

# Main ProBiz directory
alias cdspb='cd $HOME/storage/shared/myApps/ProBiz'

# Websites directory structure
alias cdspbw='cd $HOME/storage/shared/myApps/ProBiz/websites'
alias cdspbwm='cd $HOME/storage/shared/myApps/ProBiz/websites/main'
alias cdspbwmp='cd $HOME/storage/shared/myApps/ProBiz/websites/main/public'
alias cdspbwms='cd $HOME/storage/shared/myApps/ProBiz/websites/main/src'
alias cdspbwmc='cd $HOME/storage/shared/myApps/ProBiz/websites/main/config'
alias cdspbwp1='cd $HOME/storage/shared/myApps/ProBiz/websites/project1'
alias cdspbwp2='cd $HOME/storage/shared/myApps/ProBiz/websites/project2'
alias cdspbwg='cd $HOME/storage/shared/myApps/ProBiz/websites/games'
alias cdspbwgg1='cd $HOME/storage/shared/myApps/ProBiz/websites/games/game1'
alias cdspbwgg2='cd $HOME/storage/shared/myApps/ProBiz/websites/games/game2'

# Node.js directory structure
alias cdspbn='cd $HOME/storage/shared/myApps/ProBiz/nodejs'
alias cdspbna='cd $HOME/storage/shared/myApps/ProBiz/nodejs/api-server'
alias cdspbnw='cd $HOME/storage/shared/myApps/ProBiz/nodejs/websocket-apps'
alias cdspbnu='cd $HOME/storage/shared/myApps/ProBiz/nodejs/utilities'

# Shared resources directory structure
alias cdspbs='cd $HOME/storage/shared/myApps/ProBiz/shared'
alias cdspbsc='cd $HOME/storage/shared/myApps/ProBiz/shared/css'
alias cdspbsj='cd $HOME/storage/shared/myApps/ProBiz/shared/js'
alias cdspbsi='cd $HOME/storage/shared/myApps/ProBiz/shared/images'
alias cdspbst='cd $HOME/storage/shared/myApps/ProBiz/shared/templates'

# Other main directories
alias cdspbscr='cd $HOME/storage/shared/myApps/ProBiz/scripts'
alias cdspbl='cd $HOME/storage/shared/myApps/ProBiz/logs'
alias cdspbb='cd $HOME/storage/shared/myApps/ProBiz/backups'
alias cdspbd='cd $HOME/storage/shared/myApps/ProBiz/docs'


