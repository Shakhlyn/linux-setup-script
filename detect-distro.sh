#!/bin/bash

# =======================================
# It detects the distro the user is using
# =======================================

source ./lib-logger.sh

detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        log_info "You are using: $DISTRO distro"
    else
        log_error "Cannot detect Linux distro!"
        log_info "Only Ubuntu, Lubuntu Fedora are supported"
        return 1
    fi
}

