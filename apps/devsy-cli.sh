#!/usr/bin/env bash
# ==============================================================================
# Devsy CLI Installer Script
# Reference: https://github.com/devsy-org/devsy
# description: Standardized dev workspaces CLI across Docker, Kubernetes, cloud, and SSH
# command: devsy
# ==============================================================================
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DIR/lib/utils.sh"

TARGET_DIR="${DEVSY_INSTALL_DIR:-$HOME/.local/bin}"
prepend_path "$TARGET_DIR"
prepend_path "$HOME/.local/bin"

LATEST_VERSION="$(get_github_latest_version "devsy-org/devsy" "")"

if is_cmd_up_to_date "devsy" "$LATEST_VERSION" --keep-if-offline devsy "$TARGET_DIR/devsy"; then
    exit 0
fi

log_info "Installing devsy CLI..."
PKG="$(detect_pkg_manager)"

if [[ "$PKG" == "brew" ]]; then
    if brew list devsy-org/tap/devsy &>/dev/null || brew list devsy &>/dev/null; then
        brew upgrade devsy-org/tap/devsy || true
    else
        brew install devsy-org/tap/devsy
    fi
elif has_cmd curl || has_cmd wget; then
    ensure_dir "$TARGET_DIR"
    DEVSY_INSTALL_DIR="$TARGET_DIR" run_remote_script sh https://devsy.sh/install.sh
else
    log_error "brew, curl, or wget is required to install devsy CLI."
    exit 1
fi

if has_cmd devsy || [[ -x "$TARGET_DIR/devsy" ]]; then
    VER="$($(command -v devsy || echo "$TARGET_DIR/devsy") --version 2>/dev/null | head -n 1 || echo 'installed')"
    log_success "devsy CLI installed successfully ($VER)"
else
    log_error "devsy CLI installation could not be verified."
    exit 1
fi
