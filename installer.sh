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
#source ./vscode.sh
source ./browser.sh
source ./pycharm-community.sh
source ./webstorm.sh
source ./vscode.sh
source ./zsh_shell.sh
source ./golang.sh


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

    install_browsers

    install_pycharm_community

    install_webstorm

    install_vs_code

    install_zsh_suit

    install_golang
  
}

main