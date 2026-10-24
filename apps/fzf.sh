#!/usr/bin/env bash
# ==============================================================================
# FZF Installer Script
# description: Command-line fuzzy finder with interactive shell integration
# command: fzf
# ==============================================================================
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DIR/lib/utils.sh"

if has_cmd fzf; then
    log_success "FZF is already installed ($(fzf --version | head -n 1))"
    exit 0
fi

log_info "Installing FZF..."

# Prefer git clone to ~/.fzf if git is available, otherwise package manager
if has_cmd git; then
    if [[ ! -d "$HOME/.fzf" ]]; then
        git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
    else
        (cd "$HOME/.fzf" && git pull --depth 1)
    fi
    "$HOME/.fzf/install" --bin --no-update-rc --no-bash --no-zsh --no-fish
    ensure_dir "$HOME/.local/bin"
    ln -sf "$HOME/.fzf/bin/fzf" "$HOME/.local/bin/fzf"
else
    PKG="$(detect_pkg_manager)"
    case "$PKG" in
        apt)
            run_privileged apt-get update -qq
            run_privileged apt-get install -y fzf
            ;;
        brew)
            brew install fzf
            ;;
        pacman)
            run_privileged pacman -Sy --noconfirm fzf
            ;;
        dnf)
            run_privileged dnf install -y fzf
            ;;
        apk)
            run_privileged apk add fzf
            ;;
        *)
            log_error "Cannot install fzf: neither git nor supported package manager found."
            exit 1
            ;;
    esac
fi

log_success "FZF installed successfully: $(fzf --version 2>/dev/null | head -n 1 || echo 'fzf in ~/.fzf/bin')"
