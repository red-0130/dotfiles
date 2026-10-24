#!/usr/bin/env bash
# ==============================================================================
# Bat Installer Script
# description: Cat clone with syntax highlighting and Git integration
# command: bat
# ==============================================================================
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DIR/lib/utils.sh"

if has_cmd bat || has_cmd batcat; then
    log_success "Bat is already installed"
    # Ensure 'bat' symlink exists if installed as 'batcat' (Debian/Ubuntu)
    if ! has_cmd bat && has_cmd batcat; then
        ensure_dir "$HOME/.local/bin"
        ln -sf "$(which batcat)" "$HOME/.local/bin/bat"
    fi
    exit 0
fi

log_info "Installing Bat..."
PKG="$(detect_pkg_manager)"

case "$PKG" in
    apt)
        run_privileged apt-get update -qq
        run_privileged apt-get install -y bat
        ensure_dir "$HOME/.local/bin"
        if has_cmd batcat && ! has_cmd bat; then
            ln -sf "$(which batcat)" "$HOME/.local/bin/bat"
        fi
        ;;
    brew)
        brew install bat
        ;;
    pacman)
        run_privileged pacman -Sy --noconfirm bat
        ;;
    dnf)
        run_privileged dnf install -y bat
        ;;
    apk)
        run_privileged apk add bat
        ;;
    *)
        log_error "Unsupported package manager for bat installation."
        exit 1
        ;;
esac

log_success "Bat installed successfully!"
