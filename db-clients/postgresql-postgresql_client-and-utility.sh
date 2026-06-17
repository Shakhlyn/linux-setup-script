#!/bin/bash

set -uo pipefail

source ./utils/lib-logger.sh
source ./utils/utils.sh

check_dpkg_health() {
    if sudo dpkg --audit | grep -q .; then
        log_warn "Package issues detected. Attempting repair..."
        sudo dpkg --configure -a
        sudo apt --fix-broken install -y
    fi
}

ensure_postgres_running() {
    if systemctl is-active --quiet postgresql; then
        log_confirm "PostgreSQL service already running"
        return 0
    fi

    sudo systemctl enable --now postgresql

    if systemctl is-active --quiet postgresql; then
        log_success "PostgreSQL service started"
        return 0
    fi

    log_error "Could not start PostgreSQL"
    return 1
}

verify_client() {
    if is_installed 'psql' &>/dev/null; then
        log_success "psql available"
        psql --version
        return 0
    fi

    log_error "psql not found"
    return 1
}

verify_server() {
    verify_client || return 1

    sudo -u postgres psql -tAc "SELECT 1" >/dev/null 2>&1

    if [[ $? -eq 0 ]]; then
        log_success "PostgreSQL responding"
        return 0
    fi

    log_error "PostgreSQL verification failed"
    return 1
}

install_client_profile() {
    apt_install postgresql-client
    verify_client
}

install_server_profile() {
    apt_install postgresql
    apt_install postgresql-contrib

    ensure_postgres_running
    verify_server
}

install_postgresql_suit() {
    check_dpkg_health

    update_packages

    install_client_profile

    install_server_profile
}

