#!/bin/bash

source ./lib-logger.sh


generate_log_files() {
    log_info "Setting up log directory and files..."

    # Check and create logs directory if it doesn't exist
    if [[ ! -d "$LOGS_DIR" ]]; then
        if ! mkdir -p "$LOGS_DIR"; then
            log_info "Failed to create logs directory: $LOGS_DIR"
            exit 1
        fi
        log_info "Created logs directory: $LOGS_DIR"
    else
        log_info "Logs directory already exists: $LOGS_DIR"
    fi

    # Initialize (truncate/create) each log file
    for log_file in "${LOG_FILES[@]}"; do
        if ! : > "$log_file"; then
            log_info "Failed to initialize log file: $log_file"
            exit 1
        fi
        log_info "Ready: $log_file"
    done

    log_info "All log files are ready in $LOGS_DIR"
}


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

