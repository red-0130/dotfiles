#!/usr/bin/env bash
# ==============================================================================
# uv Installer Script
# Reference: https://github.com/astral-sh/uv
# description: Extremely fast Python package and project manager, written in Rust (uv, uvx)
# command: uv
# ==============================================================================
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DIR/lib/utils.sh"

prepend_path "$HOME/.local/bin"
prepend_path "$HOME/.cargo/bin"

LATEST_VERSION="$(get_github_latest_version "astral-sh/uv" "0.6.5")"

# ------------------------------------------------------------------------------
# Check if uv is already installed and up to date
# ------------------------------------------------------------------------------
if is_cmd_up_to_date "uv" "$LATEST_VERSION" uv; then
    exit 0
fi

log_info "Installing uv (v${LATEST_VERSION})..."

# ------------------------------------------------------------------------------
# Resolve platform target triple
# ------------------------------------------------------------------------------
OS="$(uname -s)"
ARCH="$(uname -m)"
TARGET=""

if [[ "$OS" == "Darwin" || "$OS" == "darwin" ]]; then
    case "$ARCH" in
        x86_64|amd64)
            TARGET="x86_64-apple-darwin"
            ;;
        arm64|aarch64)
            TARGET="aarch64-apple-darwin"
            ;;
        *)
            log_error "Unsupported macOS architecture for uv: $ARCH"
            exit 1
            ;;
    esac
else
    # Check libc flavor (musl vs glibc)
    LIBC="gnu"
    if [[ -f /etc/alpine-release ]] || (has_cmd ldd && ldd /bin/ls 2>&1 | grep -qi "musl"); then
        LIBC="musl"
    fi

    case "$ARCH" in
        x86_64|amd64)
            TARGET="x86_64-unknown-linux-${LIBC}"
            ;;
        aarch64|arm64)
            TARGET="aarch64-unknown-linux-${LIBC}"
            ;;
        armv7*|armhf)
            TARGET="armv7-unknown-linux-${LIBC}eabihf"
            ;;
        i386|i686)
            TARGET="i686-unknown-linux-${LIBC}"
            ;;
        *)
            log_error "Unsupported Linux architecture for uv: $ARCH"
            exit 1
            ;;
    esac
fi

# ------------------------------------------------------------------------------
# Download and install prebuilt package from GitHub releases
# ------------------------------------------------------------------------------
(
    tmp_dir="$(mktemp -d)" || exit 1
    trap 'rm -rf "$tmp_dir"' EXIT
    tar_file="$tmp_dir/uv-${TARGET}.tar.gz"

    if ! download_file "$tar_file" \
        "https://github.com/astral-sh/uv/releases/download/${LATEST_VERSION}/uv-${TARGET}.tar.gz" \
        "https://github.com/astral-sh/uv/releases/download/v${LATEST_VERSION}/uv-${TARGET}.tar.gz" \
        "https://github.com/astral-sh/uv/releases/latest/download/uv-${TARGET}.tar.gz"; then
        # Fallback to official install script
        log_warn "Direct download failed, falling back to official uv installer script..."
        if ! UV_INSTALL_DIR="$HOME/.local/bin" run_remote_script sh https://astral.sh/uv/install.sh; then
            log_error "Failed to install uv prebuilt package."
            exit 1
        fi
    else
        if ! has_cmd tar; then
            log_error "tar is required to extract uv archive."
            exit 1
        fi
        tar -xzf "$tar_file" -C "$tmp_dir"

        uv_bin="$(find "$tmp_dir" -type f -name "uv" 2>/dev/null | head -n 1)"
        uvx_bin="$(find "$tmp_dir" -type f -name "uvx" 2>/dev/null | head -n 1)"

        if [[ -z "$uv_bin" || ! -f "$uv_bin" ]]; then
            log_error "uv binary not found in extracted archive."
            exit 1
        fi

        install_binary "$uv_bin" "uv"

        if [[ -n "$uvx_bin" && -f "$uvx_bin" ]]; then
            install_binary "$uvx_bin" "uvx"
        else
            ln -sf "$HOME/.local/bin/uv" "$HOME/.local/bin/uvx"
            if [[ $EUID -eq 0 ]] || has_cmd sudo; then
                run_privileged ln -sf /usr/local/bin/uv /usr/local/bin/uvx 2>/dev/null || true
            fi
        fi
    fi
)

# ------------------------------------------------------------------------------
# Generate shell completions
# ------------------------------------------------------------------------------
prepend_path "$HOME/.local/bin"

if has_cmd uv; then
    if ensure_dir "$HOME/.local/share/bash-completion/completions" 2>/dev/null; then
        uv generate-shell-completion bash > "$HOME/.local/share/bash-completion/completions/uv" 2>/dev/null || true
    fi
fi

# ------------------------------------------------------------------------------
# Verify installation
# ------------------------------------------------------------------------------
if has_cmd uv; then
    log_success "uv installed successfully: $(uv --version 2>/dev/null || echo 'uv in PATH')"
    if has_cmd uvx; then
        log_info "uvx tool runner available: $(uvx --version 2>/dev/null || echo 'uvx in PATH')"
    fi
else
    log_error "uv installation could not be verified."
    exit 1
fi
