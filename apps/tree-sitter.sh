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

prepend_path "$HOME/.local/bin"

LATEST_VERSION="$(get_github_latest_version "tree-sitter/tree-sitter" "0.25.3")"

# ------------------------------------------------------------------------------
# Check if tree-sitter is already installed and up to date
# ------------------------------------------------------------------------------
ensure_bin_alias tree-sitter tree-sitter-cli
ensure_bin_alias tree-sitter-cli tree-sitter
if is_cmd_up_to_date "tree-sitter" "$LATEST_VERSION" tree-sitter tree-sitter-cli; then
    exit 0
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
        pkg_install unzip || true
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
(
    tmp_dir="$(mktemp -d)" || exit 1
    trap 'rm -rf "$tmp_dir"' EXIT

    # Query GitHub API for download URL
    release_json=""
    if has_cmd curl; then
        release_json="$(curl -fsSL https://api.github.com/repos/tree-sitter/tree-sitter/releases/latest 2>/dev/null || true)"
    fi
    download_url=""
    if [[ -n "$release_json" ]]; then
        download_url="$(echo "$release_json" | grep -E "browser_download_url.*tree-sitter.*${OS_NAME}.*${ARCH_NAME}\.(zip|gz)" | head -n 1 | cut -d '"' -f 4)"
    fi

    zip_urls=(
        "https://github.com/tree-sitter/tree-sitter/releases/download/v${LATEST_VERSION}/tree-sitter-cli-${OS_NAME}-${ARCH_NAME}.zip"
        "https://github.com/tree-sitter/tree-sitter/releases/latest/download/tree-sitter-cli-${OS_NAME}-${ARCH_NAME}.zip"
    )
    gz_urls=(
        "https://github.com/tree-sitter/tree-sitter/releases/download/v${LATEST_VERSION}/tree-sitter-${OS_NAME}-${ARCH_NAME}.gz"
        "https://github.com/tree-sitter/tree-sitter/releases/latest/download/tree-sitter-${OS_NAME}-${ARCH_NAME}.gz"
    )

    archive_ext=""
    archive_file=""
    if [[ -n "$download_url" && "$download_url" == *".gz" && "$download_url" != *".tar.gz" ]] && download_file "$tmp_dir/tree-sitter.gz" "$download_url"; then
        archive_ext="gz"
        archive_file="$tmp_dir/tree-sitter.gz"
    else
        [[ -n "$download_url" && "$download_url" != *".gz" ]] && zip_urls=("$download_url" "${zip_urls[@]}")
        if download_file "$tmp_dir/tree-sitter.zip" "${zip_urls[@]}"; then
            archive_ext="zip"
            archive_file="$tmp_dir/tree-sitter.zip"
        elif download_file "$tmp_dir/tree-sitter.gz" "${gz_urls[@]}"; then
            archive_ext="gz"
            archive_file="$tmp_dir/tree-sitter.gz"
        else
            log_error "Failed to download tree-sitter prebuilt binary."
            exit 1
        fi
    fi

    # Extract downloaded archive
    extract_dir="$tmp_dir/extracted"
    ensure_dir "$extract_dir"

    if [[ "$archive_ext" == "zip" ]]; then
        extract_zip "$archive_file" "$extract_dir"
    elif [[ "$archive_ext" == "gz" ]]; then
        if has_cmd gzip; then
            gzip -dc "$archive_file" > "$extract_dir/tree-sitter"
        elif has_cmd gunzip; then
            gunzip -c "$archive_file" > "$extract_dir/tree-sitter"
        else
            log_error "gzip is required to extract .gz archive."
            exit 1
        fi
    fi

    # Locate executable binary
    bin_src=""
    if [[ -f "$extract_dir/tree-sitter" ]]; then
        bin_src="$extract_dir/tree-sitter"
    elif [[ -f "$extract_dir/tree-sitter.exe" ]]; then
        bin_src="$extract_dir/tree-sitter.exe"
    else
        bin_src="$(find "$extract_dir" -type f -name "tree-sitter*" 2>/dev/null | head -n 1)"
    fi

    if [[ -z "$bin_src" || ! -f "$bin_src" ]]; then
        log_error "tree-sitter binary not found in extracted archive."
        exit 1
    fi

    install_binary "$bin_src" "tree-sitter"
    ln -sf "$HOME/.local/bin/tree-sitter" "$HOME/.local/bin/tree-sitter-cli"

    if [[ $EUID -eq 0 ]] || has_cmd sudo; then
        run_privileged ln -sf /usr/local/bin/tree-sitter /usr/local/bin/tree-sitter-cli 2>/dev/null || true
    fi
)

# ------------------------------------------------------------------------------
# Verify installation
# ------------------------------------------------------------------------------
prepend_path "$HOME/.local/bin"

if has_cmd tree-sitter || has_cmd tree-sitter-cli; then
    log_success "tree-sitter CLI installed successfully: $((tree-sitter --version || tree-sitter-cli --version) 2>/dev/null | head -n 1 || echo 'tree-sitter in PATH')"
else
    log_error "tree-sitter installation could not be verified."
    exit 1
fi
