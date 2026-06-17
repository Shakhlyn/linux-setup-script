#!/bin/bash

set -uo pipefail

source ./utils/lib-logger.sh
source ./utils/utils.sh

APP_NAME="dbeaver-ce"

check_if_installed() {
    if command -v dbeaver &>/dev/null; then
        log_confirm "DBeaver already installed"
        return 0
    fi
    return 1
}

install_prereqs() {
    log_info "Installing prerequisites..."
    # sudo apt update
    update_packages
    sudo apt install -y wget gnupg ca-certificates
}

add_dbeaver_repo() {
    if [[ -f /etc/apt/sources.list.d/dbeaver.list ]]; then
        log_confirm "DBeaver repo already exists"
        return 0
    fi

    log_info "Adding DBeaver APT repository..."

    wget -O - https://dbeaver.io/debs/dbeaver.gpg.key | sudo gpg --dearmor -o /usr/share/keyrings/dbeaver.gpg

    echo "deb [signed-by=/usr/share/keyrings/dbeaver.gpg] https://dbeaver.io/debs/dbeaver-ce /" | \
        sudo tee /etc/apt/sources.list.d/dbeaver.list > /dev/null
}

install() {
    log_info "Installing DBeaver CE (APT)..."
    update_packages
    sudo apt install -y dbeaver-ce
}

verify() {
    if command -v dbeaver &>/dev/null; then
        log_success "DBeaver installed successfully"
        dbeaver --version || true
    else
        log_error "DBeaver installation failed"
        return 1
    fi
}

install_dbeaver() {
    if is_installed "dbeaver"; then
        log_info "DBeaver is already installed!"
        dbeaver --version || true
        return 0
    fi

    install_prereqs
    add_dbeaver_repo
    install
    verify
}



