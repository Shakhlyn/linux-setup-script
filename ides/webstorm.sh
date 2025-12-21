#!/bin/bash

source ./lib-logger.sh
source ./utils.sh

APP_NAME="webstorm"

check_if_snap_installed() {
    if ! command -v snap &> /dev/null; then
        log_warn "snap is not installed in your system!"
        log_info "Installing snap...\n"

        sudo apt update
        echo "\n"
        sudo apt install -y snapd

        if [[ "$?" -eq 0 ]]; then
            log_success "Successfully installed snap"
        else
            error_exit "Couldn't install snap. Check your internet connection. Try again later."
        fi
    else
        log_confirm "snap is already installed in your system."
        return 0
    fi
}

check_if_snapd_is_running() {
    if ! systemctl is-active --quiet snapd.service; then
        log_warn "Snap service is not active. Activating..."
        sudo systemctl start snapd.service
        if [[ "$?" -eq 0 ]]; then
            log_success "Snapd service is activated"
            return 0
        else
            log_warn "Couldn't activate the snapd service! Please try again later"
            return 1
        fi
    else
        log_info "Snapd service is active."
        return 0
    fi
}

check_if_webstorm_installed() {
    if sudo snap list | grep -q "^$APP_NAME "; then
        INSTALLED_VERSION=$(snap list | awk "/^$APP_NAME / {print \$2}")
        log_confirm "$APP_NAME is already installed (version: $INSTALLED_VERSION)."

        read -r -p "Re-install/Update Webstorm? (Y/N): " ANSWER

        if [[ "$ANSWER" == "n" || "$ANSWER" == "N" ]]; then
            log_warn "Aborted"
            return 1
        elif [[ "$ANSWER" == "y" || "$ANSWER" == "Y" ]]; then
            log_info "Removing old version..."
            sudo snap remove "$APP_NAME"
            return 0
        fi
    fi
}


install_webstorm_on_ubuntu() {
    log_info "Installing Webstorm...\n"
    sudo snap install "$APP_NAME" --classic
    if [[ "$?" -eq 0 ]]; then
        log_success "Webstorm is installed successfully!!!"
        return 0
    else
        log_Error "Couldn't install $APP_NAME. Something went wrong"
        return 1
    fi
}


install_webstorm() {
    if check_if_snap_installed; then
        if check_if_snapd_is_running; then
            if check_if_webstorm_installed; then
                if install_webstorm_on_ubuntu; then
                    return 0
                fi
            fi
        fi
    fi
}
