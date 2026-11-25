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
    ensure_bin_alias batcat bat
    exit 0
fi

log_info "Installing Bat..."
if ! pkg_install bat; then
    log_error "Unsupported package manager or failed to install bat."
    exit 1
fi
ensure_bin_alias batcat bat

log_success "Bat installed successfully!"
