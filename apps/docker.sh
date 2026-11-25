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
  CONFLICTING_PACKAGES=$(dpkg --get-selections docker.io docker-compose docker-compose-v2 docker-doc docker-buildx podman-docker containerd runc 2>/dev/null | cut -f1)
  . /etc/os-release
  if [[ "${ID:-}" == "ubuntu" || -n "${UBUNTU_CODENAME:-}" ]]; then
    OS_ID="ubuntu"
    SUITE="${UBUNTU_CODENAME:-${VERSION_CODENAME:-}}"
  else
    OS_ID="debian"
    SUITE="${DEBIAN_CODENAME:-${VERSION_CODENAME:-}}"
  fi
  if [[ -z "$SUITE" ]]; then
    log_error "Could not determine distribution codename from /etc/os-release."
    exit 1
  fi
  if [[ -n "$CONFLICTING_PACKAGES" ]]; then
    log_info "Removing conflicting packages..."
    run_privileged apt remove -y $CONFLICTING_PACKAGES
  fi
  log_info "Updating repo sources..."
  run_privileged apt update -qq
  log_info "Installing docker..."
  run_privileged apt install -y ca-certificates curl
  run_privileged install -m 0755 -d /etc/apt/keyrings
  run_privileged curl -fsSL https://download.docker.com/linux/${OS_ID}/gpg -o /etc/apt/keyrings/docker.asc
  run_privileged chmod a+r /etc/apt/keyrings/docker.asc
  run_privileged tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/${OS_ID}
Suites: ${SUITE}
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF
  run_privileged apt update -qq
  run_privileged apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  ;;
dnf)
  log_info "Removing old/conflicting packages..."
  run_privileged dnf remove -y docker \
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
  run_privileged dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  ;;
*)
  log_error "Unsupported package manager for docker installation."
  exit 1
  ;;
esac

TARGET_USER="${SUDO_USER:-${USER:-$(id -un)}}"
run_privileged usermod -aG docker "$TARGET_USER"
log_info "Added $TARGET_USER to the docker group. Log out and back in, or run 'newgrp docker', to apply."

log_success "Docker installed successfully!"
