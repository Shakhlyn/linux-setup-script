#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

# =========================
# Script to install Visual Studio Code  (RPM version) on Fedora and Ubuntu
# =========================

source ./lib-logger.sh
source ./utils.sh


set_gpg_key_n_code_repo_on_ubuntu() {
    log_info "Importing Microsoft GPG key..."
    if ! wget -qO- https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/vscode.gpg; then
        log_error "Failed to import Microsoft GPG key\n"
        return 1
    else
        log_success "Successfully Imported Microsoft GPG key"
    fi

    log_info "Creating VS Code repository file..."
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/vscode.gpg] https://packages.microsoft.com/repos/vscode stable main" | sudo tee /etc/apt/sources.list.d/vscode.list

    if [ $? -ne 0 ]; then
        log_error"Failed to create the repo\n"
        return 1
    else
        log_success "Successfully created the vs code repo"
    fi
}


set_gpg_key_n_code_repo_on_fedora() {
  # Import the Microsoft GPG key
    log_info "Importing Microsoft GPG key..."
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc


    if [ $? -ne 0 ]; then
        log_error "Failed to import Microsoft GPG key\n"
        return 1
    else
        log_success "Successfully Imported Microsoft GPG key"
    fi


    # Creating VS Code repo
    log_info "Creating VS Code repository file..."
    sudo tee /etc/yum.repos.d/vscode.repo > /dev/null <<-'EOF'
        [code]
        name=Visual Studio Code
        baseurl=https://packages.microsoft.com/yumrepos/vscode
        enabled=1
        gpgcheck=1
        gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF

    if [ $? -ne 0 ]; then
        log_error"Failed to create the repo\n"
        return 1
    else
        log_success "Successfully created the vs code repo"
    fi
}


install_vs_on_fedora() {
    log_warn "Cleaning DNF metadata..."
    sudo dnf clean all || log_warn "    Failed clear DNF metadata"

    log_warn "Refreshing package cache..."
    sudo dnf makecache || log_warn "    Failed to refresh DNF cache"

    log_info "Installing the VS Code..."
    sudo dnf install -y code
}


install_vs_on_ubuntu() {
  # Refreshing the repositories
  sudo apt update

  log_info "Installing the VS Code..."
  sudo apt install -y code
}


# -------------------------
# Main process
# -------------------------

install_vs_code() {
    if is_installed "code"; then
        log_success "Hurrah! VS Code is already installed in this system"
        log_info "You can launch it using 'code'"
        log_info "Exiting the process since there is no need to install again\n"
        return 0
    fi

    log_info "VS Code is not found in this system. Installing..."
    log_info "Have patience and wait for a few moment please ..."


    case "$DISTRO" in
        fedora)
            if ! set_gpg_key_n_code_repo_on_fedora; then
                return 1
            fi
            ;;
        ubuntu|debian)
            if ! set_gpg_key_n_code_repo_on_ubuntu; then
                return 1
            fi
            ;;
        *)
            log_error "Unsupported distro! Please use this script only on 'fedora' or 'ubuntu(debian)'\n"
            return 1
            ;;
    esac


    case "$DISTRO" in
        fedora)
            install_vs_on_fedora
            ;;
        ubuntu|debian)
            install_vs_on_ubuntu
            ;;
        *)
            log_error "Unsupported distro! Please use this script only on 'fedora' or 'ubuntu(debian)'\n"
            return 1
          ;;
    esac


    if [ "$?" -ne 0 ]; then
        log_error "Installation failed. Please check your network or repo setting first, then try again.\n"
        return 1
    else
        log_success "Installation Complete!"
        log_info "Now you can launch VS code using: 'code'\n"
    fi
}

