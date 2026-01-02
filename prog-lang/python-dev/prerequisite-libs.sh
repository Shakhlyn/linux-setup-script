#!/bin/bash

source ./lib-logger.sh
source ./utils.sh

set -uo pipefail


PYENV_PRE_REQUISITE_LIBS=(libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev llvm libncurses5-dev \
        libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev python3-openssl )
PYTHON_PRE_REQUISITE_LIBS=(libgdbm-dev libdb-dev libexpat1-dev uuid-dev libnss3-dev)

install_python_n_pyenv_pre_requisites() {
    log_info "Installing pre-requisite libraries required for pyenv ..."
    for pkg in "${PYENV_PRE_REQUISITE_LIBS[@]}"; do
        if ! apt_install "$pkg"; then
            exit 1
        fi
    done

    log_info "Installing pre-requisite libraries required for python ..."
    for pkg in "${PYTHON_PRE_REQUISITE_LIBS[@]}"; do
        if ! apt_install "$pkg"; then
            exit 1
        fi
    done
}
