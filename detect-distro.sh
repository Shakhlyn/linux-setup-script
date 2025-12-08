#!/bin/bash

# =======================================
# It detects the distro the user is using
# =======================================

source ./lib-logger.sh

detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
#        echo "$DISTRO"
        log_info "You are using: $DISTRO distro"
        return 0
    else
        log_info "Only Ubuntu, Lubuntu, and Fedora are supported"
        return 1
    fi
}

