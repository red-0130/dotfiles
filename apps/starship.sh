#!/usr/bin/env bash
# ==============================================================================
# Starship Installer Script
# description: Minimal, blazing-fast, customizable cross-shell prompt
# command: starship
# ==============================================================================
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DIR/lib/utils.sh"

if has_cmd starship; then
    log_success "Starship is already installed ($(starship --version | head -n 1))"
    exit 0
fi

log_info "Installing Starship..."

ensure_dir "$HOME/.local/bin"

if has_cmd curl; then
    # Use official starship install script with non-interactive flags
    curl -sS https://starship.rs/install.sh | sh -s -- --bin-dir "$HOME/.local/bin" --yes
else
    PKG="$(detect_pkg_manager)"
    case "$PKG" in
        brew) brew install starship ;;
        pacman) run_privileged pacman -Sy --noconfirm starship ;;
        apk) run_privileged apk add starship ;;
        *) log_error "curl is required to install starship."; exit 1 ;;
    esac
fi

log_success "Starship installed successfully: $(starship --version 2>/dev/null | head -n 1 || echo 'starship in ~/.local/bin')"
