#!/bin/bash

# ====================================
# Script for Zsh + Oh My Zsh Installer
# ====================================

set -euo pipefail
IFS=$'\n\t'


source ./lib-logger.sh
source ./utils.sh


check_if_zsh_installed() {
  log_info "Checking if zsh already installed..."
  if command -v zsh >/dev/null 2>&1; then
    log_info "ZSH is already installed in this device\n"
    return 0
  else
    return 1
  fi
}

check_if_ohmyzsh_installed() {
  if [ -d "$HOME/.oh-my-zsh" ]; then
    log_info "Oh My Zsh is already installed. Skipping.\n"
    return 0
  else
    return 1
  fi
}

# -----------------------------------------
# Install zsh based on distro
# -----------------------------------------
install_zsh() {
  printf "\n"
  cat <<'info'
  ================================
  Installing Zsh + Oh My Zsh Suite
  ================================
info
  printf "\n"

    case "$DISTRO" in
    ubuntu|debian)
      sudo apt update -y
      sudo apt install -y zsh wget
      ;;
    fedora)
      sudo dnf install -y zsh wget
      ;;
#    arch)
#      sudo pacman -Sy --noconfirm zsh git wget
#      ;;
    *)
      log_warn "Unsupported distribution: $DISTRO"
      return 1
      ;;
  esac

  log_success "ZSH is installed successfully.\n"
}


# -----------------------------------------
# Install Oh My Zsh
# -----------------------------------------
install_ohmyzsh() {
  log_info "Installing Oh My Zsh...\n"

#Setting RUNZSH=no tells it: Do not start Zsh automatically after installation.”
  RUNZSH=no \
  sh -c "$(wget -O - https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

  log_success "Oh My Zsh installed.\n"
}



# -----------------------------------------
# Install plugins
# -----------------------------------------
install_plugins() {

  log_info "Installing plugins...\n"

  local ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

  # Autosuggestions
  if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions \
      "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    log_success "zsh-autosuggestions installed.\n"
  else
    log_info "zsh-autosuggestions already installed.\n"
  fi

  # Syntax highlighting
  if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
      "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
    log_success "zsh-syntax-highlighting installed."
  else
    log_info "zsh-syntax-highlighting already installed."
  fi

  printf "\n"
}



# -----------------------------------------
# Update ~/.zshrc
# -----------------------------------------
configure_zshrc() {

  log_info "Updating ~/.zshrc...\n"

  if grep -q "zsh-autosuggestions" ~/.zshrc; then
    log_info "Plugins already configured.\n"
    return
  fi

  sed -i 's/^plugins=(\(.*\))/plugins=(\1 zsh-autosuggestions zsh-syntax-highlighting)/' ~/.zshrc

  log_success "Added plugins to ~/.zshrc\n\n"
}



# -----------------------------------------
# Make Zsh default
# -----------------------------------------
make_default_shell() {
  log_warn "Changing default shell to zsh...\n"

  if [[ "$SHELL" == "$(command -v zsh)" ]]; then
    log_info "Zsh is already the default shell.\n"
    return
  fi

  chsh -s "$(command -v zsh)"

  log_success "Default shell changed. Restart terminal.\n"
}



# -----------------------------------------
# Main installer sequence
# -----------------------------------------
install_zsh_suit() {
#  if check_if_zsh_installed; then
#    return 0
#  fi
#
#  install_zsh

  if check_if_ohmyzsh_installed; then
    return 0
  fi

  install_ohmyzsh

  install_plugins
  configure_zshrc
  make_default_shell

  log_success "All done! Restart your terminal or run"
  printf '  source ~/.zshrc'
}
