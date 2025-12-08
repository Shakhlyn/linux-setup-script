#!/bin/bash

# lib-logger.sh  (or common.sh)

# Reset
RESET='\033[0m'

# Regular Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'

# Bold
BRED='\033[1;31m'
BGREEN='\033[1;32m'
BYELLOW='\033[1;33m'
BBLUE='\033[1;34m'

log_info()    { echo -e "${BLUE}[INFO]${RESET}    $*${RESET}"; }
log_success() { echo -e "${GREEN}[SUCCESS]${RESET} $*${RESET}"; }
log_warn()    { echo -e "${YELLOW}[WARN]${RESET}    $*${RESET}"; }
log_error()   { echo -e "${RED}[ERROR]${RESET}   $*${RESET}"; }
log_debug()   { [[ "$DEBUG" == "1" ]] && echo -e "${CYAN}[DEBUG]${RESET}   $*${RESET}"; }

log_test()    { printf "${BLUE}[INFO]${RESET}    %b\n" "$*"; }