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

if [[ -d "$HOME/.local/bin" ]] && [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$HOME/.local/bin:$PATH"
fi
if [[ -d "$HOME/.cargo/bin" ]] && [[ ":$PATH:" != *":$HOME/.cargo/bin:"* ]]; then
    export PATH="$HOME/.cargo/bin:$PATH"
fi

# ------------------------------------------------------------------------------
# Helper: Fetch latest release tag from GitHub releases
# ------------------------------------------------------------------------------
get_latest_uv_version() {
    local version=""
    if has_cmd curl; then
        version="$(curl -fsSL https://api.github.com/repos/astral-sh/uv/releases/latest 2>/dev/null | grep -m 1 '"tag_name":' | sed -E 's/.*"v?([^"]+)".*/\1/' || true)"
        if [[ -z "$version" ]]; then
            version="$(curl -fsSIL "https://github.com/astral-sh/uv/releases/latest" 2>/dev/null | grep -i '^location:' | sed -E 's/.*\/tag\/v?([^ \r\n]+).*/\1/' || true)"
        fi
    fi
    if [[ -z "$version" ]] && has_cmd wget; then
        version="$(wget -qO- https://api.github.com/repos/astral-sh/uv/releases/latest 2>/dev/null | grep -m 1 '"tag_name":' | sed -E 's/.*"v?([^"]+)".*/\1/' || true)"
    fi
    if [[ -z "$version" ]]; then
        version="0.6.5"
    fi
    echo "$version"
}

LATEST_VERSION="$(get_latest_uv_version)"

# ------------------------------------------------------------------------------
# Check if uv is already installed and up to date
# ------------------------------------------------------------------------------
if has_cmd uv; then
    CURRENT_VERSION="$(uv --version 2>/dev/null | head -n 1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n 1 || echo '')"
    if [[ -n "$CURRENT_VERSION" && -n "$LATEST_VERSION" ]]; then
        if [[ "$(printf '%s\n%s' "$LATEST_VERSION" "$CURRENT_VERSION" | sort -V | head -n1)" == "$LATEST_VERSION" ]]; then
            log_success "uv is already at the latest version (v${CURRENT_VERSION})"
            exit 0
        else
            log_info "Current uv (v${CURRENT_VERSION}) is outdated. Upgrading to latest prebuilt version (v${LATEST_VERSION})..."
        fi
    else
        log_info "uv is installed. Verifying latest version..."
    fi
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
if ! has_cmd curl && ! has_cmd wget; then
    log_error "curl or wget is required to download uv prebuilt packages."
    exit 1
fi

TMP_DIR="$(mktemp -d)"
TAR_FILE="$TMP_DIR/uv-${TARGET}.tar.gz"

DOWNLOAD_URLS=(
    "https://github.com/astral-sh/uv/releases/download/${LATEST_VERSION}/uv-${TARGET}.tar.gz"
    "https://github.com/astral-sh/uv/releases/download/v${LATEST_VERSION}/uv-${TARGET}.tar.gz"
    "https://github.com/astral-sh/uv/releases/latest/download/uv-${TARGET}.tar.gz"
)

DOWNLOAD_SUCCESS=false

for url in "${DOWNLOAD_URLS[@]}"; do
    log_info "Downloading uv prebuilt package: $url"
    if has_cmd curl && curl -fsSL "$url" -o "$TAR_FILE" 2>/dev/null; then
        DOWNLOAD_SUCCESS=true
        break
    elif has_cmd wget && wget -qO "$TAR_FILE" "$url" 2>/dev/null; then
        DOWNLOAD_SUCCESS=true
        break
    fi
done

if [[ "$DOWNLOAD_SUCCESS" != "true" || ! -s "$TAR_FILE" ]]; then
    # Fallback to official install script
    log_warn "Direct download failed, falling back to official uv installer script..."
    if has_cmd curl && curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR="$HOME/.local/bin" sh; then
        rm -rf "$TMP_DIR"
    elif has_cmd wget && wget -qO- https://astral.sh/uv/install.sh | env UV_INSTALL_DIR="$HOME/.local/bin" sh; then
        rm -rf "$TMP_DIR"
    else
        rm -rf "$TMP_DIR"
        log_error "Failed to install uv prebuilt package."
        exit 1
    fi
else
    # Extract archive
    tar -xzf "$TAR_FILE" -C "$TMP_DIR"

    # Locate uv and uvx binaries
    UV_BIN="$(find "$TMP_DIR" -type f -name "uv" 2>/dev/null | head -n 1)"
    UVX_BIN="$(find "$TMP_DIR" -type f -name "uvx" 2>/dev/null | head -n 1)"

    if [[ -z "$UV_BIN" || ! -f "$UV_BIN" ]]; then
        rm -rf "$TMP_DIR"
        log_error "uv binary not found in extracted archive."
        exit 1
    fi

    ensure_dir "$HOME/.local/bin"
    install -m 755 "$UV_BIN" "$HOME/.local/bin/uv"

    if [[ -n "$UVX_BIN" && -f "$UVX_BIN" ]]; then
        install -m 755 "$UVX_BIN" "$HOME/.local/bin/uvx"
    else
        ln -sf "$HOME/.local/bin/uv" "$HOME/.local/bin/uvx"
    fi

    if [[ $EUID -eq 0 ]] || has_cmd sudo; then
        run_privileged install -m 755 "$UV_BIN" /usr/local/bin/uv 2>/dev/null || true
        if [[ -n "$UVX_BIN" && -f "$UVX_BIN" ]]; then
            run_privileged install -m 755 "$UVX_BIN" /usr/local/bin/uvx 2>/dev/null || true
        else
            run_privileged ln -sf /usr/local/bin/uv /usr/local/bin/uvx 2>/dev/null || true
        fi
    fi

    rm -rf "$TMP_DIR"
fi

# ------------------------------------------------------------------------------
# Generate shell completions
# ------------------------------------------------------------------------------
if [[ -d "$HOME/.local/bin" ]] && [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

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
