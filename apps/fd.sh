#!/usr/bin/env bash
# ==============================================================================
# fd Installer Script (by sharkdp)
# description: Simple, fast and user-friendly alternative to find (fd)
# command: fd
# ==============================================================================
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DIR/lib/utils.sh"

prepend_path "$HOME/.local/bin"

# Check if already installed
if has_cmd fd || has_cmd fdfind; then
  # Ensure 'fd' symlink exists if installed as 'fdfind' (Debian/Ubuntu)
  ensure_bin_alias fdfind fd
  log_success "fd is already installed ($($(fd --version || fdfind --version) 2>/dev/null | head -n 1))"
  exit 0
fi

log_info "Installing fd (by sharkdp)..."
rc=0
pkg_install fd apt=fd-find dnf=fd-find || rc=$?

if [[ $rc -eq 0 ]]; then
  ensure_bin_alias fdfind fd
elif [[ $rc -eq 2 ]]; then
  # Fallback: GitHub binary release from sharkdp/fd
  if has_cmd tar && { has_cmd curl || has_cmd wget; }; then
    log_info "Attempting GitHub binary release download from sharkdp/fd..."
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
    LATEST_VERSION="$(get_github_latest_version "sharkdp/fd" "10.2.0")"
    LATEST_TAG="v${LATEST_VERSION#v}"
    install_tar_binary "fd" "fd" \
      "https://github.com/sharkdp/fd/releases/download/${LATEST_TAG}/fd-${LATEST_TAG}-${FD_ARCH}.tar.gz"
  elif has_cmd cargo; then
    cargo install fd-find
  else
    log_error "Unsupported package manager or missing curl/tar for fd installation."
    exit 1
  fi
else
  exit "$rc"
fi

prepend_path "$HOME/.local/bin"

if has_cmd fd; then
  log_success "fd installed successfully: $(fd --version)"
elif has_cmd fdfind; then
  log_success "fd installed successfully (as fdfind): $(fdfind --version)"
else
  log_success "fd installed to ~/.local/bin/fd."
fi
