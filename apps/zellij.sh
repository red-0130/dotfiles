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
if [[ -d "$HOME/.local/bin" ]] && [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$HOME/.local/bin:$PATH"
fi
if [[ -d "$HOME/.cargo/bin" ]] && [[ ":$PATH:" != *":$HOME/.cargo/bin:"* ]]; then
    export PATH="$HOME/.cargo/bin:$PATH"
fi
if [[ -s "$HOME/.cargo/env" ]]; then
    # shellcheck source=/dev/null
    source "$HOME/.cargo/env"
fi

# ------------------------------------------------------------------------------
# Helper: Fetch latest release tag from GitHub releases
# ------------------------------------------------------------------------------
get_latest_zellij_version() {
    local version=""
    if has_cmd curl; then
        version="$(curl -fsSL https://api.github.com/repos/zellij-org/zellij/releases/latest 2>/dev/null | grep -m 1 '"tag_name":' | sed -E 's/.*"v?([^"]+)".*/\1/' || true)"
        if [[ -z "$version" ]]; then
            version="$(curl -fsSIL "https://github.com/zellij-org/zellij/releases/latest" 2>/dev/null | grep -i '^location:' | sed -E 's/.*\/tag\/v?([^ \r\n]+).*/\1/' || true)"
        fi
    fi
    if [[ -z "$version" ]] && has_cmd wget; then
        version="$(wget -qO- https://api.github.com/repos/zellij-org/zellij/releases/latest 2>/dev/null | grep -m 1 '"tag_name":' | sed -E 's/.*"v?([^"]+)".*/\1/' || true)"
    fi
    if [[ -z "$version" ]]; then
        version="0.45.1"
    fi
    echo "$version"
}

LATEST_VERSION="$(get_latest_zellij_version)"

# ------------------------------------------------------------------------------
# Check if zellij is already installed and up to date
# ------------------------------------------------------------------------------
if has_cmd zellij; then
    CURRENT_VERSION="$(zellij --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n 1 || echo '')"
    if [[ -n "$CURRENT_VERSION" && -n "$LATEST_VERSION" ]]; then
        if [[ "$(printf '%s\n%s' "$LATEST_VERSION" "$CURRENT_VERSION" | sort -V | head -n1)" == "$LATEST_VERSION" ]]; then
            log_success "zellij is already at the latest version (v${CURRENT_VERSION})"
            exit 0
        else
            log_info "Current zellij (v${CURRENT_VERSION}) is outdated. Upgrading to latest version (v${LATEST_VERSION})..."
        fi
    else
        log_info "zellij is installed. Verifying latest version..."
    fi
fi

log_info "Installing zellij (v${LATEST_VERSION})..."

# ------------------------------------------------------------------------------
# Helper: Install prebuilt binary from GitHub releases
# ------------------------------------------------------------------------------
install_zellij_prebuilt_binary() {
    local version="$1"

    if ! has_cmd curl && ! has_cmd wget; then
        log_error "curl or wget is required to download prebuilt binary."
        exit 1
    fi
    if ! has_cmd tar; then
        log_error "tar is required to unpack zellij archive."
        exit 1
    fi

    local os="$(uname -s)"
    local arch="$(uname -m)"
    local target=""

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
    local tmp_dir="$(mktemp -d)"
    local tar_path="$tmp_dir/$tar_file"

    local download_urls=(
        "https://github.com/zellij-org/zellij/releases/download/v${version}/${tar_file}"
        "https://github.com/zellij-org/zellij/releases/download/${version}/${tar_file}"
        "https://github.com/zellij-org/zellij/releases/latest/download/${tar_file}"
    )

    local download_success=false
    for url in "${download_urls[@]}"; do
        log_info "Downloading: $url"
        if has_cmd curl && curl -fsSL "$url" -o "$tar_path" 2>/dev/null; then
            download_success=true
            break
        elif has_cmd wget && wget -qO "$tar_path" "$url" 2>/dev/null; then
            download_success=true
            break
        fi
    done

    if [[ "$download_success" != "true" || ! -s "$tar_path" ]]; then
        rm -rf "$tmp_dir"
        log_error "Failed to download prebuilt zellij binary from GitHub."
        exit 1
    fi

    tar -xzf "$tar_path" -C "$tmp_dir"

    local bin_src=""
    if [[ -f "$tmp_dir/zellij" ]]; then
        bin_src="$tmp_dir/zellij"
    else
        bin_src="$(find "$tmp_dir" -type f -name "zellij" 2>/dev/null | head -n 1)"
    fi

    if [[ -z "$bin_src" || ! -f "$bin_src" ]]; then
        rm -rf "$tmp_dir"
        log_error "zellij binary not found in extracted archive."
        exit 1
    fi

    ensure_dir "$HOME/.local/bin"
    install -m 755 "$bin_src" "$HOME/.local/bin/zellij"

    if [[ $EUID -eq 0 ]] || has_cmd sudo; then
        run_privileged install -m 755 "$bin_src" /usr/local/bin/zellij 2>/dev/null || true
    fi

    rm -rf "$tmp_dir"
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
if [[ -d "$HOME/.local/bin" ]] && [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

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
