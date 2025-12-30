#!/bin/bash

# -----------------------------
# Logging Configuration
# -----------------------------

# Colors
RESET='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'

# Bold colors
BRED='\033[1;31m'
BGREEN='\033[1;32m'
BYELLOW='\033[1;33m'
BBLUE='\033[1;34m'
BPURPLE='\033[1;35m'
BCYAN='\033[1;36m'


# -----------------------------
# Core logging function
# -----------------------------

_log() {
    local level="$1"
    local color="$2"
    local message="$3"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # Colored output to terminal
    echo -e "${color}[$level]${RESET} $message"

    # Plain text to the text file
    case "$level" in
    "SUCCESS")
        echo "[$timestamp] [$level] $message" >> "${LOG_FILES[log]}"
        echo "[$timestamp] [$level] $message" >> "${LOG_FILES[success]}"
        ;;
    "ERROR")
        echo "[$timestamp] [$level] $message" >> "${LOG_FILES[log]}"
        echo "[$timestamp] [$level] $message" >> "${LOG_FILES[error]}"
        ;;
    "CONFIRM")
        echo "[$timestamp] [$level] $message" >> "${LOG_FILES[log]}"
        ;;
    esac
}

# -----------------------------
# Public logging functions
# -----------------------------

log_info()    { _log "INFO"    "$BLUE"   "$*"; }
log_success() { _log "SUCCESS" "$GREEN"  "$*"; }
log_warn()    { _log "WARN"    "$YELLOW" "$*"; }
log_error()   { _log "ERROR"   "$RED"    "$*"; }
log_confirm() { _log "CONFIRM" "$CYAN"   "$*"; }

## Optional: A debug function (can be enabled/disabled)
#DEBUG_MODE=${DEBUG_MODE:-0}
#log_debug() {
#    if [[ $DEBUG_MODE -eq 1 ]]; then
#        _log "DEBUG" "$PURPLE" "$*"
#    fi
#}


script_divider() {
    echo -e "${PURPLE}      ================================      ${RESET}\n\n";
}
