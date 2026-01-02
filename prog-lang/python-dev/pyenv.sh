#!/bin/bash

set -uo pipefail

source ./lib-logger.sh
source ./utils.sh

PYENV_ROOT="${HOME}/.pyenv"
PYENV_INSTALL_URL="https://pyenv.run"
LOG_IN_PROFILE_FILE="${HOME}/.profile"
SHELL_CONFIG_FILE=$(get_shell_rc_file)


is_pyenv_installed() {
    if [ -d "${PYENV_ROOT}" ] && is_installed 'pyenv'; then
        return 0
    else
        return 1
    fi
}


install_pyenv() {
    log_info "Starting pyenv installation..."

    if curl -fsSL "${PYENV_INSTALL_URL}" | bash; then
        log_success "\npyenv installed successfully\n"
        return 0
    else
        log_error "Failed to install pyenv"
        return 1
    fi
}


configure_login_profile() {
    if [ -f "${LOG_IN_PROFILE_FILE}" ] && ! grep -q 'PYENV_ROOT' "${LOG_IN_PROFILE_FILE}"; then
        cat << EOF >> "${LOG_IN_PROFILE_FILE}"

# Pyenv configuration
export PYENV_ROOT="\$HOME/.pyenv"
[[ -d \$PYENV_ROOT/bin ]] && export PATH="\$PYENV_ROOT/bin:\$PATH"
EOF
        log_info "Added pyenv PATH to ~/.profile"
    fi
}


write_shell_config() {
        cat >> "${SHELL_CONFIG_FILE}" << 'EOF'

# pyenv configuration
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
EOF
}


configure_shell() {
    log_info "Configuring $SHELL_CONFIG_FILE for pyenv..."

    # Check if already configured
    if grep -q 'PYENV_ROOT' "${SHELL_CONFIG_FILE}" 2>/dev/null; then
        log_warn "pyenv already configured in $SHELL_CONFIG_FILE"
        return 0
    fi

    # Creating backup config file
    if [ -f "${SHELL_CONFIG_FILE}" ]; then
        log_warn "\n*** Keeping a back up for $SHELL_CONFIG_FILE before writing to this file. You can delete later if everything goes successfully. ***\n"
        cp "${SHELL_CONFIG_FILE}" "${SHELL_CONFIG_FILE}.bak.$(date +%s)" 2>/dev/null || true
    fi

    # Add pyenv configuration
    log_info "Adding pyenv configuration to $SHELL_CONFIG_FILE"
    write_shell_config
    log_info "Added pyenv configuration to $SHELL_CONFIG_FILE"

    configure_login_profile
}


load_pyenv() {
    log_info "Loading pyenv into current session..."

    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"

    eval "$(pyenv init -)"

    # Load virtualenv-init if available (might not be installed yet)
    if command -v pyenv-virtualenv-init >/dev/null 2>&1; then
        eval "$(pyenv virtualenv-init -)"
    fi

    log_success "pyenv loaded successfully (version: $(pyenv --version 2>/dev/null || echo 'unknown'))"
    return 0
}


setup_pyenv() {
    if is_pyenv_installed; then
        log_info "pyenv already exists at ${PYENV_ROOT} - skipping installation."

    # We need to load pyenv because we want to install python using pyenv right after.
    # Loading pyenv into the current session means we don't need to restart the terminal.
        if ! load_pyenv; then
            return 1
        fi
        return 0
    fi

    if ! install_pyenv; then
        return 1
    fi

    if ! configure_shell; then
        return 1
    fi

    if ! load_pyenv; then
        return 1
    fi

    log_success "pyenv setup complete"
    return 0
}

