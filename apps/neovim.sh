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

prepend_path "$HOME/.local/bin"

LATEST_VERSION="$(get_github_latest_version "neovim/neovim" "0.12.6")"

# ------------------------------------------------------------------------------
# Check if Neovim is already installed and up to date
# ------------------------------------------------------------------------------
if is_cmd_up_to_date "Neovim" "$LATEST_VERSION" nvim; then
    exit 0
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
if ! has_cmd tar; then
    log_error "tar is required to extract Neovim prebuilts."
    exit 1
fi

(
    TMP_DIR="$(mktemp -d)" || exit 1
    trap 'rm -rf "$TMP_DIR"' EXIT
    TAR_FILE="$TMP_DIR/$ASSET_NAME"

    log_info "Downloading Neovim from GitHub (v${LATEST_VERSION})..."
    if ! download_file "$TAR_FILE" \
        "https://github.com/neovim/neovim/releases/download/v${LATEST_VERSION}/${ASSET_NAME}" \
        "https://github.com/neovim/neovim/releases/latest/download/${ASSET_NAME}"; then
        log_error "Failed to download Neovim prebuilt package."
        exit 1
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
)

# ------------------------------------------------------------------------------
# Verify installation
# ------------------------------------------------------------------------------
prepend_path "$HOME/.local/bin"

if has_cmd nvim; then
    log_success "Neovim installed successfully: $(nvim --version 2>/dev/null | head -n 1 || echo 'nvim in PATH')"
else
    log_error "Neovim installation could not be verified."
    exit 1
fi
