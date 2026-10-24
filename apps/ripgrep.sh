#!/usr/bin/env bash
# ==============================================================================
# Ripgrep Installer Script
# description: Extremely fast regex-aware command-line search tool (rg)
# command: rg
# ==============================================================================
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DIR/lib/utils.sh"

if has_cmd rg; then
    log_success "Ripgrep is already installed ($(rg --version | head -n 1))"
    exit 0
fi

log_info "Installing Ripgrep..."
PKG="$(detect_pkg_manager)"

case "$PKG" in
    apt)
        run_privileged apt-get update -qq
        run_privileged apt-get install -y ripgrep
        ;;
    brew)
        brew install ripgrep
        ;;
    pacman)
        run_privileged pacman -Sy --noconfirm ripgrep
        ;;
    dnf)
        run_privileged dnf install -y ripgrep
        ;;
    apk)
        run_privileged apk add ripgrep
        ;;
    *)
        log_info "Attempting GitHub binary release download..."
        ensure_dir "$HOME/.local/bin"
        ARCH="$(uname -m)"
        case "$ARCH" in
            x86_64) RG_ARCH="x86_64-unknown-linux-musl" ;;
            aarch64|arm64) RG_ARCH="aarch64-unknown-linux-gnu" ;;
            *) log_error "Unsupported architecture: $ARCH"; exit 1 ;;
        esac
        RG_VER="14.1.0"
        TMP_DIR="$(mktemp -d)"
        curl -fsSL "https://github.com/BurntSushi/ripgrep/releases/download/${RG_VER}/ripgrep-${RG_VER}-${RG_ARCH}.tar.gz" -o "$TMP_DIR/rg.tar.gz"
        tar -xzf "$TMP_DIR/rg.tar.gz" -C "$TMP_DIR"
        cp "$TMP_DIR/ripgrep-${RG_VER}-${RG_ARCH}/rg" "$HOME/.local/bin/rg"
        chmod +x "$HOME/.local/bin/rg"
        rm -rf "$TMP_DIR"
        ;;
esac

log_success "Ripgrep installed successfully: $(rg --version 2>/dev/null | head -n 1 || echo 'rg in ~/.local/bin')"
