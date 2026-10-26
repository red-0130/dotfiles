#!/usr/bin/env bash
# ==============================================================================
# Tree-sitter CLI Installer Script
# Reference: https://github.com/tree-sitter/tree-sitter
# description: Incremental parsing system and parser generator CLI (tree-sitter)
# command: tree-sitter
# ==============================================================================
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DIR/lib/utils.sh"

if [[ -d "$HOME/.local/bin" ]] && [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

# ------------------------------------------------------------------------------
# Helper: Fetch latest release tag from GitHub releases
# ------------------------------------------------------------------------------
get_latest_treesitter_version() {
    local version=""
    if has_cmd curl; then
        version="$(curl -fsSL https://api.github.com/repos/tree-sitter/tree-sitter/releases/latest 2>/dev/null | grep -m 1 '"tag_name":' | sed -E 's/.*"v?([^"]+)".*/\1/' || true)"
        if [[ -z "$version" ]]; then
            version="$(curl -fsSIL "https://github.com/tree-sitter/tree-sitter/releases/latest" 2>/dev/null | grep -i '^location:' | sed -E 's/.*\/tag\/v?([^ \r\n]+).*/\1/' || true)"
        fi
    fi
    if [[ -z "$version" ]] && has_cmd wget; then
        version="$(wget -qO- https://api.github.com/repos/tree-sitter/tree-sitter/releases/latest 2>/dev/null | grep -m 1 '"tag_name":' | sed -E 's/.*"v?([^"]+)".*/\1/' || true)"
    fi
    if [[ -z "$version" ]]; then
        version="0.25.3"
    fi
    echo "$version"
}

LATEST_VERSION="$(get_latest_treesitter_version)"

# ------------------------------------------------------------------------------
# Check if tree-sitter is already installed and up to date
# ------------------------------------------------------------------------------
if has_cmd tree-sitter || has_cmd tree-sitter-cli; then
    # Ensure both symlinks exist
    if has_cmd tree-sitter && ! has_cmd tree-sitter-cli; then
        ensure_dir "$HOME/.local/bin"
        ln -sf "$(command -v tree-sitter)" "$HOME/.local/bin/tree-sitter-cli"
    elif has_cmd tree-sitter-cli && ! has_cmd tree-sitter; then
        ensure_dir "$HOME/.local/bin"
        ln -sf "$(command -v tree-sitter-cli)" "$HOME/.local/bin/tree-sitter"
    fi

    CURRENT_VERSION="$((tree-sitter --version || tree-sitter-cli --version) 2>/dev/null | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n 1 || echo '')"
    if [[ -n "$CURRENT_VERSION" && -n "$LATEST_VERSION" ]]; then
        if [[ "$(printf '%s\n%s' "$LATEST_VERSION" "$CURRENT_VERSION" | sort -V | head -n1)" == "$LATEST_VERSION" ]]; then
            log_success "tree-sitter is already at the latest version (v${CURRENT_VERSION})"
            exit 0
        else
            log_info "Current tree-sitter (v${CURRENT_VERSION}) is outdated. Upgrading to latest version (v${LATEST_VERSION})..."
        fi
    else
        log_info "tree-sitter is installed. Verifying latest version..."
    fi
fi

log_info "Installing tree-sitter CLI (v${LATEST_VERSION})..."

# ------------------------------------------------------------------------------
# Helper: Extract zip archive across various environments
# ------------------------------------------------------------------------------
extract_zip() {
    local zip_file="$1"
    local dest_dir="$2"
    ensure_dir "$dest_dir"

    if has_cmd unzip; then
        unzip -q -o "$zip_file" -d "$dest_dir"
    elif has_cmd python3; then
        python3 -c "import zipfile, sys; zipfile.ZipFile(sys.argv[1]).extractall(sys.argv[2])" "$zip_file" "$dest_dir"
    elif has_cmd python; then
        python -c "import zipfile, sys; zipfile.ZipFile(sys.argv[1]).extractall(sys.argv[2])" "$zip_file" "$dest_dir"
    elif has_cmd busybox && busybox unzip --help &>/dev/null; then
        busybox unzip -q -o "$zip_file" -d "$dest_dir"
    elif has_cmd 7z; then
        7z x -y "-o$dest_dir" "$zip_file" >/dev/null
    else
        local pkg="$(detect_pkg_manager)"
        case "$pkg" in
            apt) run_privileged apt-get update -qq && run_privileged apt-get install -y unzip ;;
            dnf) run_privileged dnf install -y unzip ;;
            pacman) run_privileged pacman -Sy --noconfirm unzip ;;
            apk) run_privileged apk add unzip ;;
            zypper) run_privileged zypper install -y unzip ;;
            brew) brew install unzip ;;
        esac
        if has_cmd unzip; then
            unzip -q -o "$zip_file" -d "$dest_dir"
        else
            log_error "Failed to extract zip archive: unzip is required."
            return 1
        fi
    fi
}

# ------------------------------------------------------------------------------
# Resolve platform asset name
# ------------------------------------------------------------------------------
OS="$(uname -s)"
ARCH="$(uname -m)"
OS_NAME=""
ARCH_NAME=""

case "$OS" in
    Linux|linux)
        OS_NAME="linux"
        ;;
    Darwin|darwin)
        OS_NAME="macos"
        ;;
    *)
        log_error "Unsupported operating system: $OS"
        exit 1
        ;;
esac

case "$ARCH" in
    x86_64|amd64)
        ARCH_NAME="x64"
        ;;
    aarch64|arm64)
        ARCH_NAME="arm64"
        ;;
    armv7*|armhf)
        ARCH_NAME="arm"
        ;;
    i386|i686)
        ARCH_NAME="x86"
        ;;
    ppc64le|powerpc64)
        ARCH_NAME="powerpc64"
        ;;
    *)
        log_error "Unsupported architecture for tree-sitter prebuilt: $ARCH"
        exit 1
        ;;
esac

# ------------------------------------------------------------------------------
# Download and install prebuilt binary from GitHub releases
# ------------------------------------------------------------------------------
if ! has_cmd curl && ! has_cmd wget; then
    log_error "curl or wget is required to download tree-sitter binary."
    exit 1
fi

TMP_DIR="$(mktemp -d)"

# Query GitHub API for download URL
RELEASE_JSON="$(curl -fsSL https://api.github.com/repos/tree-sitter/tree-sitter/releases/latest 2>/dev/null || true)"
DOWNLOAD_URL=""

if [[ -n "$RELEASE_JSON" ]]; then
    DOWNLOAD_URL="$(echo "$RELEASE_JSON" | grep -E "browser_download_url.*tree-sitter.*${OS_NAME}.*${ARCH_NAME}\.(zip|gz)" | head -n 1 | cut -d '"' -f 4)"
fi

if [[ -z "$DOWNLOAD_URL" ]]; then
    DOWNLOAD_URL="https://github.com/tree-sitter/tree-sitter/releases/download/v${LATEST_VERSION}/tree-sitter-cli-${OS_NAME}-${ARCH_NAME}.zip"
fi

ARCHIVE_EXT="zip"
if [[ "$DOWNLOAD_URL" == *".gz" && "$DOWNLOAD_URL" != *".tar.gz" ]]; then
    ARCHIVE_EXT="gz"
fi
ARCHIVE_FILE="$TMP_DIR/tree-sitter-download.${ARCHIVE_EXT}"

log_info "Downloading tree-sitter prebuilt binary: $DOWNLOAD_URL"
DOWNLOAD_SUCCESS=false

if has_cmd curl; then
    if curl -fsSL "$DOWNLOAD_URL" -o "$ARCHIVE_FILE" 2>/dev/null; then
        DOWNLOAD_SUCCESS=true
    fi
elif has_cmd wget; then
    if wget -qO "$ARCHIVE_FILE" "$DOWNLOAD_URL" 2>/dev/null; then
        DOWNLOAD_SUCCESS=true
    fi
fi

if [[ "$DOWNLOAD_SUCCESS" != "true" ]]; then
    # Try alternative release URLs
    ALT_URLS=(
        "https://github.com/tree-sitter/tree-sitter/releases/latest/download/tree-sitter-cli-${OS_NAME}-${ARCH_NAME}.zip"
        "https://github.com/tree-sitter/tree-sitter/releases/download/v${LATEST_VERSION}/tree-sitter-${OS_NAME}-${ARCH_NAME}.gz"
        "https://github.com/tree-sitter/tree-sitter/releases/latest/download/tree-sitter-${OS_NAME}-${ARCH_NAME}.gz"
    )
    for alt in "${ALT_URLS[@]}"; do
        log_info "Trying alternative download URL: $alt"
        if has_cmd curl && curl -fsSL "$alt" -o "$ARCHIVE_FILE" 2>/dev/null; then
            if [[ "$alt" == *".gz" ]]; then ARCHIVE_EXT="gz"; else ARCHIVE_EXT="zip"; fi
            DOWNLOAD_SUCCESS=true
            break
        elif has_cmd wget && wget -qO "$ARCHIVE_FILE" "$alt" 2>/dev/null; then
            if [[ "$alt" == *".gz" ]]; then ARCHIVE_EXT="gz"; else ARCHIVE_EXT="zip"; fi
            DOWNLOAD_SUCCESS=true
            break
        fi
    done
fi

if [[ "$DOWNLOAD_SUCCESS" != "true" || ! -s "$ARCHIVE_FILE" ]]; then
    rm -rf "$TMP_DIR"
    log_error "Failed to download tree-sitter prebuilt binary."
    exit 1
fi

# Extract downloaded archive
EXTRACT_DIR="$TMP_DIR/extracted"
ensure_dir "$EXTRACT_DIR"

if [[ "$ARCHIVE_EXT" == "zip" ]]; then
    extract_zip "$ARCHIVE_FILE" "$EXTRACT_DIR"
elif [[ "$ARCHIVE_EXT" == "gz" ]]; then
    if has_cmd gzip; then
        gzip -dc "$ARCHIVE_FILE" > "$EXTRACT_DIR/tree-sitter"
    elif has_cmd gunzip; then
        gunzip -c "$ARCHIVE_FILE" > "$EXTRACT_DIR/tree-sitter"
    fi
fi

# Locate executable binary
BIN_SRC=""
if [[ -f "$EXTRACT_DIR/tree-sitter" ]]; then
    BIN_SRC="$EXTRACT_DIR/tree-sitter"
elif [[ -f "$EXTRACT_DIR/tree-sitter.exe" ]]; then
    BIN_SRC="$EXTRACT_DIR/tree-sitter.exe"
else
    BIN_SRC="$(find "$EXTRACT_DIR" -type f -name "tree-sitter*" 2>/dev/null | head -n 1)"
fi

if [[ -z "$BIN_SRC" || ! -f "$BIN_SRC" ]]; then
    rm -rf "$TMP_DIR"
    log_error "tree-sitter binary not found in extracted archive."
    exit 1
fi

chmod +x "$BIN_SRC"
ensure_dir "$HOME/.local/bin"
install -m 755 "$BIN_SRC" "$HOME/.local/bin/tree-sitter"
ln -sf "$HOME/.local/bin/tree-sitter" "$HOME/.local/bin/tree-sitter-cli"

if [[ $EUID -eq 0 ]] || has_cmd sudo; then
    run_privileged install -m 755 "$BIN_SRC" /usr/local/bin/tree-sitter 2>/dev/null || true
    run_privileged ln -sf /usr/local/bin/tree-sitter /usr/local/bin/tree-sitter-cli 2>/dev/null || true
fi

rm -rf "$TMP_DIR"

# ------------------------------------------------------------------------------
# Verify installation
# ------------------------------------------------------------------------------
if [[ -d "$HOME/.local/bin" ]] && [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

if has_cmd tree-sitter || has_cmd tree-sitter-cli; then
    log_success "tree-sitter CLI installed successfully: $((tree-sitter --version || tree-sitter-cli --version) 2>/dev/null | head -n 1 || echo 'tree-sitter in PATH')"
else
    log_error "tree-sitter installation could not be verified."
    exit 1
fi
