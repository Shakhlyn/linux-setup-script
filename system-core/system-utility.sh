#!/bin/bash

#==================================================================
#script to install curl, wget, build-essential, ca-certificates
# Checks for already installed packages and logs status clearly
#==================================================================

source ./lib-logger.sh
source ./utils.sh


set -uo pipefail

PACKAGES=(curl wget build-essential ca-certificates software-properties-common)

install_system_utilities() {
    for pkg in "${PACKAGES[@]}"; do
        if is_installed "$pkg"; then
            log_confirm "$pkg is already installed. Skipping re-installation..."
        else
            log_info "Updating package lists..."
            update_apt

            log_info "Installing $pkg..."
            if ! sudo apt install "$pkg" -y; then
                error_exit "Couldn't install $pkg. Please try again later."
            fi

            log_success "$pkg Installation complete!"
        fi
    done
}
