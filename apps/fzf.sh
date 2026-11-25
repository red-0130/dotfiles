#!/usr/bin/env bash
# ==============================================================================
# FZF Installer Script
# description: Command-line fuzzy finder with interactive shell integration
# command: fzf
# ==============================================================================
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DIR/lib/utils.sh"

prepend_path "$HOME/.local/bin"

if has_cmd fzf; then
  log_success "FZF is already installed ($(fzf --version | head -n 1))"
  exit 0
fi

log_info "Installing FZF..."

install_fzf_github_binary() {
  log_info "Downloading latest fzf binary from GitHub releases..."
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
  version="$(get_github_latest_version "junegunn/fzf" "0.74.5")"
  local tar_url="https://github.com/junegunn/fzf/releases/download/v${version}/fzf-${version}-${fzf_arch}.tar.gz"

  if ! install_tar_binary "fzf" "fzf" "$tar_url"; then
    log_error "Failed to download fzf binary from GitHub: $tar_url"
    exit 1
  fi
}

if [[ "$(detect_pkg_manager)" == "apt" ]]; then
  # On Debian/Ubuntu, apt repositories typically contain outdated fzf versions.
  # Use official GitHub binary release to ensure modern fzf.
  install_fzf_github_binary
else
  rc=0
  pkg_install fzf || rc=$?
  if [[ $rc -eq 2 ]]; then
    install_fzf_github_binary
  elif [[ $rc -ne 0 ]]; then
    exit "$rc"
  fi
fi

prepend_path "$HOME/.local/bin"

log_success "FZF installed successfully: $(fzf --version 2>/dev/null | head -n 1 || echo 'fzf in ~/.local/bin')"
