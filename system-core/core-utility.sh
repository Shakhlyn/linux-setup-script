#!/bin/bash

# vim, tmux,

#!/bin/bash

# install_tmux_vim.sh
# Installs tmux and vim on supported distributions.
# Supported: ubuntu, lubuntu, pop, fedora
#
# Depends on: utils.sh (is_installed, pkg_install, error_exit)
#             lib-logger.sh (log_*)

source ./utils/lib-logger.sh
source ./utils/utils.sh

set -uo pipefail


# ─────────────────────────────────────────────────────────────────────────────
# TMUX
# ─────────────────────────────────────────────────────────────────────────────

_tmux_install_deps() {
    log_info "Installing tmux build dependencies...\n"

    case "${DISTRO:-}" in
        ubuntu | lubuntu | pop)
            pkg_install libevent-dev   libevent-dev   || return 1
            pkg_install libncurses-dev libncurses-dev || return 1
            pkg_install build-essential gcc           || return 1
            ;;
        fedora)
            pkg_install libevent-devel libevent-devel || return 1
            pkg_install ncurses-devel  ncurses-devel  || return 1
            pkg_install gcc            gcc            || return 1
            ;;
    esac
}


install_tmux() {
    log_info "======== tmux Installation ========\n"

    if is_installed "tmux"; then
        log_confirm "tmux is already installed on this system. Skipping.\n"
        return 0
    fi

    log_info "tmux not found. Starting installation...\n"

    _tmux_install_deps || {
        log_error "Failed to install tmux dependencies. Aborting tmux installation."
        return 1
    }

    log_info "Installing tmux...\n"
    if ! pkg_install tmux; then
        log_error "Failed to install tmux. Check your internet connection and try again."
        return 1
    fi

    # Final verification — pkg_install is idempotent but doesn't re-verify PATH
    if ! is_installed "tmux"; then
        log_error "tmux was not found after installation. Something went wrong."
        return 1
    fi

    log_success "tmux installed successfully.\n"
    log_info "Launch tmux by typing 'tmux' in your terminal."
    log_info "Tip: 'tmux new -s <name>' starts a named session.\n"
}


# ─────────────────────────────────────────────────────────────────────────────
# VIM
# ─────────────────────────────────────────────────────────────────────────────

# Ubuntu/Lubuntu/Pop ship vim-tiny by default. It registers in PATH as 'vim'
# but silently drops syntax highlighting and plugin support. We must detect
# this and replace it — not just check command -v vim.
_is_full_vim_installed() {
    if ! command -v vim &>/dev/null; then
        return 1
    fi

    if vim --version 2>/dev/null | grep -q "+syntax"; then
        return 0
    fi

    log_warn "Found a 'vim' binary but it is vim-tiny (no +syntax support)."
    log_warn "Will replace with full vim.\n"
    return 1
}


_remove_vim_tiny() {
    if dpkg -l vim-tiny &>/dev/null 2>&1; then
        log_info "Removing vim-tiny to avoid dpkg conflicts...\n"
        if ! sudo apt remove -y vim-tiny; then
            # Non-fatal — apt may still resolve the conflict on its own
            log_warn "Could not remove vim-tiny cleanly. apt will attempt to resolve."
        fi
    fi
}


_vim_on_apt() {
    _remove_vim_tiny

    log_info "Installing full vim...\n"
    if ! apt_install vim; then
        log_error "apt failed to install vim."
        return 1
    fi

    if ! _is_full_vim_installed; then
        log_error "vim was installed but +syntax is still absent. Installation is incomplete."
        return 1
    fi

    log_success "vim (full) installed successfully.\n"
}


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
# PUBLIC ENTRY POINT
# ─────────────────────────────────────────────────────────────────────────────

install_terminal_tools() {
    install_tmux
    install_vim
}