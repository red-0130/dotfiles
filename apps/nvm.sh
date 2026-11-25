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

LATEST_VERSION="$(get_github_latest_version "nvm-sh/nvm" "0.40.8")"

# ------------------------------------------------------------------------------
# Check if nvm is already installed and up to date
# ------------------------------------------------------------------------------
if is_cmd_up_to_date "nvm" "$LATEST_VERSION" nvm; then
    exit 0
fi

log_info "Installing / updating Node Version Manager (nvm) to v${LATEST_VERSION}..."

# ------------------------------------------------------------------------------
# Install or update using official install script
# Reference: https://github.com/nvm-sh/nvm#installing-and-updating
# ------------------------------------------------------------------------------
INSTALL_URL="https://raw.githubusercontent.com/nvm-sh/nvm/v${LATEST_VERSION}/install.sh"
if ! (
    tmp_dir="$(mktemp -d)" || exit 1
    trap 'rm -rf "$tmp_dir"' EXIT
    tmp_script="$tmp_dir/install.sh"
    if ! download_file "$tmp_script" "$INSTALL_URL"; then
        exit 2
    fi
    bash "$tmp_script"
); then
    rc=$?
    if [[ $rc -ne 2 ]]; then
        exit "$rc"
    fi
    log_warn "Direct download from raw.githubusercontent.com failed, attempting git fallback..."
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
