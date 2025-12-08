#!/bin/bash


source ./lib-logger.sh
source ./utils.sh


check_if_go_installed() {
  if command -v go &> /dev/null; then
    log_info "Go is already installed in your system. Version: $(go version)\n"
    return 0

  else
    return 1
  fi
}


install_golang() {
  echo "hi"
  if check_if_go_installed; then
    return
  fi

  log_info "Installing the latest version of Go...\n"

  go_latest_version=$(curl -s https://go.dev/VERSION?m=text | head -n 1)
  log_info "Latest Go version: $go_latest_version\n"

  log_info "Downloading the tarball"
  wget "https://go.dev/dl/${go_latest_version}.linux-amd64.tar.gz" -O /tmp/go.tar.gz

  if [[ "$?" -ne 0 ]]; then
    log_warn "Something went wrong. Couldn't download the tarball"]
    return 1
  fi


  # Remove any previous Go installation
  sudo rm -rf /usr/local/go

  # Extract to /usr/local
  sudo tar -C /usr/local -xzf /tmp/go.tar.gz

  # Add Go to PATH if not already in ~/.zshrc
  log_info "\nAdding Go to the PATH in ~/.zshrc\n"
  if ! grep -q 'export PATH=$PATH:/usr/local/go/bin' ~/.zshrc; then
      echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.zshrc
  fi

  # Apply changes
  log_success "Go has been installed successfully!"

  log_info "Open a new terminal or run: source ~/.zshrc"
}