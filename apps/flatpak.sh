#!/usr/bin/env bash
# ==============================================================================
# Flatpak Installer Script
# description: Application sandboxing and desktop runtime environment (flatpak)
# command: flatpak
# ==============================================================================
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DIR/lib/utils.sh"

# Flatpak is exclusively supported on Linux
if [[ "$(detect_os)" == "macos" || "$(detect_os)" == "windows" ]]; then
  log_error "Flatpak is only supported on Linux operating systems."
  exit 1
fi

setup_flathub_remote() {
  log_info "Configuring Flathub remote repository..."
  # Attempt system-wide remote first, fallback to user remote
  if ! flatpak remotes 2>/dev/null | grep -q "flathub"; then
    if run_privileged flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null; then
      log_success "Flathub system remote added."
    elif flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null; then
      log_success "Flathub user remote added."
    else
      log_warn "Could not automatically add Flathub remote (may require network or permissions)."
    fi
  else
    log_dim "Flathub remote is already configured."
  fi
}

# ------------------------------------------------------------------------------
# Check if Flatpak is already installed
# ------------------------------------------------------------------------------
if has_cmd flatpak; then
  log_success "Flatpak is already installed ($(flatpak --version | head -n 1))"
  setup_flathub_remote
  exit 0
fi

# ------------------------------------------------------------------------------
# Install Flatpak Runtime
# ------------------------------------------------------------------------------
log_info "Installing Flatpak runtime..."
if ! pkg_install flatpak brew=; then
  log_error "Unsupported package manager or failed to install Flatpak."
  exit 1
fi

# ------------------------------------------------------------------------------
# Post-Installation Setup
# ------------------------------------------------------------------------------
# Ensure Flatpak export directories exist
ensure_dir "$HOME/.local/share/flatpak/exports/bin"

# Configure Flathub remote
setup_flathub_remote

log_success "Flatpak runtime installed successfully: $(flatpak --version 2>/dev/null || echo 'flatpak')"
