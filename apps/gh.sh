#!/usr/bin/env bash
# ==============================================================================
# GitHub CLI Installer Script
# description: GitHub official command-line interface tool
# command: gh
# ==============================================================================
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DIR/lib/utils.sh"

if has_cmd gh; then
    log_success "GitHub CLI is already installed ($(gh --version | head -n 1))"
    exit 0
fi

log_info "Installing GitHub CLI..."
PKG="$(detect_pkg_manager)"

case "$PKG" in
    apt)
        # Official GitHub CLI installation instructions for Debian/Ubuntu
        if has_cmd curl; then
            run_privileged mkdir -p -m 755 /etc/apt/keyrings
            curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | run_privileged dd of=/etc/apt/keyrings/githubcli-archive-keyring.gpg
            run_privileged chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | run_privileged tee /etc/apt/sources.list.d/github-cli.list > /dev/null
            run_privileged apt-get update -qq
            run_privileged apt-get install -y gh
        else
            run_privileged apt-get update -qq
            run_privileged apt-get install -y gh
        fi
        ;;
    brew)
        brew install gh
        ;;
    pacman)
        run_privileged pacman -Sy --noconfirm github-cli
        ;;
    dnf)
        run_privileged dnf install -y 'dnf-command(config-manager)'
        run_privileged dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
        run_privileged dnf install -y gh
        ;;
    apk)
        run_privileged apk add github-cli
        ;;
    *)
        log_error "Unsupported package manager for gh installation."
        exit 1
        ;;
esac

log_success "GitHub CLI installed successfully: $(gh --version | head -n 1)"
