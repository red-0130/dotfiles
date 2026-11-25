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
if ! pkg_install podman; then
  log_error "Unsupported package manager or failed to install podman."
  exit 1
fi

log_success "Podman installed successfully: $(podman --version)"
