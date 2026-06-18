##!/bin/bash

set -uo pipefail
IFS=$'\n\t'

# =============================================================================
# Script to install Docker Engine, Docker CLI, Docker Compose, and related
# suite components on Ubuntu/Pop!_OS and Fedora
# =============================================================================

source ./utils/lib-logger.sh
source ./utils/utils.sh

# ─────────────────────────────────────────────────────────────────────────────
# purge_old_docker
# Removes any conflicting legacy Docker packages before a fresh install.
# ─────────────────────────────────────────────────────────────────────────────

purge_old_docker_ubuntu() {
    log_info "Removing conflicting/legacy Docker packages (if any)..."

    local legacy_pkgs=(
        docker.io docker-doc docker-compose docker-compose-v2
        podman-docker containerd runc
    )

    for pkg in "${legacy_pkgs[@]}"; do
        if dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"; then
            log_warn "Removing legacy package: $pkg"
            sudo apt remove -y "$pkg" || log_warn "Could not remove $pkg — continuing anyway"
        fi
    done

    log_success "Legacy Docker packages cleared.\n"
}

purge_old_docker_fedora() {
    log_info "Removing conflicting/legacy Docker packages (if any)..."

    local legacy_pkgs=(
        docker docker-client docker-client-latest docker-common
        docker-latest docker-latest-logrotate docker-logrotate docker-selinux
        docker-engine-selinux docker-engine
    )

    for pkg in "${legacy_pkgs[@]}"; do
        if rpm -q "$pkg" &>/dev/null; then
            log_warn "Removing legacy package: $pkg"
            sudo dnf remove -y "$pkg" || log_warn "Could not remove $pkg — continuing anyway"
        fi
    done

    log_success "Legacy Docker packages cleared.\n"
}

purge_old_docker() {
    case "${DISTRO:-}" in
        ubuntu|lubuntu|pop)
            purge_old_docker_ubuntu
            ;;
        fedora)
            purge_old_docker_fedora
            ;;
        *)
            log_error "purge_old_docker: Unsupported distribution '${DISTRO:-unset}'."
            return 1
            ;;
    esac
}

# ─────────────────────────────────────────────────────────────────────────────
# set_docker_repo
# Adds the official Docker repository and GPG key, distro-aware.
# ─────────────────────────────────────────────────────────────────────────────

set_docker_repo_ubuntu() {
    if [[ -f /etc/apt/sources.list.d/docker.list ]]; then
        log_confirm "Docker APT repository already exists. Skipping."
        return 0
    fi

    log_info "Installing APT transport prerequisites..."

    install_packages ca-certificates curl || return 1

    log_info "Importing Docker GPG key..."
    sudo install -m 0755 -d /etc/apt/keyrings
    if ! sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
            -o /etc/apt/keyrings/docker.asc; then
        log_error "Failed to download Docker GPG key."
        return 1
    fi
    sudo chmod a+r /etc/apt/keyrings/docker.asc
    log_info "Docker GPG key imported."

    log_info "Adding Docker APT repository..."
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" \
        | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    if [[ $? -ne 0 ]]; then
        log_error "Failed to add Docker APT repository."
        return 1
    fi

    log_success "Docker APT repository added.\n"
}

set_docker_repo_fedora() {
    if [[ -f /etc/yum.repos.d/docker-ce.repo ]]; then
        log_confirm "Docker DNF repository already exists. Skipping."
        return 0
    fi

    log_info "Adding Docker DNF repository..."
    if ! sudo dnf config-manager --add-repo \
            https://download.docker.com/linux/fedora/docker-ce.repo; then
        log_error "Failed to add Docker DNF repository."
        return 1
    fi

    log_success "Docker DNF repository added.\n"
}

set_docker_repo() {
    case "${DISTRO:-}" in
        ubuntu|lubuntu|pop)
            set_docker_repo_ubuntu
            ;;
        fedora)
            set_docker_repo_fedora
            ;;
        *)
            log_error "set_docker_repo: Unsupported distribution '${DISTRO:-unset}'."
            return 1
            ;;
    esac
}

# ─────────────────────────────────────────────────────────────────────────────
# install_docker_packages
# Installs the full Docker suite.
# ─────────────────────────────────────────────────────────────────────────────

install_docker_packages() {
    log_info "Installing Docker suite packages..."

    update_packages || return 1

    install_packages \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin \
    || return 1

    log_success "All Docker suite packages installed.\n"
}

# ─────────────────────────────────────────────────────────────────────────────
# enable_docker_service
# Enables and starts the Docker daemon via systemd.
# ─────────────────────────────────────────────────────────────────────────────

enable_docker_service() {
    log_info "Enabling Docker service..."

    if systemctl is-active --quiet docker; then
        log_confirm "Docker service is already running."
        return 0
    fi

    sudo systemctl enable --now docker

    if systemctl is-active --quiet docker; then
        log_success "Docker service started and enabled on boot.\n"
        return 0
    fi

    log_error "Docker service failed to start."
    return 1
}

# ─────────────────────────────────────────────────────────────────────────────
# add_user_to_docker_group
# Adds the current user to the 'docker' group for rootless CLI usage.
# Now no need to use 'sudo' for every docker command
# ─────────────────────────────────────────────────────────────────────────────

add_user_to_docker_group() {
    log_info "Adding '$USER' to the 'docker' group..."

    if groups "$USER" | grep -qw docker; then
        log_confirm "'$USER' is already in the docker group."
        return 0
    fi

    if ! sudo usermod -aG docker "$USER"; then
        log_error "Failed to add '$USER' to the docker group."
        return 1
    fi

    log_success "'$USER' added to docker group."
    log_warn "NOTE: You must log out and back in (or run 'newgrp docker') for group changes to take effect.\n"
}

# ─────────────────────────────────────────────────────────────────────────────
# verify_docker
# Smoke-tests Docker Engine, CLI, and Compose after install.
# ─────────────────────────────────────────────────────────────────────────────

verify_docker() {
    log_info "Verifying Docker installation..."

    local failed=0

    if is_installed docker &>/dev/null; then
        log_confirm "docker CLI found: $(docker --version)"
    else
        log_error "docker CLI not found."
        failed=1
    fi

    if docker compose version &>/dev/null; then
        log_confirm "docker compose plugin found: $(docker compose version)"
    else
        log_error "docker compose plugin not found."
        failed=1
    fi

    if is_installed containerd &>/dev/null || systemctl is-active --quiet containerd; then
        log_confirm "containerd is present."
    else
        log_warn "containerd status unclear — may still be functional."
    fi

    if [[ $failed -eq 1 ]]; then
        log_error "Docker verification failed. Review the errors above."
        return 1
    fi

    log_info "Running hello-world smoke test..."
    if sudo docker run --rm hello-world &>/dev/null; then
        log_confirm "Docker hello-world smoke test passed.\n"
    else
        log_warn "hello-world smoke test failed — Docker may still work after a re-login.\n"
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# install_docker_suite
# ─────────────────────────────────────────────────────────────────────────────

install_docker_suite() {
    if is_installed docker &>/dev/null; then
        log_confirm "Docker is already installed on this system."
        docker --version
        docker compose version || true
        return 0
    fi

    log_info "Docker not found. Starting full installation..."

    purge_old_docker         || return 1
    set_docker_repo          || return 1
    install_docker_packages  || return 1
    enable_docker_service    || return 1
    add_user_to_docker_group || return 1
    verify_docker            || return 1

    log_success "Docker suite installation complete!"
    log_info "Installed: docker-ce, docker-ce-cli, containerd.io, docker-buildx-plugin, docker-compose-plugin"
    log_info "Run 'newgrp docker' or re-login to use Docker without sudo.\n"
}