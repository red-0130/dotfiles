#!/usr/bin/env bash
# ==============================================================================
# Neovim Installer Script
# description: Hyperextensible Vim-based text editor (nvim)
# command: nvim
# ==============================================================================
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DIR/lib/utils.sh"

if has_cmd nvim; then
    log_success "Neovim is already installed ($(nvim --version | head -n 1))"
    exit 0
fi

log_info "Installing Neovim..."
PKG="$(detect_pkg_manager)"

case "$PKG" in
    brew)
        brew install neovim
        ;;
    pacman)
        run_privileged pacman -Sy --noconfirm neovim
        ;;
    dnf)
        run_privileged dnf install -y neovim
        ;;
    apk)
        run_privileged apk add neovim
        ;;
    apt|*)
        # On Ubuntu/Debian, apt neovim is often very outdated (0.4/0.6).
        # Download modern release tarball if possible, otherwise apt.
        ARCH="$(uname -m)"
        if [[ "$ARCH" == "x86_64" ]] && has_cmd curl && has_cmd tar; then
            log_info "Downloading modern Neovim release tarball..."
            ensure_dir "$HOME/.local"
            TMP_DIR="$(mktemp -d)"
            curl -fsSL "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz" -o "$TMP_DIR/nvim.tar.gz"
            tar -C "$TMP_DIR" -xzf "$TMP_DIR/nvim.tar.gz"
            cp -r "$TMP_DIR"/nvim-linux-x86_64/* "$HOME/.local/"
            rm -rf "$TMP_DIR"
        elif [[ "$PKG" == "apt" ]]; then
            run_privileged apt-get update -qq
            run_privileged apt-get install -y neovim
        else
            log_error "Could not install Neovim on this system."
            exit 1
        fi
        ;;
esac

log_success "Neovim installed successfully: $(nvim --version 2>/dev/null | head -n 1 || echo 'nvim in ~/.local/bin')"
