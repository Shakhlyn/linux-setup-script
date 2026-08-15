#!/bin/bash

set -uo pipefail

source ./utils/lib-logger.sh
source ./utils/utils.sh


UV_INSTALL_URL="https://astral.sh/uv/install.sh"
UV_BIN_DIR="${HOME}/.local/bin"


# ─────────────────────────────────────────────────────────────────────────────
# install_uv
# Installs uv via the official standalone installer. The installer is
# identical on every supported distro, so there is no _ubuntu/_fedora split.
# ─────────────────────────────────────────────────────────────────────────────

install_uv() {
    local retries=5
    local delay=5
    local count=0

    if is_installed 'uv'; then
        log_confirm "uv is already installed ($(uv --version 2>/dev/null)). Skipping installation."
        return 0
    fi

    log_info "Installing uv..."

    while ! curl -LsSf "${UV_INSTALL_URL}" | sh; do
        count=$((count + 1))
        if [[ $count -ge $retries ]]; then
            log_error "uv installation failed after $retries attempts."
            return 1
        fi
        log_error "uv installation failed (attempt $count/$retries). Retrying in ${delay}s..."
        sleep "$delay"
    done

    log_success "uv installed successfully\n"
}


# ─────────────────────────────────────────────────────────────────────────────
# configure_uv_shell
# The installer drops uv into ~/.local/bin. Make sure that stays on PATH for
# future shells, and for the rest of this run.
# ─────────────────────────────────────────────────────────────────────────────

configure_uv_shell() {
    local shell_rc

    shell_rc=$(get_shell_rc_file) || return 1

    if grep -q '\.local/bin' "${shell_rc}" 2>/dev/null; then
        log_confirm "${UV_BIN_DIR} is already on PATH in ${shell_rc}. Skipping."
    else
        log_info "Adding ${UV_BIN_DIR} to PATH in ${shell_rc}"
        cat >> "${shell_rc}" << 'EOF'

# uv - Python package & version manager
export PATH="$HOME/.local/bin:$PATH"
EOF
        log_success "PATH entry added to ${shell_rc}"
    fi

    # Make uv usable for the rest of this run without opening a new shell.
    case ":${PATH}:" in
        *":${UV_BIN_DIR}:"*) ;;
        *) export PATH="${UV_BIN_DIR}:${PATH}" ;;
    esac
}


# ─────────────────────────────────────────────────────────────────────────────
# verify_uv
# Smoke-tests the installation.
# ─────────────────────────────────────────────────────────────────────────────

verify_uv() {
    verify_package 'uv' || return 1

    log_confirm "uv is ready: $(uv --version)"
}


# ─────────────────────────────────────────────────────────────────────────────
# setup_uv
# ─────────────────────────────────────────────────────────────────────────────

setup_uv() {
    install_uv || return 1
    configure_uv_shell || return 1
    verify_uv || return 1
}
