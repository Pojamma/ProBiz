#!/usr/bin/env bash
set -euo pipefail

#------------------------------------------------------------------------------
# setup-ol9.sh  —  Bootstrap an Oracle Linux 9 server (Always Free friendly)
# Run as:  sudo ./setup-ol9.sh
#------------------------------------------------------------------------------

# ---- Settings you may tweak -------------------------------------------------
TZ_ZONE="America/Los_Angeles"
USER_NAME="${SUDO_USER:-opc}"         # whoever invoked sudo
USER_HOME="$(getent passwd "$USER_NAME" | cut -d: -f6)"
SSH_CONFIG="/etc/ssh/sshd_config"
DNF_CONF="/etc/dnf/dnf.conf"
F2B_JAIL="/etc/fail2ban/jail.local"

# ---- Helper -----------------------------------------------------------------
log() { echo -e "\e[32m==>\e[0m $*"; }

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || { echo "Missing $1"; exit 1; }
}

# ---- 1. System update & dnf tuning -----------------------------------------
log "Updating system & enabling fastest mirror / parallel downloads..."
# ensure dnf-plugins-core present
dnf install -y dnf-plugins-core

# tune dnf.conf if not already set
grep -q '^fastestmirror=' "$DNF_CONF" 2>/dev/null || {
  sudo tee -a "$DNF_CONF" >/dev/null <<EOF
fastestmirror=True
max_parallel_downloads=10
EOF
}

dnf clean all
dnf makecache -y --refresh
dnf update -y

# ---- 2. Install core packages ----------------------------------------------
log "Installing core packages..."
dnf install -y \
  vim nano git curl wget htop tmux unzip zip tree net-tools lsof \
  bash-completion firewalld fail2ban policycoreutils-python-utils

# ---- 3. Firewalld basic rules ----------------------------------------------
log "Configuring firewalld (ssh/http/https)..."
systemctl enable --now firewalld
firewall-cmd --permanent --add-service=ssh
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --reload

# ---- 4. SSH hardening -------------------------------------------------------
log "Hardening SSH (disable root/password login)..."
cp -n "$SSH_CONFIG" "${SSH_CONFIG}.bak.$(date +%F-%H%M%S)" || true
sed -i \
  -e 's/^#\?PermitRootLogin .*/PermitRootLogin no/' \
  -e 's/^#\?PasswordAuthentication .*/PasswordAuthentication no/' \
  "$SSH_CONFIG"
systemctl reload sshd

# ---- 5. Fail2Ban basic jail -------------------------------------------------
log "Configuring Fail2Ban for sshd..."
if [ ! -f "$F2B_JAIL" ]; then
  tee "$F2B_JAIL" >/dev/null <<'EOF'
[sshd]
enabled  = true
port     = ssh
filter   = sshd
logpath  = /var/log/secure
maxretry = 5
EOF
fi
systemctl enable --now fail2ban

# ---- 6. Timezone ------------------------------------------------------------
log "Setting timezone to ${TZ_ZONE}..."
timedatectl set-timezone "$TZ_ZONE"

# ---- 7. User shell customizations ------------------------------------------
log "Adding aliases & bash-completion to ${USER_NAME}'s .bashrc..."
BRC="${USER_HOME}/.bashrc"
grep -q "## BEGIN OL9 BOOTSTRAP" "$BRC" 2>/dev/null || cat <<'EOF' >> "$BRC"

## BEGIN OL9 BOOTSTRAP ########################################################
export EDITOR=vim
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias gs='git status'
alias gd='git diff'
alias v='vim'

# bash completion
[ -f /etc/bash_completion ] && . /etc/bash_completion
## END OL9 BOOTSTRAP ##########################################################
EOF

# Ensure ownership (in case we appended as root)
chown "$USER_NAME":"$USER_NAME" "$BRC"

# ---- 8. Final summary -------------------------------------------------------
log "All done!"
echo "
Quick checks:

  sudo dnf history list | head -n5
  systemctl is-active firewalld && sudo firewall-cmd --list-services
  sudo grep '^PermitRootLogin' $SSH_CONFIG
  sudo grep '^PasswordAuthentication' $SSH_CONFIG
  systemctl is-active fail2ban && sudo fail2ban-client status sshd
  timedatectl | grep 'Time zone'
  tail -n20 $BRC

Re-login or run:  source ~/.bashrc
"
