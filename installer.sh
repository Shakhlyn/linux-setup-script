#!/bin/bash

# -------------------------------
# Importing utility scripts
# -------------------------------
source ./detect-distro.sh
source ./lib-logger.sh
source ./utils.sh


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

source ./browser.sh

source ./ides/pycharm-community.sh
source ./ides/webstorm.sh
source ./ides/vscode.sh

source ./prog_lang/golang.sh

source ./utility-tools/zsh_shell.sh

#===================================================
# Defining all the log files in one place
#===================================================

# Define logs directory (simple relative path)
LOGS_DIR="./logs"

declare -A LOG_FILES

LOG_FILES[log]="${LOGS_DIR}/script.log"
LOG_FILES[success]="${LOGS_DIR}/success.log"
LOG_FILES[error]="${LOGS_DIR}/error.log"

export LOG_FILES

#===================================================
# Core functionalities
#===================================================

detect_distro

if [[ $? -eq 1 ]]; then
  error_exit "Cannot detect your Linux distro!"
fi

# Making the 'distro' variable available to all the scripts that are imported here
export DISTRO


main() {
    generate_log_files

    log_info "Refreshing the local list of available software packages from online repositories..."

    update_apt
    script_divider

    install_system_utilities
    script_divider

    install_browsers
    script_divider

    install_pycharm_community
    script_divider

    install_webstorm
    script_divider

    install_vs_code
    script_divider

    install_zsh_suit
    script_divider

    install_golang
    script_divider
}

main