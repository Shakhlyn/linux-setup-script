#!/bin/bash

source ./utils/lib-logger.sh
#source ./utils/utils.sh


run_module() {
    local name="$1"
    shift
    
    log_success "${name} installation successful"

    "$@"
    local status=$?

    if [[ $status -ne 0 ]]; then
        log_fail "$name installation failed"
    fi

    script_divider
    return $status
}