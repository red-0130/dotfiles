#!/usr/bin/env bash
# ==============================================================================
# Eza Installer Script
# description: Modern, feature-rich replacement for ls
# command: eza
# ==============================================================================
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DIR/lib/utils.sh"

if has_cmd eza; then
  log_success "eza is already installed ($(eza --version | head -n 1))"
  exit 0
fi

log_info "Installing eza..."
PKG="$(detect_pkg_manager)"

case "$PKG" in
brew | pacman | dnf | apk | zypper)
  pkg_install eza
  ;;
apt)
  # Attempt direct apt installation (Debian 13 trixie+, Ubuntu 24.04+)
  run_privileged apt-get update -qq
  if run_privileged apt-get install -y eza 2>/dev/null; then
    log_success "eza installed via apt"
  elif has_cmd curl; then
    # Add official eza apt repository for older Debian/Ubuntu
    log_info "Adding official eza apt repository..."
    add_apt_repo \
      "https://raw.githubusercontent.com/eza-community/eza/main/deb.asc" \
      "/etc/apt/keyrings/gierens.gpg" \
      "deb [signed-by=/etc/apt/keyrings/gierens.gpg] https://deb.gierens.de stable main" \
      "/etc/apt/sources.list.d/gierens.list" \
      "--dearmor"
    run_privileged apt-get install -y eza
  else
    log_error "Could not install eza via apt and curl is unavailable."
    exit 1
  fi
  ;;
*)
  # Fallback: GitHub binary release
  if (has_cmd curl || has_cmd wget) && has_cmd tar; then
    log_info "Attempting GitHub binary release download..."
    ARCH="$(uname -m)"
    case "$ARCH" in
    x86_64) EZA_ARCH="x86_64-unknown-linux-musl" ;;
    aarch64 | arm64) EZA_ARCH="aarch64-unknown-linux-musl" ;;
    armv7l | armhf) EZA_ARCH="arm-unknown-linux-musleabihf" ;;
    *)
      log_error "Unsupported architecture for eza binary: $ARCH"
      exit 1
      ;;
    esac
    install_tar_binary "eza" "eza" "https://github.com/eza-community/eza/releases/latest/download/eza_${EZA_ARCH}.tar.gz"
  elif has_cmd cargo; then
    cargo install eza
  else
    log_error "Unsupported package manager or missing curl/wget/tar for eza installation."
    exit 1
  fi
  ;;
esac

# Ensure ~/.local/bin is in PATH if installed there
prepend_path "$HOME/.local/bin"

log_success "eza installed successfully: $(eza --version 2>/dev/null | head -n 1 || echo 'eza')"
