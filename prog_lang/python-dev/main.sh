#!/bin/bash


source ./lib-logger.sh

source ./prog_lang/python-dev/prerequisite-libs.sh


set -uo pipefail

setup_python_dev_env() {
    install_python_n_pyenv_pre_requisites
    script_divider


}

