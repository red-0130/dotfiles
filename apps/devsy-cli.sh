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
if [[ -d "$TARGET_DIR" ]] && [[ ":$PATH:" != *":$TARGET_DIR:"* ]]; then
    export PATH="$TARGET_DIR:$PATH"
fi
if [[ -d "$HOME/.local/bin" ]] && [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

get_latest_devsy_version() {
    local url="https://github.com/devsy-org/devsy/releases/latest"
    if has_cmd curl; then
        curl -fsSIL "$url" 2>/dev/null | grep -i '^location:' | sed -E 's/.*\/tag\/v?([^ \r\n]+).*/\1/' | head -n 1 || true
    fi
}

LATEST_VERSION="$(get_latest_devsy_version)"

if has_cmd devsy; then
    CURRENT_VERSION="$(devsy --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n 1 || echo '')"
    if [[ -n "$CURRENT_VERSION" && -n "$LATEST_VERSION" ]]; then
        if [[ "$(printf '%s\n%s' "$LATEST_VERSION" "$CURRENT_VERSION" | sort -V | head -n1)" == "$LATEST_VERSION" ]]; then
            log_success "devsy is already at the latest version (v${CURRENT_VERSION})"
            exit 0
        fi
        log_info "Current devsy (v${CURRENT_VERSION}) is outdated. Upgrading to v${LATEST_VERSION}..."
    elif [[ -n "$CURRENT_VERSION" ]]; then
        log_success "devsy is already installed (v${CURRENT_VERSION})"
        exit 0
    fi
fi

log_info "Installing devsy CLI..."
PKG="$(detect_pkg_manager)"

if [[ "$PKG" == "brew" ]]; then
    if brew list devsy-org/tap/devsy &>/dev/null || brew list devsy &>/dev/null; then
        brew upgrade devsy-org/tap/devsy || true
    else
        brew install devsy-org/tap/devsy
    fi
elif has_cmd curl; then
    ensure_dir "$TARGET_DIR"
    (
        set -o pipefail
        curl -fsSL https://devsy.sh/install.sh | DEVSY_INSTALL_DIR="$TARGET_DIR" sh
    )
else
    log_error "brew or curl is required to install devsy CLI."
    exit 1
fi

if has_cmd devsy || [[ -x "$TARGET_DIR/devsy" ]]; then
    VER="$($(command -v devsy || echo "$TARGET_DIR/devsy") --version 2>/dev/null | head -n 1 || echo 'installed')"
    log_success "devsy CLI installed successfully ($VER)"
else
    log_error "devsy CLI installation could not be verified."
    exit 1
fi
