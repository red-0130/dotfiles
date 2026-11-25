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

prepend_path "$HOME/.local/bin"

LATEST_VERSION="$(get_github_latest_version "jesseduffield/lazygit" "0.66.2")"

# ------------------------------------------------------------------------------
# Check if lazygit is already installed and up to date
# ------------------------------------------------------------------------------
if is_cmd_up_to_date "lazygit" "$LATEST_VERSION" lazygit; then
    exit 0
fi

log_info "Installing lazygit..."

# ------------------------------------------------------------------------------
# Helper: Install latest pre-built binary from GitHub Releases
# ------------------------------------------------------------------------------
install_lazygit_binary() {
    local version="${1:-$LATEST_VERSION}"
    log_info "Downloading latest lazygit binary release (v${version}) from GitHub..."

    local arch lazygit_arch
    arch="$(uname -m)"
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
        Linux|linux) os="Linux" ;;
        Darwin|darwin) os="Darwin" ;;
        *) os="Linux" ;;
    esac

    log_info "Installing lazygit v${version} (${os}_${lazygit_arch})..."
    local tar_name="lazygit_${version}_${os}_${lazygit_arch}.tar.gz"
    if ! install_tar_binary "lazygit" "lazygit" \
        "https://github.com/jesseduffield/lazygit/releases/download/v${version}/${tar_name}" \
        "https://github.com/jesseduffield/lazygit/releases/latest/download/${tar_name}"; then
        log_error "Failed to download lazygit binary from GitHub releases."
        exit 1
    fi
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
    brew|pacman|apk)
        log_info "Installing lazygit via ${PKG}..."
        pkg_install lazygit
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
prepend_path "$HOME/.local/bin"

if has_cmd lazygit; then
    log_success "lazygit installed successfully: $(lazygit --version 2>/dev/null | head -n 1 || echo 'lazygit in PATH')"
else
    log_error "lazygit installation could not be verified."
    exit 1
fi
