#!/bin/bash

set -uo pipefail

source ./utils/lib-logger.sh
source ./utils/utils.sh


install_prereqs() {
    log_info "Installing prerequisites..."
    update_packages
    install_packages wget gnupg ca-certificates
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
    install_packages dbeaver-ce
}

verify() {
    if is_installed dbeaver &>/dev/null; then
        log_success "DBeaver installed successfully"
        dbeaver --version || true
    else
        log_error "DBeaver installation failed"
        return 1
    fi
}

install_dbeaver() {
    if is_installed "dbeaver"; then
        log_confirm "DBeaver is already installed!"
        dbeaver --version || true
        return 0
    fi

    install_prereqs
    add_dbeaver_repo
    install
    verify
}



