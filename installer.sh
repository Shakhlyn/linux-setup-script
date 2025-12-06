#!/bin/bash

# -------------------------------
# Importing utility scripts
# -------------------------------
source ./detect-distro.sh
source ./lib-logger.sh


# -------------------------------
# Importing installation scripts
# -------------------------------
# source ./vscode.sh
source ./pycharm-community.sh
# source ./webstorm.sh


detect_distro

# Making the 'distro' variable available to all the scripts that are imported here
export DISTRO

install_pycharm_community


