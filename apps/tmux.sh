#!/usr/bin/env bash
# ==============================================================================
# Tmux Installer Script
# description: Terminal multiplexer for managing windows and sessions
# command: tmux
# ==============================================================================
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DIR/lib/utils.sh"

if has_cmd tmux; then
    log_success "Tmux is already installed ($(tmux -V))"
    exit 0
fi

log_info "Installing Tmux..."
PKG="$(detect_pkg_manager)"

case "$PKG" in
    apt)
        run_privileged apt-get update -qq
        run_privileged apt-get install -y tmux
        ;;
    brew)
        brew install tmux
        ;;
    pacman)
        run_privileged pacman -Sy --noconfirm tmux
        ;;
    dnf)
        run_privileged dnf install -y tmux
        ;;
    apk)
        run_privileged apk add tmux
        ;;
    *)
        log_error "Unsupported package manager for tmux installation."
        exit 1
        ;;
esac

log_success "Tmux installed successfully: $(tmux -V)"
