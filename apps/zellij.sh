#!/usr/bin/env bash
# ==============================================================================
# Zellij Installer Script
# Reference: https://github.com/zellij-org/zellij
# description: A terminal workspace with batteries included (terminal multiplexer)
# command: zellij
# ==============================================================================
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DIR/lib/utils.sh"

# Ensure PATH includes ~/.local/bin and ~/.cargo/bin
prepend_path "$HOME/.local/bin"
prepend_path "$HOME/.cargo/bin"
if [[ -s "$HOME/.cargo/env" ]]; then
    # shellcheck source=/dev/null
    source "$HOME/.cargo/env"
fi

LATEST_VERSION="$(get_github_latest_version "zellij-org/zellij" "0.45.1")"

# ------------------------------------------------------------------------------
# Check if zellij is already installed and up to date
# ------------------------------------------------------------------------------
if is_cmd_up_to_date "zellij" "$LATEST_VERSION" zellij; then
    exit 0
fi

log_info "Installing zellij (v${LATEST_VERSION})..."

# ------------------------------------------------------------------------------
# Helper: Install prebuilt binary from GitHub releases
# ------------------------------------------------------------------------------
install_zellij_prebuilt_binary() {
    local version="$1"
    local os arch target=""
    os="$(uname -s)"
    arch="$(uname -m)"

    if [[ "$os" == "Darwin" || "$os" == "darwin" ]]; then
        case "$arch" in
            x86_64|amd64)
                target="x86_64-apple-darwin"
                ;;
            arm64|aarch64)
                target="aarch64-apple-darwin"
                ;;
            *)
                log_error "Unsupported macOS architecture for zellij: $arch"
                exit 1
                ;;
        esac
    else
        case "$arch" in
            x86_64|amd64)
                target="x86_64-unknown-linux-musl"
                ;;
            aarch64|arm64)
                target="aarch64-unknown-linux-musl"
                ;;
            armv7*|armhf)
                target="arm-unknown-linux-gnueabihf"
                ;;
            *)
                log_error "Unsupported Linux architecture for zellij: $arch"
                exit 1
                ;;
        esac
    fi

    local tar_file="zellij-${target}.tar.gz"
    if ! install_tar_binary "zellij" "zellij" \
        "https://github.com/zellij-org/zellij/releases/download/v${version}/${tar_file}" \
        "https://github.com/zellij-org/zellij/releases/download/${version}/${tar_file}" \
        "https://github.com/zellij-org/zellij/releases/latest/download/${tar_file}"; then
        log_error "Failed to download prebuilt zellij binary from GitHub."
        exit 1
    fi
}

# ------------------------------------------------------------------------------
# Installation flow:
# 1. Check first if it can be installed with cargo
# 2. Otherwise download and install latest prebuilt binary from GitHub
# ------------------------------------------------------------------------------
INSTALLED=false

if has_cmd cargo; then
    log_info "Cargo is available. Checking if zellij can be installed with cargo..."
    if cargo install --locked zellij; then
        INSTALLED=true
        log_success "zellij installed successfully via cargo."
        ensure_dir "$HOME/.local/bin"
        if [[ -f "$HOME/.cargo/bin/zellij" ]]; then
            ln -sf "$HOME/.cargo/bin/zellij" "$HOME/.local/bin/zellij"
            if [[ $EUID -eq 0 ]] || has_cmd sudo; then
                run_privileged mkdir -p /usr/local/bin
                run_privileged ln -sf "$HOME/.cargo/bin/zellij" /usr/local/bin/zellij 2>/dev/null || true
            fi
        fi
    else
        log_warn "Installation via cargo was unsuccessful or incomplete. Falling back to GitHub prebuilt binary..."
    fi
fi

if [[ "$INSTALLED" != "true" ]]; then
    log_info "Installing latest prebuilt binary from GitHub releases..."
    install_zellij_prebuilt_binary "$LATEST_VERSION"
fi

# ------------------------------------------------------------------------------
# Generate shell completions
# ------------------------------------------------------------------------------
prepend_path "$HOME/.local/bin"

if has_cmd zellij; then
    if ensure_dir "$HOME/.local/share/bash-completion/completions" 2>/dev/null; then
        zellij setup --generate-completion bash > "$HOME/.local/share/bash-completion/completions/zellij" 2>/dev/null || true
    fi
fi

# ------------------------------------------------------------------------------
# Verify installation
# ------------------------------------------------------------------------------
if has_cmd zellij; then
    log_success "zellij installed successfully: $(zellij --version 2>/dev/null || echo 'zellij in PATH')"
else
    log_error "zellij installation could not be verified."
    exit 1
fi
