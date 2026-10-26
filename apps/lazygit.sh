#!/usr/bin/env bash
# ==============================================================================
# Lazygit Installer Script
# Reference: https://github.com/jesseduffield/lazygit#installation
# description: Simple terminal UI for git commands (lazygit)
# command: lazygit
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
get_latest_github_version() {
    local version=""
    if has_cmd curl; then
        version="$(curl -fsSL https://api.github.com/repos/jesseduffield/lazygit/releases/latest 2>/dev/null | grep -m 1 '"tag_name":' | sed -E 's/.*"v?([^"]+)".*/\1/' || true)"
        if [[ -z "$version" ]]; then
            version="$(curl -fsSIL "https://github.com/jesseduffield/lazygit/releases/latest" 2>/dev/null | grep -i '^location:' | sed -E 's/.*\/tag\/v?([^ \r\n]+).*/\1/' || true)"
        fi
    fi
    if [[ -z "$version" ]]; then
        version="0.66.2"
    fi
    echo "$version"
}

LATEST_VERSION="$(get_latest_github_version)"

# ------------------------------------------------------------------------------
# Check if lazygit is already installed and up to date
# ------------------------------------------------------------------------------
if has_cmd lazygit; then
    CURRENT_VERSION="$(lazygit --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n 1 || echo '')"
    if [[ -n "$CURRENT_VERSION" && -n "$LATEST_VERSION" ]]; then
        # Check if current version is at least the latest version
        if [[ "$(printf '%s\n%s' "$LATEST_VERSION" "$CURRENT_VERSION" | sort -V | head -n1)" == "$LATEST_VERSION" ]]; then
            log_success "lazygit is already at the latest version (v${CURRENT_VERSION})"
            exit 0
        else
            log_info "Current lazygit (v${CURRENT_VERSION}) is outdated. Upgrading to latest version (v${LATEST_VERSION})..."
        fi
    else
        log_info "lazygit is installed. Verifying latest version..."
    fi
fi

log_info "Installing lazygit..."

# ------------------------------------------------------------------------------
# Helper: Install latest pre-built binary from GitHub Releases
# ------------------------------------------------------------------------------
install_lazygit_binary() {
    local version="${1:-$LATEST_VERSION}"
    log_info "Downloading latest lazygit binary release (v${version}) from GitHub..."
    if ! has_cmd curl || ! has_cmd tar; then
        log_error "curl and tar are required to download lazygit binary release."
        exit 1
    fi

    local arch
    arch="$(uname -m)"
    local lazygit_arch
    case "$arch" in
        x86_64|amd64)
            lazygit_arch="x86_64"
            ;;
        aarch64|arm64)
            lazygit_arch="arm64"
            ;;
        armv6*|armv7*|armhf)
            lazygit_arch="armv6"
            ;;
        i386|i686)
            lazygit_arch="32-bit"
            ;;
        *)
            log_error "Unsupported architecture for lazygit binary release: $arch"
            exit 1
            ;;
    esac

    local os
    os="$(uname -s)"
    case "$os" in
        Linux|linux)
            os="Linux"
            ;;
        Darwin|darwin)
            os="Darwin"
            ;;
        *)
            os="Linux"
            ;;
    esac

    log_info "Installing lazygit v${version} (${os}_${lazygit_arch})..."
    ensure_dir "$HOME/.local/bin"

    local tmp_dir
    tmp_dir="$(mktemp -d)"
    local tar_url="https://github.com/jesseduffield/lazygit/releases/download/v${version}/lazygit_${version}_${os}_${lazygit_arch}.tar.gz"

    if ! curl -fsSL "$tar_url" -o "$tmp_dir/lazygit.tar.gz" 2>/dev/null; then
        # Fallback to latest download URL redirect
        tar_url="https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${version}_${os}_${lazygit_arch}.tar.gz"
        if ! curl -fsSL "$tar_url" -o "$tmp_dir/lazygit.tar.gz" 2>/dev/null; then
            rm -rf "$tmp_dir"
            log_error "Failed to download lazygit binary from: $tar_url"
            exit 1
        fi
    fi

    tar -xzf "$tmp_dir/lazygit.tar.gz" -C "$tmp_dir" lazygit
    install -m 755 "$tmp_dir/lazygit" "$HOME/.local/bin/lazygit"

    if [[ $EUID -eq 0 ]] || has_cmd sudo; then
        run_privileged install -m 755 "$tmp_dir/lazygit" /usr/local/bin/lazygit 2>/dev/null || true
    fi

    rm -rf "$tmp_dir"
}

# ------------------------------------------------------------------------------
# Install based on package manager
# Reference: https://github.com/jesseduffield/lazygit#installation
# ------------------------------------------------------------------------------
PKG="$(detect_pkg_manager)"

case "$PKG" in
    apt)
        # Debian/Ubuntu apt repositories frequently contain outdated lazygit versions.
        # Use official pre-built binary release from GitHub to guarantee the latest version.
        if has_cmd apt-get && dpkg -l lazygit 2>/dev/null | grep -q '^ii'; then
            log_info "Removing outdated lazygit package from apt..."
            run_privileged apt-get remove -y lazygit 2>/dev/null || true
        fi
        install_lazygit_binary "$LATEST_VERSION"
        ;;
    brew)
        log_info "Installing lazygit via Homebrew..."
        brew install lazygit
        ;;
    pacman)
        log_info "Installing lazygit via pacman..."
        run_privileged pacman -Sy --noconfirm lazygit
        ;;
    dnf)
        log_info "Installing lazygit via Fedora Copr (dejan/lazygit)..."
        # Official recommended repository for latest version on Fedora / RHEL
        if run_privileged dnf copr enable -y dejan/lazygit 2>/dev/null; then
            run_privileged dnf install -y lazygit
        else
            log_warn "Failed to enable Copr repository. Installing latest binary from GitHub..."
            install_lazygit_binary "$LATEST_VERSION"
        fi
        ;;
    apk)
        log_info "Installing lazygit via apk..."
        run_privileged apk add lazygit
        ;;
    zypper)
        log_info "Installing lazygit via zypper..."
        if ! run_privileged zypper install -y lazygit 2>/dev/null; then
            log_info "Adding openSUSE devel:languages:go repository..."
            if [[ -f /etc/os-release ]]; then
                # shellcheck source=/dev/null
                source /etc/os-release
                if [[ "${ID:-}" == "opensuse-tumbleweed" ]]; then
                    run_privileged zypper ar -f https://download.opensuse.org/repositories/devel:/languages:/go/openSUSE_Factory/devel:languages:go.repo 2>/dev/null || true
                elif [[ -n "${VERSION_ID:-}" ]]; then
                    run_privileged zypper ar -f "https://download.opensuse.org/repositories/devel:/languages:/go/${VERSION_ID}/devel:languages:go.repo" 2>/dev/null || true
                fi
                run_privileged zypper ref 2>/dev/null || true
            fi
            if ! run_privileged zypper install -y lazygit 2>/dev/null; then
                install_lazygit_binary "$LATEST_VERSION"
            fi
        fi
        ;;
    *)
        install_lazygit_binary "$LATEST_VERSION"
        ;;
esac

# ------------------------------------------------------------------------------
# Verify installation
# ------------------------------------------------------------------------------
if [[ -d "$HOME/.local/bin" ]] && [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

if has_cmd lazygit; then
    log_success "lazygit installed successfully: $(lazygit --version 2>/dev/null | head -n 1 || echo 'lazygit in PATH')"
else
    log_error "lazygit installation could not be verified."
    exit 1
fi
