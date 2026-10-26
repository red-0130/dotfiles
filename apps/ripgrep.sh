#!/usr/bin/env bash
# ==============================================================================
# Ripgrep Installer Script
# Reference: https://github.com/BurntSushi/ripgrep
# description: Extremely fast regex-aware command-line search tool (rg)
# command: rg
# ==============================================================================
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DIR/lib/utils.sh"

if [[ -d "$HOME/.local/bin" ]] && [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

# ------------------------------------------------------------------------------
# Helper: Fetch latest tag from GitHub releases
# ------------------------------------------------------------------------------
get_latest_ripgrep_version() {
    local version=""
    if has_cmd curl; then
        version="$(curl -fsSL https://api.github.com/repos/BurntSushi/ripgrep/releases/latest 2>/dev/null | grep -m 1 '"tag_name":' | sed -E 's/.*"v?([^"]+)".*/\1/' || true)"
        if [[ -z "$version" ]]; then
            version="$(curl -fsSIL "https://github.com/BurntSushi/ripgrep/releases/latest" 2>/dev/null | grep -i '^location:' | sed -E 's/.*\/tag\/v?([^ \r\n]+).*/\1/' || true)"
        fi
    fi
    if [[ -z "$version" ]] && has_cmd wget; then
        version="$(wget -qO- https://api.github.com/repos/BurntSushi/ripgrep/releases/latest 2>/dev/null | grep -m 1 '"tag_name":' | sed -E 's/.*"v?([^"]+)".*/\1/' || true)"
    fi
    if [[ -z "$version" ]]; then
        version="14.1.1"
    fi
    echo "$version"
}

LATEST_VERSION="$(get_latest_ripgrep_version)"

# ------------------------------------------------------------------------------
# Check if Ripgrep is already installed and up to date
# ------------------------------------------------------------------------------
if has_cmd rg; then
    CURRENT_VERSION="$(rg --version 2>/dev/null | head -n 1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n 1 || echo '')"
    if [[ -n "$CURRENT_VERSION" && -n "$LATEST_VERSION" ]]; then
        if [[ "$(printf '%s\n%s' "$LATEST_VERSION" "$CURRENT_VERSION" | sort -V | head -n1)" == "$LATEST_VERSION" ]]; then
            log_success "ripgrep is already at the latest version (v${CURRENT_VERSION})"
            exit 0
        else
            log_info "Current ripgrep (v${CURRENT_VERSION}) is outdated. Upgrading to latest version (v${LATEST_VERSION})..."
        fi
    else
        log_info "ripgrep is installed. Verifying latest version..."
    fi
fi

log_info "Installing ripgrep..."

# ------------------------------------------------------------------------------
# Helper: Install latest prebuilt binary from GitHub releases
# ------------------------------------------------------------------------------
install_ripgrep_github_binary() {
    local version="${1:-$LATEST_VERSION}"
    log_info "Downloading latest ripgrep prebuilt binary (v${version}) from GitHub..."

    if ! has_cmd curl || ! has_cmd tar; then
        log_error "curl and tar are required to download ripgrep binary."
        exit 1
    fi

    local arch="$(uname -m)"
    local os="$(uname -s)"
    local rg_arch=""

    if [[ "$os" == "Darwin" || "$os" == "darwin" ]]; then
        case "$arch" in
            x86_64|amd64) rg_arch="x86_64-apple-darwin" ;;
            arm64|aarch64) rg_arch="aarch64-apple-darwin" ;;
            *) log_error "Unsupported macOS architecture for ripgrep: $arch"; exit 1 ;;
        esac
    else
        case "$arch" in
            x86_64|amd64) rg_arch="x86_64-unknown-linux-musl" ;;
            aarch64|arm64) rg_arch="aarch64-unknown-linux-gnu" ;;
            armv7*|armhf) rg_arch="arm-unknown-linux-gnueabihf" ;;
            *) log_error "Unsupported Linux architecture for ripgrep: $arch"; exit 1 ;;
        esac
    fi

    local folder_name="ripgrep-${version}-${rg_arch}"
    local tar_file="${folder_name}.tar.gz"
    local download_url="https://github.com/BurntSushi/ripgrep/releases/download/${version}/${tar_file}"

    ensure_dir "$HOME/.local/bin"
    local tmp_dir="$(mktemp -d)"

    log_info "Downloading: $download_url"
    if ! curl -fsSL "$download_url" -o "$tmp_dir/$tar_file" 2>/dev/null; then
        download_url="https://github.com/BurntSushi/ripgrep/releases/download/v${version}/${tar_file}"
        if ! curl -fsSL "$download_url" -o "$tmp_dir/$tar_file" 2>/dev/null; then
            download_url="https://github.com/BurntSushi/ripgrep/releases/latest/download/${tar_file}"
            if ! curl -fsSL "$download_url" -o "$tmp_dir/$tar_file" 2>/dev/null; then
                rm -rf "$tmp_dir"
                log_error "Failed to download ripgrep binary archive."
                exit 1
            fi
        fi
    fi

    tar -xzf "$tmp_dir/$tar_file" -C "$tmp_dir"

    local extracted_dir
    if [[ -d "$tmp_dir/$folder_name" ]]; then
        extracted_dir="$tmp_dir/$folder_name"
    else
        extracted_dir="$(find "$tmp_dir" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
    fi

    if [[ -f "$extracted_dir/rg" ]]; then
        install -m 755 "$extracted_dir/rg" "$HOME/.local/bin/rg"
        if [[ $EUID -eq 0 ]] || has_cmd sudo; then
            run_privileged install -m 755 "$extracted_dir/rg" /usr/local/bin/rg 2>/dev/null || true
        fi
    else
        rm -rf "$tmp_dir"
        log_error "ripgrep executable not found in archive."
        exit 1
    fi

    # Install man page if present
    if [[ -f "$extracted_dir/doc/rg.1" ]]; then
        ensure_dir "$HOME/.local/share/man/man1"
        install -m 644 "$extracted_dir/doc/rg.1" "$HOME/.local/share/man/man1/rg.1" 2>/dev/null || true
        if [[ $EUID -eq 0 ]] || has_cmd sudo; then
            run_privileged mkdir -p /usr/local/share/man/man1 2>/dev/null || true
            run_privileged install -m 644 "$extracted_dir/doc/rg.1" /usr/local/share/man/man1/rg.1 2>/dev/null || true
        fi
    fi

    # Install completions if present
    if [[ -f "$extracted_dir/complete/rg.bash" ]]; then
        ensure_dir "$HOME/.local/share/bash-completion/completions"
        cp -f "$extracted_dir/complete/rg.bash" "$HOME/.local/share/bash-completion/completions/rg" 2>/dev/null || true
    fi

    rm -rf "$tmp_dir"
}

# ------------------------------------------------------------------------------
# Install based on package manager
# ------------------------------------------------------------------------------
PKG="$(detect_pkg_manager)"

case "$PKG" in
    apt)
        # On Debian/Ubuntu, apt repositories frequently package outdated versions.
        # Use official prebuilt binary release from GitHub instead.
        if has_cmd apt-get && dpkg -l ripgrep 2>/dev/null | grep -q '^ii'; then
            log_info "Removing outdated ripgrep package from apt..."
            run_privileged apt-get remove -y ripgrep 2>/dev/null || true
        fi
        install_ripgrep_github_binary "$LATEST_VERSION"
        ;;
    brew)
        brew install ripgrep
        ;;
    pacman)
        run_privileged pacman -Sy --noconfirm ripgrep
        ;;
    dnf)
        run_privileged dnf install -y ripgrep
        ;;
    apk)
        run_privileged apk add ripgrep
        ;;
    zypper)
        run_privileged zypper install -y ripgrep
        ;;
    *)
        install_ripgrep_github_binary "$LATEST_VERSION"
        ;;
esac

# ------------------------------------------------------------------------------
# Verify installation
# ------------------------------------------------------------------------------
if [[ -d "$HOME/.local/bin" ]] && [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

if has_cmd rg; then
    log_success "ripgrep installed successfully: $(rg --version 2>/dev/null | head -n 1 || echo 'rg in PATH')"
else
    log_error "ripgrep installation could not be verified."
    exit 1
fi
