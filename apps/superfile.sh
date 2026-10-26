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

if [[ -d "$HOME/.local/bin" ]] && [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

# ------------------------------------------------------------------------------
# Helper: Fetch latest release tag from GitHub releases
# ------------------------------------------------------------------------------
get_latest_superfile_version() {
    local version=""
    if has_cmd curl; then
        version="$(curl -fsSL https://api.github.com/repos/yorukot/superfile/releases/latest 2>/dev/null | grep -m 1 '"tag_name":' | sed -E 's/.*"v?([^"]+)".*/\1/' || true)"
        if [[ -z "$version" ]]; then
            version="$(curl -fsSIL "https://github.com/yorukot/superfile/releases/latest" 2>/dev/null | grep -i '^location:' | sed -E 's/.*\/tag\/v?([^ \r\n]+).*/\1/' || true)"
        fi
    fi
    if [[ -z "$version" ]] && has_cmd wget; then
        version="$(wget -qO- https://api.github.com/repos/yorukot/superfile/releases/latest 2>/dev/null | grep -m 1 '"tag_name":' | sed -E 's/.*"v?([^"]+)".*/\1/' || true)"
    fi
    if [[ -z "$version" ]]; then
        version="1.6.0"
    fi
    echo "$version"
}

LATEST_VERSION="$(get_latest_superfile_version)"

# ------------------------------------------------------------------------------
# Check if superfile (spf) is already installed and up to date
# ------------------------------------------------------------------------------
if has_cmd spf || has_cmd superfile; then
    # Ensure both aliases exist
    if has_cmd spf && ! has_cmd superfile; then
        ensure_dir "$HOME/.local/bin"
        ln -sf "$(command -v spf)" "$HOME/.local/bin/superfile"
    elif has_cmd superfile && ! has_cmd spf; then
        ensure_dir "$HOME/.local/bin"
        ln -sf "$(command -v superfile)" "$HOME/.local/bin/spf"
    fi

    CURRENT_VERSION="$((spf --version || superfile --version) 2>/dev/null | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n 1 || echo '')"
    if [[ -n "$CURRENT_VERSION" && -n "$LATEST_VERSION" ]]; then
        if [[ "$(printf '%s\n%s' "$LATEST_VERSION" "$CURRENT_VERSION" | sort -V | head -n1)" == "$LATEST_VERSION" ]]; then
            log_success "superfile is already at the latest version (v${CURRENT_VERSION})"
            exit 0
        else
            log_info "Current superfile (v${CURRENT_VERSION}) is outdated. Upgrading to latest version (v${LATEST_VERSION})..."
        fi
    else
        log_info "superfile is installed. Verifying latest version..."
    fi
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
if ! has_cmd curl || ! has_cmd tar; then
    log_error "curl and tar are required to download superfile prebuilts."
    exit 1
fi

TMP_DIR="$(mktemp -d)"
TAR_FILE="$TMP_DIR/superfile.tar.gz"

# Query GitHub API for download URL if available
RELEASE_JSON="$(curl -fsSL https://api.github.com/repos/yorukot/superfile/releases/latest 2>/dev/null || true)"
DOWNLOAD_URL=""

if [[ -n "$RELEASE_JSON" ]]; then
    DOWNLOAD_URL="$(echo "$RELEASE_JSON" | grep -E "browser_download_url.*superfile-${OS_NAME}.*${ARCH_NAME}\.tar\.gz" | head -n 1 | cut -d '"' -f 4)"
    if [[ -z "$DOWNLOAD_URL" ]]; then
        DOWNLOAD_URL="$(echo "$RELEASE_JSON" | grep -E "browser_download_url.*${ARCH_NAME}.*\.tar\.gz" | head -n 1 | cut -d '"' -f 4)"
    fi
fi

if [[ -z "$DOWNLOAD_URL" ]]; then
    DOWNLOAD_URL="https://github.com/yorukot/superfile/releases/download/v${LATEST_VERSION}/superfile-${OS_NAME}-v${LATEST_VERSION}-${ARCH_NAME}.tar.gz"
fi

log_info "Downloading superfile prebuilt package: $DOWNLOAD_URL"
if ! curl -fsSL "$DOWNLOAD_URL" -o "$TAR_FILE" 2>/dev/null; then
    DOWNLOAD_URL="https://github.com/yorukot/superfile/releases/latest/download/superfile-${OS_NAME}-v${LATEST_VERSION}-${ARCH_NAME}.tar.gz"
    if ! curl -fsSL "$DOWNLOAD_URL" -o "$TAR_FILE" 2>/dev/null; then
        DOWNLOAD_URL="https://github.com/yorukot/superfile/releases/latest/download/superfile-${OS_NAME}-${ARCH_NAME}.tar.gz"
        if ! curl -fsSL "$DOWNLOAD_URL" -o "$TAR_FILE" 2>/dev/null; then
            # Fallback to official install script
            log_warn "Direct download failed, falling back to official superfile installer script..."
            if curl -fsSL https://superfile.dev/install.sh | bash; then
                ensure_dir "$HOME/.local/bin"
                if has_cmd spf && ! has_cmd superfile; then
                    ln -sf "$(command -v spf)" "$HOME/.local/bin/superfile"
                fi
                rm -rf "$TMP_DIR"
                exit 0
            else
                rm -rf "$TMP_DIR"
                log_error "Failed to install superfile."
                exit 1
            fi
        fi
    fi
fi

# Extract archive
tar -xzf "$TAR_FILE" -C "$TMP_DIR"

# Locate the executable binary
BIN_SRC=""
if [[ -f "$TMP_DIR/spf" ]]; then
    BIN_SRC="$TMP_DIR/spf"
elif [[ -f "$TMP_DIR/superfile" ]]; then
    BIN_SRC="$TMP_DIR/superfile"
else
    BIN_SRC="$(find "$TMP_DIR" -type f \( -name "spf" -o -name "superfile" \) 2>/dev/null | head -n 1)"
fi

if [[ -z "$BIN_SRC" || ! -f "$BIN_SRC" ]]; then
    rm -rf "$TMP_DIR"
    log_error "superfile binary (spf) not found in downloaded archive."
    exit 1
fi

ensure_dir "$HOME/.local/bin"
install -m 755 "$BIN_SRC" "$HOME/.local/bin/spf"
ln -sf "$HOME/.local/bin/spf" "$HOME/.local/bin/superfile"

if [[ $EUID -eq 0 ]] || has_cmd sudo; then
    run_privileged install -m 755 "$BIN_SRC" /usr/local/bin/spf 2>/dev/null || true
    run_privileged ln -sf /usr/local/bin/spf /usr/local/bin/superfile 2>/dev/null || true
fi

rm -rf "$TMP_DIR"

# ------------------------------------------------------------------------------
# Verify installation
# ------------------------------------------------------------------------------
if [[ -d "$HOME/.local/bin" ]] && [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

if has_cmd spf || has_cmd superfile; then
    log_success "superfile installed successfully: $($(spf --version || superfile --version) 2>/dev/null | head -n 1 || echo 'spf in PATH')"
else
    log_error "superfile installation could not be verified."
    exit 1
fi
