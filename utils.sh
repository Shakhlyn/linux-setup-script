#!/bin/bash

source ./lib-logger.sh

# Check if it is already installed
is_installed() {
    if command -v "$1" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}


error_exit() {
  log_error "$1" >&2
  exit 1
}

