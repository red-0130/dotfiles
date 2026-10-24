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
PKG="$(detect_pkg_manager)"

case "$PKG" in
    apt)
        run_privileged apt-get update -qq
        run_privileged apt-get install -y zsh
        ;;
    brew)
        brew install zsh
        ;;
    pacman)
        run_privileged pacman -Sy --noconfirm zsh
        ;;
    dnf)
        run_privileged dnf install -y zsh
        ;;
    apk)
        run_privileged apk add zsh
        ;;
    *)
        log_error "Unsupported package manager for zsh installation."
        exit 1
        ;;
esac

log_success "Zsh installed successfully: $(zsh --version)"
