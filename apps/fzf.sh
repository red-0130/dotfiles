#!/usr/bin/env bash
# ==============================================================================
# FZF Installer Script
# description: Command-line fuzzy finder with interactive shell integration
# command: fzf
# ==============================================================================
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DIR/lib/utils.sh"

if [[ -d "$HOME/.local/bin" ]] && [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
  export PATH="$HOME/.local/bin:$PATH"
fi

if has_cmd fzf; then
  log_success "FZF is already installed ($(fzf --version | head -n 1))"
  exit 0
fi

log_info "Installing FZF..."

install_fzf_github_binary() {
  log_info "Downloading latest fzf binary from GitHub releases..."
  ensure_dir "$HOME/.local/bin"
  local arch="$(uname -m)"
  local fzf_arch
  case "$arch" in
  x86_64) fzf_arch="linux_amd64" ;;
  aarch64 | arm64) fzf_arch="linux_arm64" ;;
  armv7l | armhf) fzf_arch="linux_armv7" ;;
  armv6l) fzf_arch="linux_armv6" ;;
  armv5*) fzf_arch="linux_armv5" ;;
  riscv64) fzf_arch="linux_riscv64" ;;
  s390x) fzf_arch="linux_s390x" ;;
  ppc64le) fzf_arch="linux_ppc64le" ;;
  *)
    log_error "Unsupported architecture for fzf: $arch"
    exit 1
    ;;
  esac

  local version
  version="$(curl -fsSL https://api.github.com/repos/junegunn/fzf/releases/latest 2>/dev/null | grep '"tag_name":' | sed -E 's/.*"v?([^"]+)".*/\1/' || echo "0.74.5")"
  if [[ -z "$version" ]]; then
    version="0.74.5"
  fi

  local tmp_dir
  tmp_dir="$(mktemp -d)"
  local tar_url="https://github.com/junegunn/fzf/releases/download/v${version}/fzf-${version}-${fzf_arch}.tar.gz"

  if curl -fsSL "$tar_url" -o "$tmp_dir/fzf.tar.gz"; then
    tar -xzf "$tmp_dir/fzf.tar.gz" -C "$tmp_dir"
    install -m 755 "$tmp_dir/fzf" "$HOME/.local/bin/fzf"
    rm -rf "$tmp_dir"
  else
    rm -rf "$tmp_dir"
    log_error "Failed to download fzf binary from GitHub: $tar_url"
    exit 1
  fi
}

PKG="$(detect_pkg_manager)"

case "$PKG" in
apt)
  # On Debian/Ubuntu, apt repositories typically contain outdated fzf versions.
  # Use official GitHub binary release to ensure modern fzf.
  install_fzf_github_binary
  ;;
brew)
  brew install fzf
  ;;
pacman)
  run_privileged pacman -Sy --noconfirm fzf
  ;;
dnf)
  run_privileged dnf install -y fzf
  ;;
apk)
  run_privileged apk add fzf
  ;;
zypper)
  run_privileged zypper install -y fzf
  ;;
*)
  # Fallback to GitHub binary release
  if has_cmd curl && has_cmd tar; then
    install_fzf_github_binary
  else
    log_error "Cannot install fzf: missing curl or tar for GitHub binary download."
    exit 1
  fi
  ;;
esac

# Ensure ~/.local/bin is in PATH if installed there
if [[ -d "$HOME/.local/bin" ]] && [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
  export PATH="$HOME/.local/bin:$PATH"
fi

log_success "FZF installed successfully: $(fzf --version 2>/dev/null | head -n 1 || echo 'fzf in ~/.local/bin')"
