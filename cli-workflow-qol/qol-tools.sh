#!/bin/bash

# Should be installed in the later phase; after installing the programming languages(pip is required, which requires python)
# quality-of-life tools: htop', neofetch', strace', tree', ripgrep', fdk-find', fzf', bat', thefuck'

set -u

#LOG_FILE="$HOME/qol-install.log"

# ---------- Colors ----------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ---------- Logging ----------
log() {
    echo -e "${BLUE}[INFO]${NC} $1"
#    echo "[INFO] $1" >> "$LOG_FILE"
}

success() {
    echo -e "${GREEN}[OK]${NC} $1"
#    echo "[OK] $1" >> "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
#    echo "[WARN] $1" >> "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
#    echo "[ERROR] $1" >> "$LOG_FILE"
}

# ---------- Pre-flight ----------
if [[ "$EUID" -eq 0 ]]; then
    error "Do NOT run this script as root."
    exit 1
fi

log "Starting Quality-of-Life tools installation"
#log "Log file: $LOG_FILE"

# ---------- Helpers ----------
command_exists() {
    command -v "$1" &>/dev/null
}

apt_install() {
    local pkg="$1"
    local cmd="${2:-$1}"

    if command_exists "$cmd"; then
        warn "$pkg already installed"
        return
    fi

    log "Installing $pkg..."
    if sudo apt install -y "$pkg" >>"$LOG_FILE" 2>&1; then
        success "$pkg installed"
    else
        error "Failed to install $pkg"
    fi
}

# ---------- System Update ----------
log "Updating package lists..."
if sudo apt update >>"$LOG_FILE" 2>&1; then
    success "System updated"
else
    error "apt update failed"
fi

# ---------- Core Tools ----------
apt_install htop
apt_install tree
apt_install ripgrep rg
apt_install fd-find fd
apt_install bat batcat
apt_install fzf
apt_install jq
apt_install httpie http
apt_install neofetch
apt_install redis-tools redis-cli
apt_install postgresql-client psql
apt_install strace
apt_install thefuck fuck


TOOLS=(
    "htop              htop"
    "tree              tree"
    "ripgrep           rg"
    "fd-find           fd"
    "bat               batcat"
    "fzf               fzf"
    "jq                jq"
    "httpie            http"
    "neofetch          neofetch"
    "redis-tools       redis-cli"
    "postgresql-client psql"
    "strace            strace"
    "thefuck           fuck"
)

log "Installing command-line tools..."
update_apt

for entry in "${TOOLS[@]}"; do
    read -r pkg cmd <<< "$entry"
#    It takes the content of the variable $entry, splits it on whitespace (spaces, tabs),
#    and assigns the resulting words to the variables pkg and cmd.

    apt_install "$pkg" "$cmd"
done

log_success "Tool installation complete!"

# ---------- LazyGit ----------
if command_exists lazygit; then
    warn "lazygit already installed"
else
    log "Installing lazygit..."
    if sudo apt install -y lazygit >>"$LOG_FILE" 2>&1; then
        success "lazygit installed"
    else
        error "Failed to install lazygit"
    fi
fi

# ---------- ctop ----------
if command_exists ctop; then
    warn "ctop already installed"
else
    log "Installing ctop..."
    if sudo apt install -y ctop >>"$LOG_FILE" 2>&1; then
        success "ctop installed"
    else
        error "Failed to install ctop"
    fi
fi

# ---------- Aliases ----------
log "Configuring shell aliases..."

ZSHRC="$HOME/.zshrc"

if [[ -f "$ZSHRC" ]]; then
    grep -q "alias cat=" "$ZSHRC" || echo "alias cat='batcat'" >> "$ZSHRC"
    grep -q "alias ll=" "$ZSHRC" || echo "alias ll='ls -alF'" >> "$ZSHRC"
    success "Aliases added to .zshrc"
else
    warn ".zshrc not found, skipping aliases"
fi

# ---------- fzf key bindings ----------
if command_exists fzf; then
    log "Enabling fzf key bindings..."
    /usr/share/doc/fzf/examples/install --key-bindings --completion --no-update-rc >>"$LOG_FILE" 2>&1 || \
        warn "fzf bindings setup skipped"
fi

# ---------- Summary ----------
echo
echo -e "${GREEN}================ INSTALLATION COMPLETE ================${NC}"
echo "✔ Logs saved to: $LOG_FILE"
echo "✔ Script is safe to re-run"
echo
echo "Restart terminal or run:"
echo "  source ~/.zshrc"
echo -e "${GREEN}========================================================${NC}"

