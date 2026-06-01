#!/bin/bash

source ./utils/lib-logger.sh


error_exit() {
  log_error "$1" >&2
  exit 1
}


generate_log_files() {
    log_info "Setting up log directory and files..."

    # Check and create logs directory if it doesn't exist
    if [[ ! -d "$LOGS_DIR" ]]; then
        if ! mkdir -p "$LOGS_DIR"; then
            error_exit "Failed to create logs directory: $LOGS_DIR"
        fi
        log_info "Created logs directory: $LOGS_DIR"
    else
        log_info "Logs directory already exists: $LOGS_DIR"
    fi

    # Initialize (truncate/create) each log file
    for log_file in "${LOG_FILES[@]}"; do
        if ! : > "$log_file"; then
            error_exit "Failed to initialize log file: $log_file"
        fi
        log_info "Ready: $log_file"
    done

    log_info "All log files are ready in $LOGS_DIR"
}


is_installed() {
    local target="$1"

    log_info "Checking for $target ..."

    if command -v "$target" &> /dev/null; then
        log_info "Found in PATH: $(command -v "$target")"
        return 0
    fi

    if dpkg-query -W -f='${Status}' "$target" 2>/dev/null | grep -q "install ok installed"; then
        log_info "Installed via apt"
        return 0
    fi

    if snap list 2>/dev/null | grep -q "^$target "; then
        log_info "Installed via snap"
        return 0
    fi

    if flatpak list --app 2>/dev/null | grep -q -i "$target"; then
        log_info "Installed via flatpak"
        return 0
    fi

    # Check for pip packages (Python)
    if python3 -m pip show "$target" &> /dev/null; then
        log_info "Installed via pip"
        return 0
    fi

    return 1
}


update_apt() {
    local retries=5
    local delay=5
    local count=0

    log_info "Updating apt package indexes..."

    while ! sudo apt update -qq; do
        count=$((count + 1))
        if [[ $count -ge $retries ]]; then
            error_exit "Error: 'apt update' failed after $retries attempts." >&2
        fi
        log_error "apt update failed (attempt $count/$retries). Retrying in $delay seconds..."
        sleep $delay
    done

    log_success "apt package indexes updated successfully.\n"
}



# ─────────────────────────────────────────────────────────────────────────────
# update_dnf
# Refreshes the dnf package index with retry logic.
# ─────────────────────────────────────────────────────────────────────────────
 
update_dnf() {
    local retries=5
    local delay=5
    local count=0
 
    log_info "Updating dnf package cache..."
 
    while ! sudo dnf makecache -q; do
        count=$((count + 1))
        if [[ $count -ge $retries ]]; then
            error_exit "'dnf makecache' failed after $retries attempts. Check your internet connection."
        fi
        log_error "dnf makecache failed (attempt $count/$retries). Retrying in ${delay}s..."
        sleep "$delay"
    done
 
    log_success "dnf package cache updated.\n"
}

# ─────────────────────────────────────────────────────────────────────────────
# update_packages
# Distro-aware wrapper. Call this from main.sh instead of update_apt directly.
# ─────────────────────────────────────────────────────────────────────────────
 
update_packages() {
    case "${DISTRO:-}" in
        ubuntu | lubuntu | pop)
            update_apt
            ;;
        fedora)
            update_dnf
            ;;
        *)
            error_exit "update_packages: Unsupported distribution '${DISTRO:-unset}'."
            ;;
    esac
}



apt_install() {
    local pkg="$1"
    local cmd="${2:-$1}"

    if is_installed "$cmd"; then
        log_confirm "$pkg is already installed. Skipping re-installation..."
        return 0
    fi

    log_info "Installing $pkg..."
    if ! sudo apt install "$pkg" -y; then
        log_error "Couldn't install $pkg. Please try again later."
        return 1
    fi

    echo ""
    log_success "$pkg Installation complete\n"
}



get_shell_rc_file() {
    local shell_config=""
    local default_shell

    default_shell=$(basename "$SHELL")

    if [[ "$default_shell" == "zsh" ]]; then
        shell_config="$HOME/.zshrc"
    elif [[ "$default_shell" == "bash" ]]; then
        shell_config="$HOME/.bashrc"
    else
        error_exit "Only BASH or ZSH shell can use this script."
    fi

    echo "${shell_config}"
}

