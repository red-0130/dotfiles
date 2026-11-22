#!/usr/bin/env bash
# ==============================================================================
# Podman Installer Script
# description: Tool for managing OCI containers and pods
# command: podman
# ==============================================================================
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DIR/lib/utils.sh"

if has_cmd podman; then
  log_success "Podman is already installed ($(podman --version))"
  exit 0
fi

log_info "Installing Podman..."
PKG="$(detect_pkg_manager)"

case "$PKG" in
  apt)
    run_privileged apt-get update -qq
    run_privileged apt-get install -y podman
    ;;
  brew)
    brew install podman
    ;;
  pacman)
    run_privileged pacman -Sy --noconfirm podman
    ;;
  dnf)
    run_privileged dnf install -y podman
    ;;
  apk)
    run_privileged apk add podman
    ;;
  zypper)
    run_privileged zypper install -y podman
    ;;
  *)
    log_error "Unsupported package manager for podman installation."
    exit 1
    ;;
esac

log_success "Podman installed successfully: $(podman --version)"
