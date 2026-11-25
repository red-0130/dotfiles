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
            add_apt_repo \
                "https://cli.github.com/packages/githubcli-archive-keyring.gpg" \
                "/etc/apt/keyrings/githubcli-archive-keyring.gpg" \
                "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
                "/etc/apt/sources.list.d/github-cli.list"
            run_privileged apt-get install -y gh
        else
            pkg_install gh
        fi
        ;;
    dnf)
        run_privileged dnf install -y 'dnf-command(config-manager)'
        run_privileged dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
        run_privileged dnf install -y gh
        ;;
    *)
        if ! pkg_install gh pacman=github-cli apk=github-cli; then
            log_error "Unsupported package manager or failed to install gh."
            exit 1
        fi
        ;;
esac

log_success "GitHub CLI installed successfully: $(gh --version | head -n 1)"
