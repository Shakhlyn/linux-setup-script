#!/bin/bash

set -uo pipefail

source ./lib-logger.sh
source ./utils.sh

PYTHON_VERSIONS=(3.10 3.10.14 3.12.12 3.13.11)

check_python_version_installed() {
    if pyenv versions --bare 2>/dev/null | grep -q "^${version}$"; then
        return 0
    fi
}


set_global_python() {
    local version="3.12.12"

    if ! is_installed 'pyenv'; then
        log_error "pyenv not found in PATH"
        return 1
    fi

    if ! check_python_version_installed; then
        log_error "Python $version is not found in your system. Please install this version first"
        return 1
    fi

    log_info "Setting Python $version as global default..."

    if ! pyenv global "$version"; then
        log_error "Failed to set $version as the global Python version"
        return 1
    fi

    log_success "Python $version set as global default"
    return 0
}


install_python_versions() {
    if ! is_installed 'pyenv'; then
        log_error "pyenv not found in PATH"
        return 1
    fi

    for version in "${PYTHON_VERSIONS[@]}"; do

        # Check if already installed
        if check_python_version_installed; then
            log_confirm "Python $version already installed"
        else
            # Install Python version
            log_info "Installing Python $version..."
            if pyenv install "$version"; then
                log_success "Python $version is installed successfully"
                return 0
            else
                log_error "Failed to install Python $version"
                return 1
            fi
        fi
    done
}

install_python() {
    if ! install_python_versions; then
        return 1
    fi


    if ! set_global_python; then
        return 1
    fi
}

