#!/bin/bash

source ./lib-logger.sh

# Check if it is already installed
#is_installed() {
#    if command -v "$1" >/dev/null 2>&1; then
#        return 0
#    else
#        return 1
#    fi
#}


is_installed() {
    local target="$1"

    log_info "Checking for $target..."

    # Try different methods
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

    while ! sudo apt update -qq; do
        count=$((count + 1))
        if [[ $count -ge $retries ]]; then
            error_exit "Error: 'apt update' failed after $retries attempts." >&2
        fi
        log_error "apt update failed (attempt $count/$retries). Retrying in $delay seconds..."
        sleep $delay
    done
}


error_exit() {
  log_error "$1" >&2
  exit 1
}

