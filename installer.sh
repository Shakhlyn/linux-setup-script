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
source ./golang.sh


detect_distro

if [[ $? -eq 1 ]]; then
  error_exit "Cannot detect your Linux distro!"
fi

# Making the 'distro' variable available to all the scripts that are imported here
export DISTRO

main() {
  install_pycharm_community

  install_zsh_suit

  install_golang
}

main