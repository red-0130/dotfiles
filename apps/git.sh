#!/usr/bin/env bash
# ==============================================================================
# Git Installer Script
# description: Distributed revision control system
# command: git
# ==============================================================================
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DIR/lib/utils.sh"

if has_cmd git; then
    log_success "Git is already installed ($(git --version))"
    exit 0
fi

log_info "Installing Git..."
PKG="$(detect_pkg_manager)"

case "$PKG" in
    apt)
        run_privileged apt-get update -qq
        run_privileged apt-get install -y git
        ;;
    brew)
        brew install git
        ;;
    pacman)
        run_privileged pacman -Sy --noconfirm git
        ;;
    dnf)
        run_privileged dnf install -y git
        ;;
    apk)
        run_privileged apk add git
        ;;
    *)
        log_error "Unsupported package manager for git installation."
        exit 1
        ;;
esac

log_success "Git installed successfully: $(git --version)"
