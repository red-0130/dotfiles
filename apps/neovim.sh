#!/usr/bin/env bash
# ==============================================================================
# Neovim Installer Script
# Reference: https://github.com/neovim/neovim/releases
# description: Hyperextensible Vim-based text editor (nvim)
# command: nvim
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
get_latest_neovim_version() {
    local version=""
    if has_cmd curl; then
        version="$(curl -fsSL https://api.github.com/repos/neovim/neovim/releases/latest 2>/dev/null | grep -m 1 '"tag_name":' | sed -E 's/.*"v?([^"]+)".*/\1/' || true)"
        if [[ -z "$version" ]]; then
            version="$(curl -fsSIL "https://github.com/neovim/neovim/releases/latest" 2>/dev/null | grep -i '^location:' | sed -E 's/.*\/tag\/v?([^ \r\n]+).*/\1/' || true)"
        fi
    fi
    if [[ -z "$version" ]]; then
        version="0.12.6"
    fi
    echo "$version"
}

LATEST_VERSION="$(get_latest_neovim_version)"

# ------------------------------------------------------------------------------
# Check if Neovim is already installed and up to date
# ------------------------------------------------------------------------------
if has_cmd nvim; then
    CURRENT_VERSION="$(nvim --version 2>/dev/null | head -n 1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n 1 || echo '')"
    if [[ -n "$CURRENT_VERSION" && -n "$LATEST_VERSION" ]]; then
        if [[ "$(printf '%s\n%s' "$LATEST_VERSION" "$CURRENT_VERSION" | sort -V | head -n1)" == "$LATEST_VERSION" ]]; then
            log_success "Neovim is already at the latest version (v${CURRENT_VERSION})"
            exit 0
        else
            log_info "Current Neovim (v${CURRENT_VERSION}) is outdated. Upgrading to latest prebuilt version (v${LATEST_VERSION})..."
        fi
    else
        log_info "Neovim is installed. Verifying latest prebuilt version..."
    fi
fi

log_info "Installing latest Neovim prebuilt package (v${LATEST_VERSION})..."

# ------------------------------------------------------------------------------
# Clean up outdated package manager installations if present
# ------------------------------------------------------------------------------
if has_cmd apt-get && dpkg -l neovim 2>/dev/null | grep -q '^ii'; then
    log_info "Removing outdated package manager version of neovim (apt)..."
    run_privileged apt-get remove -y neovim 2>/dev/null || true
fi

# ------------------------------------------------------------------------------
# Resolve platform asset name
# ------------------------------------------------------------------------------
OS="$(uname -s)"
ARCH="$(uname -m)"
ASSET_NAME=""

case "$OS" in
    Linux|linux)
        case "$ARCH" in
            x86_64|amd64)
                ASSET_NAME="nvim-linux-x86_64.tar.gz"
                ;;
            aarch64|arm64)
                ASSET_NAME="nvim-linux-arm64.tar.gz"
                ;;
            *)
                log_error "Unsupported architecture for Neovim Linux prebuilt release: $ARCH"
                exit 1
                ;;
        esac
        ;;
    Darwin|darwin)
        case "$ARCH" in
            x86_64|amd64)
                ASSET_NAME="nvim-macos-x86_64.tar.gz"
                ;;
            arm64|aarch64)
                ASSET_NAME="nvim-macos-arm64.tar.gz"
                ;;
            *)
                log_error "Unsupported architecture for Neovim macOS prebuilt release: $ARCH"
                exit 1
                ;;
        esac
        ;;
    *)
        log_error "Unsupported operating system for Neovim prebuilt release: $OS"
        exit 1
        ;;
esac

# ------------------------------------------------------------------------------
# Download and install prebuilt package
# ------------------------------------------------------------------------------
if ! has_cmd curl || ! has_cmd tar; then
    log_error "curl and tar are required to download and install Neovim prebuilts."
    exit 1
fi

TMP_DIR="$(mktemp -d)"
TAR_FILE="$TMP_DIR/$ASSET_NAME"
DOWNLOAD_URL="https://github.com/neovim/neovim/releases/download/v${LATEST_VERSION}/${ASSET_NAME}"

log_info "Downloading Neovim from GitHub: $DOWNLOAD_URL"
if ! curl -fsSL "$DOWNLOAD_URL" -o "$TAR_FILE" 2>/dev/null; then
    DOWNLOAD_URL="https://github.com/neovim/neovim/releases/latest/download/${ASSET_NAME}"
    log_info "Trying latest asset URL: $DOWNLOAD_URL"
    if ! curl -fsSL "$DOWNLOAD_URL" -o "$TAR_FILE" 2>/dev/null; then
        rm -rf "$TMP_DIR"
        log_error "Failed to download Neovim prebuilt package."
        exit 1
    fi
fi

# On macOS, clear quarantine attribute if xattr is available
if [[ "$OS" == "Darwin" || "$OS" == "darwin" ]] && has_cmd xattr; then
    xattr -c "$TAR_FILE" 2>/dev/null || true
fi

# Target installation directory
INSTALL_DIR="$HOME/.local/share/nvim-prebuilt"
rm -rf "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR"

log_info "Extracting Neovim prebuilt package..."
tar -xzf "$TAR_FILE" -C "$INSTALL_DIR" --strip-components=1

# Symlink executable to ~/.local/bin/nvim
ensure_dir "$HOME/.local/bin"
ln -sf "$INSTALL_DIR/bin/nvim" "$HOME/.local/bin/nvim"

# If root / sudo permissions are available, also configure system-wide /opt/nvim and /usr/local/bin
if [[ $EUID -eq 0 ]] || has_cmd sudo; then
    log_info "Configuring system-wide installation in /opt/nvim and /usr/local/bin/nvim..."
    run_privileged mkdir -p /opt/nvim
    run_privileged rm -rf /opt/nvim/*
    run_privileged cp -rf "$INSTALL_DIR"/* /opt/nvim/ 2>/dev/null || true
    run_privileged ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim 2>/dev/null || true
fi

# Install man pages, desktop entry, and icons if present
if [[ -d "$INSTALL_DIR/share/man" ]]; then
    ensure_dir "$HOME/.local/share/man"
    cp -rn "$INSTALL_DIR/share/man"/* "$HOME/.local/share/man/" 2>/dev/null || true
fi

if [[ -d "$INSTALL_DIR/share/applications" ]]; then
    ensure_dir "$HOME/.local/share/applications"
    cp -rn "$INSTALL_DIR/share/applications"/* "$HOME/.local/share/applications/" 2>/dev/null || true
fi

if [[ -d "$INSTALL_DIR/share/icons" ]]; then
    ensure_dir "$HOME/.local/share/icons"
    cp -rn "$INSTALL_DIR/share/icons"/* "$HOME/.local/share/icons/" 2>/dev/null || true
fi

rm -rf "$TMP_DIR"

# ------------------------------------------------------------------------------
# Verify installation
# ------------------------------------------------------------------------------
if [[ -d "$HOME/.local/bin" ]] && [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

if has_cmd nvim; then
    log_success "Neovim installed successfully: $(nvim --version 2>/dev/null | head -n 1 || echo 'nvim in PATH')"
else
    log_error "Neovim installation could not be verified."
    exit 1
fi
