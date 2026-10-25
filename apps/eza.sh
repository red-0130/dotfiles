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
brew)
  brew install eza
  ;;
pacman)
  run_privileged pacman -Sy --noconfirm eza
  ;;
dnf)
  run_privileged dnf install -y eza
  ;;
apk)
  run_privileged apk add eza
  ;;
zypper)
  run_privileged zypper install -y eza
  ;;
apt)
  # Attempt direct apt installation (Debian 13 trixie+, Ubuntu 24.04+)
  run_privileged apt-get update -qq
  if run_privileged apt-get install -y eza 2>/dev/null; then
    log_success "eza installed via apt"
  elif has_cmd curl; then
    # Add official eza apt repository for older Debian/Ubuntu
    log_info "Adding official eza apt repository..."
    run_privileged mkdir -p -m 755 /etc/apt/keyrings
    if has_cmd gpg; then
      curl -fsSL https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | run_privileged gpg --dearmor --yes -o /etc/apt/keyrings/gierens.gpg
    else
      curl -fsSL https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | run_privileged dd of=/etc/apt/keyrings/gierens.gpg
    fi
    run_privileged chmod 644 /etc/apt/keyrings/gierens.gpg
    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | run_privileged tee /etc/apt/sources.list.d/gierens.list >/dev/null
    run_privileged chmod 644 /etc/apt/sources.list.d/gierens.list
    run_privileged apt-get update -qq
    run_privileged apt-get install -y eza
  else
    log_error "Could not install eza via apt and curl is unavailable."
    exit 1
  fi
  ;;
*)
  # Fallback: GitHub binary release
  if has_cmd curl && has_cmd tar; then
    log_info "Attempting GitHub binary release download..."
    ensure_dir "$HOME/.local/bin"
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
    TMP_DIR="$(mktemp -d)"
    curl -fsSL "https://github.com/eza-community/eza/releases/latest/download/eza_${EZA_ARCH}.tar.gz" -o "$TMP_DIR/eza.tar.gz"
    tar -xzf "$TMP_DIR/eza.tar.gz" -C "$TMP_DIR"
    install -m 755 "$TMP_DIR/eza" "$HOME/.local/bin/eza"
    rm -rf "$TMP_DIR"
  elif has_cmd cargo; then
    cargo install eza
  else
    log_error "Unsupported package manager or missing curl/tar for eza installation."
    exit 1
  fi
  ;;
esac

# Ensure ~/.local/bin is in PATH if installed there
if [[ -d "$HOME/.local/bin" ]] && [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
  export PATH="$HOME/.local/bin:$PATH"
fi

log_success "eza installed successfully: $(eza --version 2>/dev/null | head -n 1 || echo 'eza')"
