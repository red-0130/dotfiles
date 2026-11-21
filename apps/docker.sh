#!/usr/bin/env bash
# ==============================================================================
# Docker Engine Installer Script
# description: Open-source software for deploying and running of containerized applications
# command: docker
# ==============================================================================
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DIR/lib/utils.sh"

if has_cmd docker; then
  log_success "Docker is already installed"
  exit 0
fi

log_info "Installing Docker..."
PKG="$(detect_pkg_manager)"

case "$PKG" in
apt)
  CONFLICTING_PACKAGES=$(dpkg --get-selections docker.io docker-compose docker-compose-v2 docker-doc docker-buildx podman-docker containerd runc | cut -f1)
  . /etc/os-release
  OS_ID=$([ "$ID" = "ubuntu" ] && echo "ubuntu" || echo "debian")
  log_info "Removing conflicting packages..."
  run_privileged apt remove $CONFLICTING_PACKAGES
  log_info "Updating repo sources..."
  run_privileged apt update -qq
  log_info "Installing docker..."
  run_privileged apt install ca-certificates curl
  run_privileged install -m 0755 -d /etc/apt/keyrings
  run_privileged curl -fsSL https://download.docker.com/linux/${OS_ID}/gpg -o /etc/apt/keyrings/docker.asc
  run_privileged chmod a+r /etc/apt/keyrings/docker.asc
  run_privileged tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: ${UBUNTU_VERSION:-$VERSION_CODENAME}
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF
  run_privileged apt update -qq
  run_privileged apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  ;;
dnf)
  log_info "Removing old/conflicting packages..."
  run_privileged dnf remove docker \
    docker-client \
    docker-client-latest \
    docker-common docker-latest \
    docker-latest-logrotate \
    docker-logrotate \
    docker-selinux \
    docker-engine-selinux \
    docker-engine
  log_info "Adding RPM repo..."
  run_privileged dnf config-manager addrepo --from-repofile https://download.docker.com/linux/fedora/docker-ce.repo
  log_info "Installing docker..."
  run_privileged dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  ;;
*)
  log_error "Unsupported package manager for docker installation."
  exit 1
  ;;
esac

run_privileged usermod -aG docker $USER
newgrp docker

log_success "Docker installed successfully!"
