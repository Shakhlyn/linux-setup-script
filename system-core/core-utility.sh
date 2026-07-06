#!/bin/bash
set -uo pipefail
IFS=$'\n\t'

# Installs terminal utilities, i.e., tmux and vim, on supported distributions.
# Supported: ubuntu, lubuntu, pop, fedora
source ./utils/lib-logger.sh
source ./utils/utils.sh

# ─────────────────────────────────────────────────────────────────────────────
# _tmux_install_deps_ubuntu
# Installs tmux build dependencies on apt-based distributions.
# ─────────────────────────────────────────────────────────────────────────────

_tmux_install_deps_ubuntu() {
    log_info "Installing tmux build dependencies...\n"
    install_packages libncurses-dev libevent-dev || return 1
    install_packages build-essential gcc || return 1
}

# ─────────────────────────────────────────────────────────────────────────────
# _tmux_install_deps_fedora
# Installs tmux build dependencies on Fedora.
# ─────────────────────────────────────────────────────────────────────────────

_tmux_install_deps_fedora() {
    log_info "Installing tmux build dependencies...\n"
    install_packages libevent-devel ncurses-devel gcc || return 1
}

# ─────────────────────────────────────────────────────────────────────────────
# _tmux_install_deps
# Dispatches tmux dependency installation for the active distribution.
# ─────────────────────────────────────────────────────────────────────────────

_tmux_install_deps() {
    case "${DISTRO:-}" in
        ubuntu | lubuntu | pop)
            _tmux_install_deps_ubuntu
            ;;
        fedora)
            _tmux_install_deps_fedora
            ;;
        *)
            log_error "_tmux_install_deps: Unsupported distribution '${DISTRO:-unset}'."
            return 1
            ;;
    esac
}

# ─────────────────────────────────────────────────────────────────────────────
# install_tmux
# Installs tmux and verifies the binary is available.
# ─────────────────────────────────────────────────────────────────────────────
install_tmux() {
    log_info "======== tmux Installation ========\n"

    if is_installed "tmux"; then
        log_confirm "tmux is already installed on this system. Skipping.\n"
        return 0
    fi

    log_info "tmux not found. Starting installation...\n"

    if ! _tmux_install_deps; then
        log_error "Failed to install tmux dependencies. Aborting tmux installation."
        return 1
    fi

    log_info "Installing tmux...\n"
    if ! install_packages tmux; then
        log_error "Failed to install tmux. Check your internet connection and try again."
        return 1
    fi

    verify_package "tmux" || return 1

    log_success "tmux installed successfully.\n"
    log_info "Launch tmux by typing 'tmux' in your terminal."
    log_info "Tip: 'tmux new -s <name>' starts a named session.\n"
}

# ─────────────────────────────────────────────────────────────────────────────
# _is_full_vim_installed
# Checks that vim exists and includes full syntax support.
# ─────────────────────────────────────────────────────────────────────────────

# Ubuntu/Lubuntu/Pop ship vim-tiny by default. It registers in PATH as 'vim'
# but silently drops syntax highlighting and plugin support.
_is_full_vim_installed() {
    if ! is_installed "vim" &>/dev/null; then
        return 1
    fi

    if vim --version 2>/dev/null | grep -q "+syntax"; then
        return 0
    fi

    log_warn "Found a 'vim' binary but it is vim-tiny (no +syntax support)."
    log_warn "Will replace with full vim.\n"
    return 1
}

# ─────────────────────────────────────────────────────────────────────────────
# _remove_vim_tiny
# Removes vim-tiny on apt-based distributions before installing full vim.
# ─────────────────────────────────────────────────────────────────────────────

_remove_vim_tiny() {
    if [[ "${DISTRO:-}" != "ubuntu" && "${DISTRO:-}" != "lubuntu" && "${DISTRO:-}" != "pop" ]]; then
        log_error "_remove_vim_tiny: Unsupported distribution '${DISTRO:-unset}'."
        return 1
    fi

    if dpkg-query -W -f='${Status}' vim-tiny 2>/dev/null | grep -q "install ok installed"; then
        log_info "Removing vim-tiny to avoid dpkg conflicts...\n"
        if ! sudo apt remove -y vim-tiny; then
            # Non-fatal: apt may still resolve the conflict during full vim install.
            log_warn "Could not remove vim-tiny cleanly. apt will attempt to resolve."
        fi
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# _vim_on_apt
# Installs full vim on apt-based distributions.
# ─────────────────────────────────────────────────────────────────────────────

_vim_on_apt() {
    _remove_vim_tiny || return 1

    log_info "Installing full vim...\n"
    if ! install_packages vim; then
        log_error "apt failed to install vim."
        return 1
    fi

    if ! _is_full_vim_installed; then
        log_error "vim was installed but +syntax is still absent. Installation is incomplete."
        return 1
    fi

    log_success "vim (full) installed successfully.\n"
}

# ─────────────────────────────────────────────────────────────────────────────
# _vim_on_dnf
# Installs vim-enhanced on Fedora.
# ─────────────────────────────────────────────────────────────────────────────

_vim_on_dnf() {
    # Fedora ships vim-minimal by default. vim-enhanced is the full-featured build.
    log_info "Installing vim-enhanced (full-featured build for Fedora)...\n"

    # The binary is still called 'vim', but the package is 'vim-enhanced'
    if ! dnf_install vim-enhanced vim; then
        log_error "dnf failed to install vim-enhanced."
        return 1
    fi

    if ! _is_full_vim_installed; then
        log_error "vim was installed but +syntax is still absent. Installation is incomplete."
        return 1
    fi

    log_success "vim (enhanced) installed successfully.\n"
}

# ─────────────────────────────────────────────────────────────────────────────
# install_vim
# Installs full vim for the active distribution.
# ─────────────────────────────────────────────────────────────────────────────
install_vim() {
    log_info "======== vim Installation ========\n"

    if _is_full_vim_installed; then
        log_confirm "Full vim is already installed on this system. Skipping.\n"
        return 0
    fi

    case "${DISTRO:-}" in
        ubuntu | lubuntu | pop)
            _vim_on_apt || return 1
            ;;
        fedora)
            _vim_on_dnf || return 1
            ;;
        *)
            log_error "install_vim: Unsupported distribution '${DISTRO:-unset}'."
            return 1
            ;;
    esac

    log_info "Launch vim by typing 'vim <filename>' in your terminal.\n"
}

# ─────────────────────────────────────────────────────────────────────────────
# install_terminal_tools
# Installs terminal tools used by the development environment.
# ─────────────────────────────────────────────────────────────────────────────

install_terminal_tools() {
    install_tmux || return 1
    install_vim || return 1

    log_success "Terminal tools installed successfully.\n"
}
