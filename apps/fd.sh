#!/usr/bin/env bash
# ==============================================================================
# fd Installer Script (by sharkdp)
# description: Simple, fast and user-friendly alternative to find (fd)
# command: fd
# ==============================================================================
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DIR/lib/utils.sh"

if [[ -d "$HOME/.local/bin" ]] && [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
  export PATH="$HOME/.local/bin:$PATH"
fi

# Check if already installed
if has_cmd fd || has_cmd fdfind; then
  # Ensure 'fd' symlink exists if installed as 'fdfind' (Debian/Ubuntu)
  if ! has_cmd fd && has_cmd fdfind; then
    ensure_dir "$HOME/.local/bin"
    ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
  fi
  log_success "fd is already installed ($($(fd --version || fdfind --version) 2>/dev/null | head -n 1))"
  exit 0
fi

log_info "Installing fd (by sharkdp)..."
PKG="$(detect_pkg_manager)"

case "$PKG" in
apt)
  # Debian and Ubuntu package fd as 'fd-find' with binary 'fdfind'
  run_privileged apt-get update -qq
  run_privileged apt-get install -y fd-find
  ensure_dir "$HOME/.local/bin"
  if has_cmd fdfind && ! has_cmd fd; then
    ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
  fi
  ;;
brew)
  brew install fd
  ;;
pacman)
  run_privileged pacman -Sy --noconfirm fd
  ;;
dnf)
  # Fedora / RHEL packages as 'fd-find'
  run_privileged dnf install -y fd-find
  ensure_dir "$HOME/.local/bin"
  if has_cmd fdfind && ! has_cmd fd; then
    ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
  fi
  ;;
apk)
  run_privileged apk add fd
  ;;
zypper)
  run_privileged zypper install -y fd
  ;;
*)
  # Fallback: GitHub binary release from sharkdp/fd
  if has_cmd curl && has_cmd tar; then
    log_info "Attempting GitHub binary release download from sharkdp/fd..."
    ensure_dir "$HOME/.local/bin"
    ARCH="$(uname -m)"
    case "$ARCH" in
    x86_64) FD_ARCH="x86_64-unknown-linux-musl" ;;
    aarch64 | arm64) FD_ARCH="aarch64-unknown-linux-musl" ;;
    armv7l | armhf) FD_ARCH="arm-unknown-linux-musleabihf" ;;
    *)
      log_error "Unsupported architecture for fd binary: $ARCH"
      exit 1
      ;;
    esac
    TMP_DIR="$(mktemp -d)"
    LATEST_TAG="$(curl -fsSL https://api.github.com/repos/sharkdp/fd/releases/latest 2>/dev/null | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' || echo "v10.2.0")"
    if [[ -z "$LATEST_TAG" ]]; then
      LATEST_TAG="v10.2.0"
    fi
    curl -fsSL "https://github.com/sharkdp/fd/releases/download/${LATEST_TAG}/fd-${LATEST_TAG}-${FD_ARCH}.tar.gz" -o "$TMP_DIR/fd.tar.gz"
    tar -xzf "$TMP_DIR/fd.tar.gz" -C "$TMP_DIR"
    install -m 755 "$TMP_DIR"/fd-*/fd "$HOME/.local/bin/fd"
    rm -rf "$TMP_DIR"
  elif has_cmd cargo; then
    cargo install fd-find
  else
    log_error "Unsupported package manager or missing curl/tar for fd installation."
    exit 1
  fi
  ;;
esac

# Ensure ~/.local/bin is in PATH if installed there
if [[ -d "$HOME/.local/bin" ]] && [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
  export PATH="$HOME/.local/bin:$PATH"
fi

if has_cmd fd; then
  log_success "fd installed successfully: $(fd --version)"
elif has_cmd fdfind; then
  log_success "fd installed successfully (as fdfind): $(fdfind --version)"
else
  log_success "fd installed to ~/.local/bin/fd."
fi
