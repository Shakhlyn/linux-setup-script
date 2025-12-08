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
source ./pycharm-community.sh
#source ./webstorm.sh
source ./zsh_shell.sh


detect_distro

if [[ $? -eq 1 ]]; then
  error_exit "Cannot detect your Linux distro!"
fi

# Making the 'distro' variable available to all the scripts that are imported here
export DISTRO

install_pycharm_community

#main
install_zsh_suit
