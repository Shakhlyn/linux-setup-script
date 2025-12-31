#!/bin/bash

#==================================================================
#script to install curl, wget, build-essential, ca-certificates
# Checks for already installed packages and logs status clearly
#==================================================================

source ./lib-logger.sh
source ./utils.sh


set -uo pipefail

PACKAGES=(make curl wget build-essential ca-certificates software-properties-common)

install_system_utilities() {
    for pkg in "${PACKAGES[@]}"; do
        if ! apt_install "$pkg"; then
            exit 1
        fi
    done
}
