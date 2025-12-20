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

source ./browser.sh

source ./ides/pycharm-community.sh
source ./ides/webstorm.sh
source ./ides/vscode.sh

source ./prog_lang/golang.sh

source ./utility-tools/zsh_shell.sh


detect_distro

if [[ $? -eq 1 ]]; then
  error_exit "Cannot detect your Linux distro!"
fi

# Making the 'distro' variable available to all the scripts that are imported here
export DISTRO

main() {
    log_info "Refreshing the local list of available software packages from online repositories..."
    sudo apt update
    if [[ "$?" -ne 0 ]]; then
        error_exit "Some thing went wrong. Check internet connection. Please try again later\n"
    else
        printf "\n\n"
    fi
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