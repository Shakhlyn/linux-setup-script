#!/bin/bash

# install_brave.sh
# Script to install Brave Browser on Fedora 43

source ./lib-logger.sh
source ./utils.sh

set -euo pipefail # Exit immediately if a command fails


#============================================================================================

brave_on_ubuntu() {
    if is_installed "brave-browser"; then
        log_info "Brave browser is already installed in your system."
        return 0
    else
        log_info "Couldn't find Brave in your system"
        log_info "Starting the procedure for installing Brave on your system...\n"
    fi

    log_info "Installing the required dependencies..."
    sudo apt install curl gnupg apt-transport-https software-properties-common
    printf "\n"

    log_info "Adding Brave's GPG key\n"
    sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg

    log_info "Adding Brave's repository\n"
    echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list

    log_info "\Updating package list\n"
    sudo apt update
    printf "\n"

    log_info "Installing Brave browser...\n"
    sudo apt install brave-browser

    if [[ "$?" -ne 0 ]]; then
        printf "\n"
        log_error "Something went wrong. Check internet connection. Please try again later\n\n"
    else
        log_success "Successfully installed Brave browser!!!\n"
        printf "\n"
    fi
}


brave_on_fedora() {
    echo "Updating system packages..."
    sudo dnf update -y

    echo "Installing DNF plugins..."
    sudo dnf install -y dnf-plugins-core

    echo "Adding Brave Browser repository..."
    sudo dnf config-manager --add-repo --from-repofile=https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo

    echo "Importing Brave GPG key..."
    sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc

    echo "Installing Brave Browser..."
    sudo dnf install -y brave-browser

    echo "Brave Browser installation completed!"
    echo "You can launch it with: brave-browser"
}


install_brave() {
    case "$DISTRO" in
    ubuntu|debian)
        if brave_on_ubuntu; then
            log_info "You can run brave by typing 'brave-browser' in the terminal.\n\n"
            return 0
        else
            return 1
        fi
        ;;
    fedora)
        if brave_on_fedora; then
            log_info "You can run Chrome by typing 'google-chrome-stable' in the terminal\n\n"
            return 0
        else
            return 1
        fi
        ;;
    *)
        log_warn "Unsupported distribution: $DISTRO"
        return 1
        ;;
    esac
}

#=============================================================================================

chrome_on_ubuntu() {
    if is_installed "google-chrome-stable"; then
        log_info "Google Chrome is already installed in your system."
        return 0
    else
        log_info "Couldn't find Google Chrome in your system"
        log_info "Starting the procedure for installing Google Chrome on your system...\n"
    fi

    log_info "Downloading the deb package..."
    wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    if [[ "$?" -ne 0 ]]; then
        log_warn "Something went wrong! Check your internet connection. Please try again later.\n"
    fi
    log_info "Installing..."
    sudo dpkg -i google-chrome-stable_current_amd64.deb

    if [[ "$?" -ne 0 ]]; then
        sudo apt --fix-broken install
    else
        log_success "Chrome has been installed successfully."

        log_info "Deleting the chrome .dev file..."
        rm google-chrome-stable_current_amd64.deb
    fi
}


install_chrome () {
    case "$DISTRO" in
    ubuntu|debian)
        if chrome_on_ubuntu; then
            log_info "You can run Chrome by typing 'google-chrome-stable' in the terminal\n\n"
            return 0
        else
            return 1
        fi
        ;;
    fedora)
        if brave_on_fedora; then
            log_info "You can run Chrome by typing 'google-chrome-stable' in the terminal\n\n"
            return 0
        else
            return 1
        fi
        ;;
    *)
        log_warn "Unsupported distribution: $DISTRO"
        return 1
        ;;
    esac


}

#=============================================================================================

install_browsers() {
    install_chrome

    install_brave
}
