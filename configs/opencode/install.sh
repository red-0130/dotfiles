#!/usr/bin/env bash
# ==============================================================================
# configs/opencode/install.sh - Custom install hook for OpenCode configuration
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
fi

if [[ -f "$DOTFILES_DIR/lib/backup.sh" ]]; then
  # shellcheck source=/dev/null
  source "$DOTFILES_DIR/lib/backup.sh"
fi

SRC_CONFIG="${SCRIPT_DIR}/opencode.json"
TARGET_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
TARGET_FILE="${TARGET_DIR}/opencode.json"

if [[ ! -f "$SRC_CONFIG" ]]; then
  log_error "Source config file not found: $SRC_CONFIG"
  exit 1
fi

# If target directory exists as a symlink from earlier linking, remove it
if [[ -L "$TARGET_DIR" ]]; then
  rm -f "$TARGET_DIR"
fi

# Ensure destination directory exists (whether it previously existed or not)
mkdir -p "$TARGET_DIR"

# If target file exists and differs from source, create a backup
if [[ -f "$TARGET_FILE" ]] && ! cmp -s "$SRC_CONFIG" "$TARGET_FILE"; then
  if declare -f backup_target >/dev/null 2>&1; then
    backup_target "$TARGET_FILE"
  fi
fi

# Copy the configuration file directly
cp -f "$SRC_CONFIG" "$TARGET_FILE"
log_success "Copied OpenCode config to ${TARGET_FILE/#$HOME/~}"
