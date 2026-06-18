#!/bin/bash

# -------------------------------
# Importing utility scripts
# -------------------------------
source ./utils/distro.sh
source ./utils/lib-logger.sh
source ./utils/utils.sh

source ./utils/run-module.sh


# -------------------------------
# Importing installation scripts
# -------------------------------

: <<'NOTE'

# IMPORTANT NOTE:
#
# Although we have grouped the scripts in similar directories,
# we have imported individual scripts. The main reason is that
# in a later stage, the users will have the option to select
# the items they want to install.
#
NOTE

source ./system-core/system-utility.sh

source ./db-clients/dbeaver-ce.sh
source ./db-clients/postgresql-postgresql_client-and-utility.sh

source ./browser.sh

source ./ides/pycharm-community.sh
source ./ides/webstorm.sh
source ./ides/vscode.sh

source ./prog-lang/golang.sh
source ./prog-lang/python-dev/main.sh

source ./utility-tools/zsh_shell.sh

source ./containers-devops/docker-suite.sh


#===================================================
# Defining all the log files in one place
#===================================================

# Define logs directory (simple relative path)
LOGS_DIR="./logs"

declare -A LOG_FILES

LOG_FILES[log]="${LOGS_DIR}/script.log"
LOG_FILES[success]="${LOGS_DIR}/success.log"
LOG_FILES[error]="${LOGS_DIR}/error.log"
LOG_FILES[warn]="${LOGS_DIR}/warn.log"
LOG_FILES[fail]="${LOGS_DIR}/fail.log"

export LOG_FILES

#===================================================
# Core functionalities
#===================================================

DISTRO="$(detect_distro)"

if is_supported_distro "$DISTRO"; then
    log_info "You are using: $DISTRO distro"
    log_info "Proceeding with the installation..."
    script_divider
else
    error_exit "Currently, $DISTRO is not supported. Please let us know your distro."
fi

# Making the 'distro' variable available to all the scripts that are imported here
export DISTRO



main() {
    generate_log_files

    log_info "\nRefreshing the local list of available software packages from online repositories...\n"

    update_apt
    script_divider

    run_module "system utilities" install_system_utilities

    run_module "ZSH" install_zsh_suit

    run_module "POSTGRESQL" install_postgresql_suit

    run_module "DBEAVER" install_dbeaver

    run_module "BROWSER" install_browsers

    run_module "WEBSTORM" install_webstorm

    run_module "PYCHARM" install_pycharm_community

    run_module "VS CODE" install_vs_code

    run_module "GOLANG" install_golang

    run_module "PYTHON & PYTHON_DEV_ENV" setup_python_dev_env

    run_module "DOCKER SUITE" install_docker_suite
}

main