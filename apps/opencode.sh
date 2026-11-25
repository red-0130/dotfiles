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
prepend_path "$HOME/.opencode/bin"
prepend_path "$HOME/.local/bin"
prepend_path "/usr/local/bin"

INSTALL_DIR="$HOME/.opencode/bin"
LOCAL_BIN="$HOME/.local/bin"

# ------------------------------------------------------------------------------
# Helper: Fetch latest release version from OpenCode update API or GitHub
# ------------------------------------------------------------------------------
get_latest_opencode_version() {
    local version=""
    if has_cmd curl; then
        version="$(curl -fsSL https://opencode.ai/update/api/latest/cli/npm 2>/dev/null | sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' || true)"
    elif has_cmd wget; then
        version="$(wget -qO- https://opencode.ai/update/api/latest/cli/npm 2>/dev/null | sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' || true)"
    fi
    if [[ -z "$version" ]]; then
        version="$(get_github_latest_version "anomalyco/opencode" "2.2.5")"
    fi
    echo "$version"
}

LATEST_VERSION="$(get_latest_opencode_version)"

# ------------------------------------------------------------------------------
# Check if opencode is already installed and up to date
# ------------------------------------------------------------------------------
if [[ "${OPENCODE_FORCE_INSTALL:-0}" != "1" ]] && is_cmd_up_to_date "OpenCode" "$LATEST_VERSION" --keep-if-offline opencode "$INSTALL_DIR/opencode" "$LOCAL_BIN/opencode"; then
    if [[ -x "$INSTALL_DIR/opencode" ]]; then
        ensure_dir "$LOCAL_BIN"
        ln -sf "$INSTALL_DIR/opencode" "$LOCAL_BIN/opencode"
    fi
    exit 0
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
if [[ "$INSTALLED" != "true" ]] && { has_cmd curl || has_cmd wget; }; then
    log_info "Installing via official OpenCode v2 installer script..."
    if run_remote_script bash https://opencode.ai/v2/install --no-modify-path; then
        INSTALLED=true
    else
        log_warn "Official OpenCode installer script returned non-zero, trying direct package download..."
    fi
fi

# ------------------------------------------------------------------------------
# Method 3: Direct Prebuilt Package from NPM Registry
# ------------------------------------------------------------------------------
if [[ "$INSTALLED" != "true" ]] && has_cmd tar; then
    log_info "Downloading OpenCode prebuilt binary from npm registry (target: ${TARGET})..."
    if (
        tmp_dir="$(mktemp -d)" || exit 1
        trap 'rm -rf "$tmp_dir"' EXIT
        package_name="@opencode/cli-${TARGET}"
        tar_url="https://registry.npmjs.org/${package_name}/-/cli-${TARGET}-${LATEST_VERSION}.tgz"
        download_file "$tmp_dir/opencode.tgz" "$tar_url" || exit 1
        tar -xzf "$tmp_dir/opencode.tgz" -C "$tmp_dir" 2>/dev/null || exit 1
        bin_found="$(find "$tmp_dir" -type f -name "opencode" 2>/dev/null | head -n 1)"
        [[ -n "$bin_found" && -f "$bin_found" ]] || exit 1
        install_binary "$bin_found" "opencode" "$INSTALL_DIR"
    ); then
        INSTALLED=true
    fi
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
prepend_path "$LOCAL_BIN"

if has_cmd opencode || [[ -x "$LOCAL_BIN/opencode" ]]; then
    VER_OUTPUT="$((opencode --version 2>/dev/null || "$LOCAL_BIN/opencode" --version 2>/dev/null) | head -n 1 || echo 'opencode in PATH')"
    log_success "OpenCode installed successfully: ${VER_OUTPUT}"
    exit 0
else
    log_error "OpenCode installation could not be verified."
    exit 1
fi
