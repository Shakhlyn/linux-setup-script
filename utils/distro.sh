#!/bin/bash

# =======================================
# It detects the distro the user is using
# =======================================

source ./utils/lib-logger.sh

detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        echo "${DISTRO}"
        return 0
    else
        error_exit "Couldn't detect you distro! Please try again later"
    fi
}


is_supported_distro() {
    local distro="$1"
    case "$distro" in
        ubuntu|lubuntu|pop|fedora) return 0 ;;
        *) return 1 ;;
    esac
}


