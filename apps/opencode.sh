#!/usr/bin/env bash
# ==============================================================================
# OpenCode CLI Installer Script
# Reference: https://opencode.ai | https://github.com/anomalyco/opencode
# description: Open-source AI coding assistant and agent in your terminal (opencode)
# command: opencode
# ==============================================================================
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DIR/lib/utils.sh"

# Ensure target directories are included in PATH for execution
if [[ -d "$HOME/.opencode/bin" ]] && [[ ":$PATH:" != *":$HOME/.opencode/bin:"* ]]; then
    export PATH="$HOME/.opencode/bin:$PATH"
fi
if [[ -d "$HOME/.local/bin" ]] && [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$HOME/.local/bin:$PATH"
fi
if [[ -d "/usr/local/bin" ]] && [[ ":$PATH:" != *":/usr/local/bin:"* ]]; then
    export PATH="/usr/local/bin:$PATH"
fi

INSTALL_DIR="$HOME/.opencode/bin"
LOCAL_BIN="$HOME/.local/bin"

# ------------------------------------------------------------------------------
# Helper: Fetch latest release version from OpenCode update API or GitHub
# ------------------------------------------------------------------------------
get_latest_opencode_version() {
    local version=""
    if has_cmd curl; then
        version="$(curl -fsSL https://opencode.ai/update/api/latest/cli/npm 2>/dev/null | sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' || true)"
        if [[ -z "$version" ]]; then
            version="$(curl -fsSL https://api.github.com/repos/anomalyco/opencode/releases/latest 2>/dev/null | grep -m 1 '"tag_name":' | sed -E 's/.*"v?([^"]+)".*/\1/' || true)"
        fi
    fi
    if [[ -z "$version" ]] && has_cmd wget; then
        version="$(wget -qO- https://opencode.ai/update/api/latest/cli/npm 2>/dev/null | sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' || true)"
    fi
    if [[ -z "$version" ]]; then
        version="2.2.5"
    fi
    echo "$version"
}

LATEST_VERSION="$(get_latest_opencode_version)"

# ------------------------------------------------------------------------------
# Check if opencode is already installed and up to date
# ------------------------------------------------------------------------------
if has_cmd opencode || [[ -x "$INSTALL_DIR/opencode" ]] || [[ -x "$LOCAL_BIN/opencode" ]]; then
    CURRENT_VERSION="$((opencode --version 2>/dev/null || "$INSTALL_DIR/opencode" --version 2>/dev/null || "$LOCAL_BIN/opencode" --version 2>/dev/null) | head -n 1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n 1 || echo '')"
    if [[ -n "$CURRENT_VERSION" && -n "$LATEST_VERSION" && "${OPENCODE_FORCE_INSTALL:-0}" != "1" ]]; then
        if [[ "$(printf '%s\n%s' "$LATEST_VERSION" "$CURRENT_VERSION" | sort -V | head -n1)" == "$LATEST_VERSION" ]]; then
            log_success "OpenCode is already at the latest version (v${CURRENT_VERSION})"
            # Ensure local bin symlink exists
            if [[ -x "$INSTALL_DIR/opencode" ]]; then
                ensure_dir "$LOCAL_BIN"
                ln -sf "$INSTALL_DIR/opencode" "$LOCAL_BIN/opencode"
            fi
            exit 0
        else
            log_info "Current OpenCode (v${CURRENT_VERSION}) is outdated. Upgrading to latest version (v${LATEST_VERSION})..."
        fi
    elif [[ -n "$CURRENT_VERSION" && "${OPENCODE_FORCE_INSTALL:-0}" != "1" ]]; then
        log_success "OpenCode is already installed (v${CURRENT_VERSION})"
        exit 0
    fi
fi

log_info "Installing OpenCode (v${LATEST_VERSION})..."

# ------------------------------------------------------------------------------
# Resolve platform target triple
# ------------------------------------------------------------------------------
RAW_OS="$(uname -s)"
case "$RAW_OS" in
    Darwin*) OS="darwin" ;;
    Linux*) OS="linux" ;;
    *) OS="linux" ;;
esac

ARCH="$(uname -m)"
case "$ARCH" in
    x86_64|amd64) ARCH="x64" ;;
    aarch64|arm64) ARCH="arm64" ;;
    *) ARCH="x64" ;;
esac

# Rosetta translation on macOS
if [[ "$OS" == "darwin" && "$ARCH" == "x64" ]]; then
    rosetta_flag=$(sysctl -n sysctl.proc_translated 2>/dev/null || echo 0)
    if [[ "$rosetta_flag" == "1" ]]; then
        ARCH="arm64"
    fi
fi

IS_MUSL=false
if [[ "$OS" == "linux" ]]; then
    if [[ -f /etc/alpine-release ]] || (has_cmd ldd && ldd /bin/ls 2>&1 | grep -qi "musl"); then
        IS_MUSL=true
    fi
fi

NEEDS_BASELINE=false
if [[ "$ARCH" == "x64" ]]; then
    if [[ "$OS" == "linux" ]]; then
        if ! grep -qwi avx2 /proc/cpuinfo 2>/dev/null; then
            NEEDS_BASELINE=true
        fi
    elif [[ "$OS" == "darwin" ]]; then
        avx2=$(sysctl -n hw.optional.avx2_0 2>/dev/null || echo 0)
        if [[ "$avx2" != "1" ]]; then
            NEEDS_BASELINE=true
        fi
    fi
fi

TARGET="$OS-$ARCH"
if [[ "$NEEDS_BASELINE" == "true" ]]; then
    TARGET="${TARGET}-baseline"
fi
if [[ "$IS_MUSL" == "true" ]]; then
    TARGET="${TARGET}-musl"
fi

INSTALLED=false

# ------------------------------------------------------------------------------
# Method 1: macOS via Homebrew (if available)
# ------------------------------------------------------------------------------
if [[ "$OS" == "darwin" ]] && has_cmd brew; then
    log_info "Attempting installation via Homebrew..."
    if brew install anomalyco/tap/opencode-v2 2>/dev/null || brew install anomalyco/tap/opencode 2>/dev/null; then
        INSTALLED=true
    fi
fi

# ------------------------------------------------------------------------------
# Method 2: Official OpenCode v2 Bootstrapper Script
# ------------------------------------------------------------------------------
if [[ "$INSTALLED" != "true" ]] && has_cmd curl; then
    log_info "Installing via official OpenCode v2 installer script..."
    if curl -fsSL https://opencode.ai/v2/install | bash -s -- --no-modify-path; then
        INSTALLED=true
    else
        log_warn "Official OpenCode installer script returned non-zero, trying direct package download..."
    fi
fi

# ------------------------------------------------------------------------------
# Method 3: Direct Prebuilt Package from NPM Registry
# ------------------------------------------------------------------------------
if [[ "$INSTALLED" != "true" ]]; then
    log_info "Downloading OpenCode prebuilt binary from npm registry (target: ${TARGET})..."
    TMP_DIR="$(mktemp -d)"
    PACKAGE_NAME="@opencode/cli-${TARGET}"
    TAR_URL="https://registry.npmjs.org/${PACKAGE_NAME}/-/cli-${TARGET}-${LATEST_VERSION}.tgz"

    DOWNLOAD_OK=false
    if has_cmd curl && curl -fsSL "$TAR_URL" -o "$TMP_DIR/opencode.tgz" 2>/dev/null; then
        DOWNLOAD_OK=true
    elif has_cmd wget && wget -qO "$TMP_DIR/opencode.tgz" "$TAR_URL" 2>/dev/null; then
        DOWNLOAD_OK=true
    fi

    if [[ "$DOWNLOAD_OK" == "true" ]] && has_cmd tar; then
        if tar -xzf "$TMP_DIR/opencode.tgz" -C "$TMP_DIR" 2>/dev/null; then
            BIN_FOUND="$(find "$TMP_DIR" -type f -name "opencode" 2>/dev/null | head -n 1)"
            if [[ -n "$BIN_FOUND" && -f "$BIN_FOUND" ]]; then
                ensure_dir "$INSTALL_DIR"
                install -m 755 "$BIN_FOUND" "$INSTALL_DIR/opencode"
                INSTALLED=true
            fi
        fi
    fi
    rm -rf "$TMP_DIR"
fi

# ------------------------------------------------------------------------------
# Method 4: Package Manager Fallback (Bun / npm)
# ------------------------------------------------------------------------------
if [[ "$INSTALLED" != "true" ]]; then
    if has_cmd bun; then
        log_info "Attempting global install via Bun..."
        if bun install -g --trust @opencode/cli; then
            INSTALLED=true
        fi
    elif has_cmd npm; then
        log_info "Attempting global install via npm..."
        if run_privileged npm install -g @opencode/cli@latest; then
            INSTALLED=true
        fi
    fi
fi

# ------------------------------------------------------------------------------
# Symlink and Path Setup
# ------------------------------------------------------------------------------
BINARY_SRC=""
if [[ -x "$INSTALL_DIR/opencode" ]]; then
    BINARY_SRC="$INSTALL_DIR/opencode"
elif has_cmd opencode; then
    BINARY_SRC="$(command -v opencode)"
fi

if [[ -n "$BINARY_SRC" ]]; then
    ensure_dir "$LOCAL_BIN"
    ln -sf "$BINARY_SRC" "$LOCAL_BIN/opencode"
    if [[ $EUID -eq 0 ]] || has_cmd sudo; then
        run_privileged ln -sf "$BINARY_SRC" /usr/local/bin/opencode 2>/dev/null || true
    fi
fi

# ------------------------------------------------------------------------------
# Shell Completion Generation
# ------------------------------------------------------------------------------
OPENCODE_BIN="${BINARY_SRC:-$LOCAL_BIN/opencode}"
if [[ -x "$OPENCODE_BIN" ]]; then
    if ensure_dir "$HOME/.local/share/bash-completion/completions" 2>/dev/null; then
        "$OPENCODE_BIN" completion bash > "$HOME/.local/share/bash-completion/completions/opencode" 2>/dev/null || true
    fi
fi

# ------------------------------------------------------------------------------
# Install Configuration (Copy Mode)
# ------------------------------------------------------------------------------
if [[ -x "$DIR/configs/opencode/install.sh" ]]; then
    "$DIR/configs/opencode/install.sh"
elif [[ -f "$DIR/configs/opencode/opencode.json" ]]; then
    TARGET_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
    mkdir -p "$TARGET_CONFIG_DIR"
    cp -f "$DIR/configs/opencode/opencode.json" "$TARGET_CONFIG_DIR/opencode.json"
fi

# ------------------------------------------------------------------------------
# Verification
# ------------------------------------------------------------------------------
if [[ -d "$LOCAL_BIN" ]] && [[ ":$PATH:" != *":$LOCAL_BIN:"* ]]; then
    export PATH="$LOCAL_BIN:$PATH"
fi

if has_cmd opencode || [[ -x "$LOCAL_BIN/opencode" ]]; then
    VER_OUTPUT="$((opencode --version 2>/dev/null || "$LOCAL_BIN/opencode" --version 2>/dev/null) | head -n 1 || echo 'opencode in PATH')"
    log_success "OpenCode installed successfully: ${VER_OUTPUT}"
    exit 0
else
    log_error "OpenCode installation could not be verified."
    exit 1
fi
