#!/bin/bash


source ./lib-logger.sh

source ./prog-lang/python-dev/prerequisite-libs.sh
source ./prog-lang/python-dev/pyenv.sh
source ./prog-lang/python-dev/python.sh


set -uo pipefail

setup_python_dev_env() {
    install_python_n_pyenv_pre_requisites
    script_divider

    if ! setup_pyenv; then
        return 1
    fi

    if ! install_python; then
        return 1
    fi
}

