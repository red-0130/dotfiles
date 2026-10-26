#!/usr/bin/env bash
# ==============================================================================
# Ghostty Terminal Installer Script
# description: Fast, feature-rich, cross-platform terminal emulator (ghostty)
# command: ghostty
# ==============================================================================
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DIR/lib/utils.sh"

if [[ -d "$HOME/.local/bin" ]] && [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

# ------------------------------------------------------------------------------
# Check if Ghostty is already installed
# ------------------------------------------------------------------------------
if has_cmd ghostty; then
    log_success "Ghostty is already installed ($(ghostty --version 2>/dev/null | head -n 1 || echo 'ghostty'))"
    exit 0
fi

log_info "Installing Ghostty terminal..."

# ------------------------------------------------------------------------------
# Helper: Check if OS is Ubuntu 26.04 or higher
# ------------------------------------------------------------------------------
is_ubuntu_2604_or_higher() {
    if [[ -f /etc/os-release ]]; then
        # shellcheck source=/dev/null
        source /etc/os-release
        if [[ "${ID:-}" == "ubuntu" && -n "${VERSION_ID:-}" ]]; then
            local min_ver="26.04"
            if [[ "$(printf '%s\n%s' "$min_ver" "$VERSION_ID" | sort -V | head -n1)" == "$min_ver" ]]; then
                return 0
            fi
        fi
    fi
    return 1
}

# ------------------------------------------------------------------------------
# Helper: Install ghostty-ubuntu community package (mkasberg/ghostty-ubuntu)
# ------------------------------------------------------------------------------
install_ghostty_ubuntu_community() {
    log_info "Installing via ghostty-ubuntu community package (mkasberg/ghostty-ubuntu)..."

    local os_id=""
    if [[ -f /etc/os-release ]]; then
        # shellcheck source=/dev/null
        source /etc/os-release
        os_id="${ID:-}"
    fi

    # 1. On Ubuntu with add-apt-repository, use the Launchpad PPA
    if [[ "$os_id" == "ubuntu" ]] && has_cmd add-apt-repository; then
        log_info "Adding community PPA: ppa:mkasberg/ghostty-ubuntu..."
        run_privileged add-apt-repository -y ppa:mkasberg/ghostty-ubuntu
        run_privileged apt-get update -qq
        run_privileged apt-get install -y ghostty
    elif has_cmd curl; then
        # 2. Try the community install script
        log_info "Running mkasberg/ghostty-ubuntu install script..."
        if /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/mkasberg/ghostty-ubuntu/HEAD/install.sh)"; then
            log_success "Ghostty installed via community install script."
        else
            # 3. Fallback: Download latest .deb directly from GitHub releases
            log_info "Downloading latest .deb package from ghostty-ubuntu releases..."
            local arch
            arch="$(dpkg --print-architecture 2>/dev/null || echo 'amd64')"
            local tmp_dir
            tmp_dir="$(mktemp -d)"
            local deb_url
            deb_url="$(curl -fsSL https://api.github.com/repos/mkasberg/ghostty-ubuntu/releases/latest 2>/dev/null | grep -E "browser_download_url.*_${arch}\.deb" | head -n 1 | cut -d '"' -f 4)"

            if [[ -n "$deb_url" ]]; then
                curl -fsSL "$deb_url" -o "$tmp_dir/ghostty.deb"
                run_privileged apt-get update -qq
                run_privileged apt-get install -y "$tmp_dir/ghostty.deb"
                rm -rf "$tmp_dir"
            else
                rm -rf "$tmp_dir"
                log_error "Could not find ghostty-ubuntu deb package for architecture: $arch"
                exit 1
            fi
        fi
    else
        log_error "curl is required to install the ghostty-ubuntu community package."
        exit 1
    fi
}

# ------------------------------------------------------------------------------
# Install based on package manager
# ------------------------------------------------------------------------------
PKG="$(detect_pkg_manager)"

case "$PKG" in
    apt)
        if is_ubuntu_2604_or_higher; then
            log_info "Detected Ubuntu 26.04 or higher. Installing Ghostty from official repositories..."
            run_privileged apt-get update -qq
            run_privileged apt-get install -y ghostty
        else
            log_info "Distro is not Ubuntu 26.04+; using ghostty-ubuntu community package..."
            install_ghostty_ubuntu_community
        fi
        ;;
    brew)
        brew install --cask ghostty 2>/dev/null || brew install ghostty
        ;;
    pacman)
        run_privileged pacman -Sy --noconfirm ghostty
        ;;
    dnf)
        # Enable COPR repository if available, then install
        if run_privileged dnf copr enable -y pgdev/ghostty 2>/dev/null; then
            run_privileged dnf install -y ghostty
        else
            run_privileged dnf install -y ghostty
        fi
        ;;
    apk)
        run_privileged apk add ghostty
        ;;
    zypper)
        run_privileged zypper install -y ghostty
        ;;
    *)
        if has_cmd flatpak; then
            log_info "Attempting Flatpak installation for Ghostty..."
            flatpak install -y flathub com.mitchellh.ghostty
        else
            log_error "Unsupported package manager for Ghostty installation."
            exit 1
        fi
        ;;
esac

if has_cmd ghostty; then
    log_success "Ghostty installed successfully: $(ghostty --version 2>/dev/null | head -n 1 || echo 'ghostty')"
else
    log_success "Ghostty installation completed."
fi
