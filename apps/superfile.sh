#!/usr/bin/env bash
# ==============================================================================
# Superfile Installer Script
# Reference: https://github.com/yorukot/superfile
# description: Modern, fancy and fast terminal file manager (spf)
# command: spf
# ==============================================================================
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DIR/lib/utils.sh"

prepend_path "$HOME/.local/bin"

LATEST_VERSION="$(get_github_latest_version "yorukot/superfile" "1.6.0")"

# ------------------------------------------------------------------------------
# Check if superfile (spf) is already installed and up to date
# ------------------------------------------------------------------------------
ensure_bin_alias spf superfile
ensure_bin_alias superfile spf
if is_cmd_up_to_date "superfile" "$LATEST_VERSION" spf superfile; then
    exit 0
fi

log_info "Installing superfile (v${LATEST_VERSION})..."

# ------------------------------------------------------------------------------
# Resolve platform asset name
# ------------------------------------------------------------------------------
OS="$(uname -s)"
ARCH="$(uname -m)"
OS_NAME=""
ARCH_NAME=""

case "$OS" in
    Linux|linux)
        OS_NAME="linux"
        ;;
    Darwin|darwin)
        OS_NAME="darwin"
        ;;
    *)
        log_error "Unsupported operating system: $OS"
        exit 1
        ;;
esac

case "$ARCH" in
    x86_64|amd64)
        ARCH_NAME="amd64"
        ;;
    aarch64|arm64)
        ARCH_NAME="arm64"
        ;;
    armv7*|armhf)
        ARCH_NAME="armv7"
        ;;
    i386|i686)
        ARCH_NAME="386"
        ;;
    *)
        log_error "Unsupported architecture for superfile prebuilt: $ARCH"
        exit 1
        ;;
esac

# ------------------------------------------------------------------------------
# Download and install prebuilt package from GitHub releases
# ------------------------------------------------------------------------------
RELEASE_JSON=""
if has_cmd curl; then
    RELEASE_JSON="$(curl -fsSL https://api.github.com/repos/yorukot/superfile/releases/latest 2>/dev/null || true)"
fi
DOWNLOAD_URL=""

if [[ -n "$RELEASE_JSON" ]]; then
    DOWNLOAD_URL="$(echo "$RELEASE_JSON" | grep -E "browser_download_url.*superfile-${OS_NAME}.*${ARCH_NAME}\.tar\.gz" | head -n 1 | cut -d '"' -f 4)"
    if [[ -z "$DOWNLOAD_URL" ]]; then
        DOWNLOAD_URL="$(echo "$RELEASE_JSON" | grep -E "browser_download_url.*${ARCH_NAME}.*\.tar\.gz" | head -n 1 | cut -d '"' -f 4)"
    fi
fi

log_info "Downloading superfile prebuilt package..."
if ! install_tar_binary "spf|superfile" "spf" \
    "$DOWNLOAD_URL" \
    "https://github.com/yorukot/superfile/releases/download/v${LATEST_VERSION}/superfile-${OS_NAME}-v${LATEST_VERSION}-${ARCH_NAME}.tar.gz" \
    "https://github.com/yorukot/superfile/releases/latest/download/superfile-${OS_NAME}-v${LATEST_VERSION}-${ARCH_NAME}.tar.gz" \
    "https://github.com/yorukot/superfile/releases/latest/download/superfile-${OS_NAME}-${ARCH_NAME}.tar.gz"; then
    # Fallback to official install script
    log_warn "Direct download failed, falling back to official superfile installer script..."
    if run_remote_script bash https://superfile.dev/install.sh; then
        ensure_bin_alias spf superfile
        exit 0
    else
        log_error "Failed to install superfile."
        exit 1
    fi
fi

ln -sf "$HOME/.local/bin/spf" "$HOME/.local/bin/superfile"
if [[ $EUID -eq 0 ]] || has_cmd sudo; then
    run_privileged ln -sf /usr/local/bin/spf /usr/local/bin/superfile 2>/dev/null || true
fi

# ------------------------------------------------------------------------------
# Verify installation
# ------------------------------------------------------------------------------
prepend_path "$HOME/.local/bin"

if has_cmd spf || has_cmd superfile; then
    log_success "superfile installed successfully: $($(spf --version || superfile --version) 2>/dev/null | head -n 1 || echo 'spf in PATH')"
else
    log_error "superfile installation could not be verified."
    exit 1
fi
