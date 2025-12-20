#!/bin/bash


source ./lib-logger.sh
source ./utils.sh


know_go_latest_version() {
    if go_latest_version=$(curl -s https://go.dev/VERSION?m=text | head -n 1);then
        log_info "Latest Go version: $go_latest_version\n"
    else
        log_warn "Cannot find what is the latest version of Go!"
        return 1
    fi
}


download_tarball() {
    wget "https://go.dev/dl/${go_latest_version}.linux-amd64.tar.gz" -O /tmp/go.tar.gz

    if [[ "$?" -ne 0 ]]; then
        log_warn "Something went wrong. Couldn't download the tarball"]
        return 1
    fi

    log_info "Downloaded the tarball of Go"
}


adding_path_if_not_in_zshrc() {
    if ! grep -q 'export PATH=$PATH:/usr/local/go/bin' ~/.zshrc; then
        log_info "\nAdding Go to the PATH in ~/.zshrc\n"
        echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.zshrc
    else
        log_info "\nPath is already in the .zshrc file. Skipping re-writing...\n"
        return 0
    fi
}


install_golang() {
    if is_installed 'go'; then
        log_info "Go is already installed in your device. Version: $(go version)"
        return 0
    fi

    log_info "Go is not installed in your system. Installing the latest version of Go...\n"

    if ! know_go_latest_version; then
        return 1
    fi

    log_info "Downloading the tarball"
    if ! download_tarball; then
        return 1
    fi

    # Remove any previous Go installation
    sudo rm -rf /usr/local/go

    # Extract to /usr/local
    sudo tar -C /usr/local -xzf /tmp/go.tar.gz

    # Add Go to PATH if not already in ~/.zshrc
    adding_path_if_not_in_zshrc

    # Apply changes
    log_success "Go has been installed successfully!"

    log_info "Open a new terminal or run: source ~/.zshrc"
}