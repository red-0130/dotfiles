#!/usr/bin/env bash
# ==============================================================================
# Zsh Installer Script
# description: Z shell advanced command interpreter
# command: zsh
# ==============================================================================
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DIR/lib/utils.sh"

if has_cmd zsh; then
    log_success "Zsh is already installed ($(zsh --version))"
    exit 0
fi

log_info "Installing Zsh..."
if ! pkg_install zsh; then
    log_error "Unsupported package manager or failed to install zsh."
    exit 1
fi

log_success "Zsh installed successfully: $(zsh --version)"
