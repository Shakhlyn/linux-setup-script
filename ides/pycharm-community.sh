#!/bin/bash

source ./lib-logger.sh
source ./utils.sh

install_pycharm_on_fedora() {
    flatpak install flathub com.jetbrains.PyCharm-Community
}

install_pycharm_on_ubuntu() {
    sudo snap install pycharm-community --classic
}

install_pycharm_community() {
    local pycharm="pycharm-community"

    if is_installed "$pycharm"; then
        log_info "Hurrah! $pycharm is already installed in this system"
        log_info "You can launch it using 'pycharm-community'"
        log_warn "Concluding this process since there is no need to install again"
        
        return 0
    fi
        

    log_info "'Pycharm-community' is not found in this system. Installing..."
    log_info "Have patience and wait for a few moment please ... ... ..."

    case "$DISTRO" in 
        fedora)
            install_pycharm_on_fedora
            ;;
        ubuntu|debian|lubuntu)
            install_pycharm_on_ubuntu
            ;;
        *)
            log_error "Unsupported distro! Please use this script only on 'fedora' or 'ubuntu(debian)'"
            return 1
            ;;
    esac


    if [ $? -ne 0 ]; then
    log_error "Installation failed. Please check your network or repo setting first, then try again.\n\n"
    else
    log_success "Pycharm community Installation Complete!\n\n"
    fi
}