#!/bin/bash

set -uo pipefail

source ./utils/lib-logger.sh

source ./prog-lang/python-dev/uv.sh


# ─────────────────────────────────────────────────────────────────────────────
# setup_python_dev_env
# Python versions are not managed globally anymore. uv pulls whatever version
# a project needs (`uv python install 3.12`, `uv venv --python 3.12`, or the
# `requires-python` in a project's pyproject.toml), so uv is all we install.
# ─────────────────────────────────────────────────────────────────────────────

setup_python_dev_env() {
    setup_uv || return 1
}
