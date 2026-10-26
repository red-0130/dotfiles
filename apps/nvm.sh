#!/usr/bin/env bash
# ==============================================================================
# Node Version Manager (nvm) Installer Script
# Reference: https://github.com/nvm-sh/nvm#installing-and-updating
# description: Node Version Manager - Simple bash script to manage multiple active node.js versions (nvm)
# command: nvm
# ==============================================================================
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DIR/lib/utils.sh"

export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"

# Source nvm if present in NVM_DIR
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    # shellcheck source=/dev/null
    source "$NVM_DIR/nvm.sh"
fi

# ------------------------------------------------------------------------------
# Helper: Fetch latest tag from GitHub releases
# ------------------------------------------------------------------------------
get_latest_nvm_version() {
    local version=""
    if has_cmd curl; then
        version="$(curl -fsSL https://api.github.com/repos/nvm-sh/nvm/releases/latest 2>/dev/null | grep -m 1 '"tag_name":' | sed -E 's/.*"v?([^"]+)".*/\1/' || true)"
        if [[ -z "$version" ]]; then
            version="$(curl -fsSIL "https://github.com/nvm-sh/nvm/releases/latest" 2>/dev/null | grep -i '^location:' | sed -E 's/.*\/tag\/v?([^ \r\n]+).*/\1/' || true)"
        fi
    fi
    if [[ -z "$version" ]] && has_cmd wget; then
        version="$(wget -qO- https://api.github.com/repos/nvm-sh/nvm/releases/latest 2>/dev/null | grep -m 1 '"tag_name":' | sed -E 's/.*"v?([^"]+)".*/\1/' || true)"
    fi
    if [[ -z "$version" ]]; then
        version="0.40.8"
    fi
    echo "$version"
}

LATEST_VERSION="$(get_latest_nvm_version)"

# ------------------------------------------------------------------------------
# Check if nvm is already installed and up to date
# ------------------------------------------------------------------------------
if has_cmd nvm; then
    CURRENT_VERSION="$(nvm --version 2>/dev/null || echo '')"
    if [[ -n "$CURRENT_VERSION" && -n "$LATEST_VERSION" ]]; then
        if [[ "$(printf '%s\n%s' "$LATEST_VERSION" "$CURRENT_VERSION" | sort -V | head -n1)" == "$LATEST_VERSION" ]]; then
            log_success "nvm is already at the latest version (v${CURRENT_VERSION})"
            exit 0
        else
            log_info "Current nvm (v${CURRENT_VERSION}) is outdated. Upgrading to latest version (v${LATEST_VERSION})..."
        fi
    else
        log_info "nvm is installed. Verifying latest version..."
    fi
fi

log_info "Installing / updating Node Version Manager (nvm) to v${LATEST_VERSION}..."

# ------------------------------------------------------------------------------
# Install or update using official install script
# Reference: https://github.com/nvm-sh/nvm#installing-and-updating
# ------------------------------------------------------------------------------
INSTALL_URL="https://raw.githubusercontent.com/nvm-sh/nvm/v${LATEST_VERSION}/install.sh"
TMP_DIR="$(mktemp -d)"
TMP_SCRIPT="$TMP_DIR/install.sh"

if has_cmd curl; then
    log_info "Downloading official nvm install script via curl..."
    if ! curl -fsSL "$INSTALL_URL" -o "$TMP_SCRIPT" 2>/dev/null; then
        log_warn "Direct download from raw.githubusercontent.com failed, attempting git fallback..."
    fi
elif has_cmd wget; then
    log_info "Downloading official nvm install script via wget..."
    if ! wget -qO "$TMP_SCRIPT" "$INSTALL_URL" 2>/dev/null; then
        log_warn "Direct download from raw.githubusercontent.com failed, attempting git fallback..."
    fi
fi

if [[ -f "$TMP_SCRIPT" && -s "$TMP_SCRIPT" ]]; then
    bash "$TMP_SCRIPT"
    rm -rf "$TMP_DIR"
else
    # Git-based installation fallback as documented in nvm README
    if has_cmd git; then
        log_info "Cloning/updating nvm repository via git..."
        ensure_dir "$NVM_DIR"
        if [[ -d "$NVM_DIR/.git" ]]; then
            (cd "$NVM_DIR" && git fetch --tags origin && git checkout "v${LATEST_VERSION}")
        else
            git clone https://github.com/nvm-sh/nvm.git "$NVM_DIR"
            (cd "$NVM_DIR" && git checkout "v${LATEST_VERSION}")
        fi
    else
        rm -rf "$TMP_DIR"
        log_error "Could not download nvm install script and git is not available."
        exit 1
    fi
fi

# ------------------------------------------------------------------------------
# Source nvm into current session for verification
# ------------------------------------------------------------------------------
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    # shellcheck source=/dev/null
    source "$NVM_DIR/nvm.sh"
fi

if [[ -s "$NVM_DIR/bash_completion" ]]; then
    # shellcheck source=/dev/null
    source "$NVM_DIR/bash_completion" 2>/dev/null || true
fi

# ------------------------------------------------------------------------------
# Verify installation
# ------------------------------------------------------------------------------
if has_cmd nvm; then
    log_success "Node Version Manager (nvm) installed successfully: v$(nvm --version 2>/dev/null || echo "$LATEST_VERSION")"
    log_info "To use nvm in your current shell session, run:"
    log_info "  export NVM_DIR=\"$NVM_DIR\""
    log_info "  [ -s \"\$NVM_DIR/nvm.sh\" ] && \\. \"\$NVM_DIR/nvm.sh\""
else
    if [[ -s "$NVM_DIR/nvm.sh" ]]; then
        log_success "Node Version Manager (nvm) files installed in $NVM_DIR"
        log_info "Load nvm into your shell by running:"
        log_info "  export NVM_DIR=\"$NVM_DIR\""
        log_info "  [ -s \"\$NVM_DIR/nvm.sh\" ] && \\. \"\$NVM_DIR/nvm.sh\""
    else
        log_error "nvm installation could not be completed."
        exit 1
    fi
fi
