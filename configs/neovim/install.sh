#!/usr/bin/env bash
# ==============================================================================
# configs/neovim/install.sh - Custom install hook for Neovim configuration
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

# Source library utilities if available
if [[ -f "$DOTFILES_DIR/lib/utils.sh" ]]; then
  # shellcheck source=/dev/null
  source "$DOTFILES_DIR/lib/utils.sh"
else
  log_info() { echo "  ℹ $*"; }
  log_success() { echo "  ✔ $*"; }
  log_warn() { echo "  ⚠ $*" >&2; }
  log_error() { echo "  ✖ $*" >&2; }
  log_dim() { echo "    $*"; }
fi

if ! declare -f ensure_dir >/dev/null 2>&1; then
  ensure_dir() { mkdir -p "$1"; }
fi

if [[ -f "$DOTFILES_DIR/lib/backup.sh" ]]; then
  # shellcheck source=/dev/null
  source "$DOTFILES_DIR/lib/backup.sh"
fi

if [[ -f "$DOTFILES_DIR/lib/link.sh" ]]; then
  # shellcheck source=/dev/null
  source "$DOTFILES_DIR/lib/link.sh"
fi

SRC_DIR="${SCRIPT_DIR}/nvim"
TARGET_DIR="${HOME}/.config/nvim"

if [[ ! -d "$SRC_DIR" ]]; then
  log_error "Neovim config source directory not found: $SRC_DIR"
  exit 1
fi

ensure_dir "${HOME}/.config"

if command -v safe_symlink >/dev/null 2>&1; then
  safe_symlink "$SRC_DIR" "$TARGET_DIR"
else
  if [[ -L "$TARGET_DIR" && "$(readlink "$TARGET_DIR")" == "$SRC_DIR" ]]; then
    log_info "Already linked: ~/.config/nvim"
  else
    ln -sfn "$SRC_DIR" "$TARGET_DIR"
    log_success "Linked: ~/.config/nvim -> $SRC_DIR"
  fi
fi
