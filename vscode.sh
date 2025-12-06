#!/bin/bash

# =========================
# Script to install Visual Studio Code  (RPM version) on Fedora and Ubuntu
# =========================
set -euo pipefail
IFS=$'\n\t'

# -------------------------
# Helpers: colors + logging
# -------------------------
GREEN="\e[32m"; YELLOW="\e[33m"; RED="\e[31m"; BLUE="\e[34m"; RESET="\e[0m"
success(){ echo -e "${GREEN}[SUCCESS]${RESET} $*"; }
info(){ echo -e "${BLUE}[INFO]${RESET} $*"; }
warn(){ echo -e "${YELLOW}[WARN]${RESET} $*"; }
err(){ echo -e "${RED}[ERROR]${RESET} $*"; }


# -------------------------
# Helpers: functions
# -------------------------
is_vs_installed() {
  if command -v code >/dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}


error_exit() {
  err "$1" >&2
  exit 1
}


set_gpg_key_n_code_repo_on_ubuntu() {

  info "Importing Microsoft GPG key..."
  wget -qO- https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/vscode.gpg

  info "Creating VS Code repository file..."
  echo "deb [arch=amd64 signed-by=/usr/share/keyrings/vscode.gpg] https://packages.microsoft.com/repos/vscode stable main" | sudo tee /etc/apt/sources.list.d/vscode.list

}


set_gpg_key_n_code_repo_on_fedora() {
  # Import the Microsoft GPG key
  info "Importing Microsoft GPG key..."
  sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc


  if [ $? -ne 0 ]; then
    error_exit "Failed to import Microsoft GPG key"
  else
    success "Successfully Imported Microsoft GPG key"
  fi


  # Creating VS Code repo
  info "Creating VS Code repository file..."
  sudo tee /etc/yum.repos.d/vscode.repo > /dev/null <<-'EOF'
    [code]
    name=Visual Studio Code
    baseurl=https://packages.microsoft.com/yumrepos/vscode
    enabled=1
    gpgcheck=1
    gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF

}


install_vs_on_fedora() {
  # Clean DNF metadata and refresh cache
  warn "Cleaning DNF metadata..."
  sudo dnf clean all || warn "Failed clear DNF metadata"

  warn "Refreshing package cache..."
  sudo dnf makecache || warn "Failed to refresh DNF cache"

  info "Installing the VS Code..."
  sudo dnf install -y code
}


install_vs_on_ubuntu() {
  # Refreshing the repositories
  sudo apt update

  info "Installing the VS Code..."
  sudo apt install -y code
}


# -------------------------
# Main process
# -------------------------

# Checking distro
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
    info "You are using: $DISTRO distro"

    if [[ $DISTRO == "fedora" || $DISTRO == "ubuntu" ]]; then
      info "Proceeding with the installation"
    else
      warn "Currently this script can be used to install only on 'fedora' or 'ubuntu' distro!"
      err "Can't install on this distro."
      info "If you want distro(s) support, please send an email at: 'shakhlyn.sh.du@gmail.com"
      warn "Exiting the script..."
    fi

else
    info "Try to use this script only on Fedora or Ubuntu"
    error_exit "Cannot detect Linux distro"
fi


if is_vs_installed; then
  success "Hurrah! VS Code is already installed in this system"
  info "You can launch it using 'code'"
  warn "Exiting the process since there is no need to install again"
  exit 0
fi


info "VS Code is not found in this system. Installing..."
info "Have patience and wait for a few moment please ... ... ..."


case "$DISTRO" in
  fedora)
    set_gpg_key_n_code_repo_on_fedora
#    install_vs_on_fedora
    ;;
  ubuntu|debian)
    set_gpg_key_n_code_repo_on_ubuntu
    ;;
  *)
    error_exit "Unsupported distro! Please use this script only on 'fedora' or 'ubuntu(debian)'"
    ;;
esac


if [ $? -ne 0 ]; then
  error_exit "Failed to create VS Code repo file"
else
  success "Created VS code repo file successfully."
fi


case "$DISTRO" in
  fedora)
    install_vs_on_fedora
    ;;
  ubuntu|debian)
    install_vs_on_ubuntu
    ;;
  *)
    error_exit "Unsupported distro! Please use this script only on 'fedora' or 'ubuntu(debian)'"
    ;;
esac


if [ $? -ne 0 ]; then
  error_exit "Installation failed. Please check your network or repo setting first, then try again."
else
  success "Installation Complete!"
fi

info "Now you can launch VS code using: 'code'"
