#!/usr/bin/env bash
# ==============================================================================
# configs/ssh/install.sh - Custom install hook for OpenSSH configuration
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

SRC_CONFIG="${SCRIPT_DIR}/config"
XDG_SSH_DIR="${HOME}/.config/ssh"
XDG_SSH_CONFIG="${XDG_SSH_DIR}/config"
ORIG_SSH_DIR="${HOME}/.ssh"
ORIG_SSH_CONFIG="${ORIG_SSH_DIR}/config"
INCLUDE_LINE="Include ~/.config/ssh/config"

# Ensure source dotfile config exists with 0600 permissions
if [[ -f "$SRC_CONFIG" ]]; then
  chmod 600 "$SRC_CONFIG"
else
  log_error "Source SSH config file not found: $SRC_CONFIG"
  exit 1
fi

# Ensure ~/.config/ssh directory exists and symlink dotfiles config
ensure_dir "$XDG_SSH_DIR"
chmod 700 "$XDG_SSH_DIR"

if command -v safe_symlink >/dev/null 2>&1; then
  safe_symlink "$SRC_CONFIG" "$XDG_SSH_CONFIG"
else
  if [[ -L "$XDG_SSH_CONFIG" && "$(readlink "$XDG_SSH_CONFIG")" == "$SRC_CONFIG" ]]; then
    log_info "Already linked: ~/.config/ssh/config"
  else
    ln -sf "$SRC_CONFIG" "$XDG_SSH_CONFIG"
    log_success "Linked: ~/.config/ssh/config -> $SRC_CONFIG"
  fi
fi
chmod 600 "$XDG_SSH_CONFIG" 2>/dev/null || true

# Ensure ~/.ssh directory exists with strict permissions (0700)
# Handles cold-start case when ~/.ssh does not exist yet
if [[ ! -d "$ORIG_SSH_DIR" ]]; then
  log_info "Creating directory: $ORIG_SSH_DIR (0700)"
  mkdir -m 700 -p "$ORIG_SSH_DIR"
else
  chmod 700 "$ORIG_SSH_DIR"
fi

mkdir -m 700 -p "$ORIG_SSH_DIR/sockets"

# If ~/.ssh/config was previously a symlink pointing to dotfiles, remove it
if [[ -L "$ORIG_SSH_CONFIG" ]]; then
  local_target="$(readlink "$ORIG_SSH_CONFIG")"
  if [[ "$local_target" == "$SRC_CONFIG" || "$local_target" == "$XDG_SSH_CONFIG" ]]; then
    log_info "Replacing legacy symlinked ~/.ssh/config with real file containing Include directive"
    rm -f "$ORIG_SSH_CONFIG"
  fi
fi

# Handle ~/.ssh/config:
#    - If absent: create fresh file with 0600 permissions and 'Include ~/.config/ssh/config'
#    - If present: prepend 'Include ~/.config/ssh/config' to the top if not already there
if [[ -f "$ORIG_SSH_CONFIG" ]]; then
  if grep -qE '^[[:space:]]*Include[[:space:]]+.*\.config/ssh/config' "$ORIG_SSH_CONFIG"; then
    log_dim "Include directive already present in $ORIG_SSH_CONFIG"
  else
    log_info "Prepending Include directive to top of $ORIG_SSH_CONFIG"
    temp_file="$(mktemp)"
    {
      echo "$INCLUDE_LINE"
      echo ""
      cat "$ORIG_SSH_CONFIG"
    } >"$temp_file"
    cat "$temp_file" >"$ORIG_SSH_CONFIG"
    rm -f "$temp_file"
    chmod 600 "$ORIG_SSH_CONFIG"
    log_success "Prepended '$INCLUDE_LINE' to $ORIG_SSH_CONFIG"
  fi
else
  log_info "Creating fresh $ORIG_SSH_CONFIG (0600) with Include directive"
  (
    umask 077
    {
      echo "$INCLUDE_LINE"
      echo ""
    } >"$ORIG_SSH_CONFIG"
  )
  chmod 600 "$ORIG_SSH_CONFIG"
  log_success "Created $ORIG_SSH_CONFIG with '$INCLUDE_LINE'"
fi

log_success "SSH configuration installed: dotfiles linked to ~/.config/ssh/config and included in ~/.ssh/config."
