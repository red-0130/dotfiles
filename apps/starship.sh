#!/usr/bin/env bash
# ==============================================================================
# Starship Installer Script
# description: Minimal, blazing-fast, customizable cross-shell prompt
# command: starship
# ==============================================================================
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DIR/lib/utils.sh"

prepend_path "$HOME/.local/bin"

if has_cmd starship; then
    log_success "Starship is already installed ($(starship --version | head -n 1))"
    exit 0
fi

log_info "Installing Starship..."

ensure_dir "$HOME/.local/bin"

if has_cmd curl || has_cmd wget; then
    # Use official starship install script with non-interactive flags
    run_remote_script sh https://starship.rs/install.sh --bin-dir "$HOME/.local/bin" --yes
elif ! pkg_install starship apt= dnf= zypper=; then
    log_error "curl is required to install starship."
    exit 1
fi

log_success "Starship installed successfully: $(starship --version 2>/dev/null | head -n 1 || echo 'starship in ~/.local/bin')"
