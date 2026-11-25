#!/usr/bin/env bash
# ==============================================================================
# Helium Browser Installer Script
# Reference: https://helium.computer/download#all-downloads
# description: Privacy-respecting, modern Chromium-based web browser
# command: helium
# ==============================================================================
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DIR/lib/utils.sh"

prepend_path "$HOME/.local/bin"

# ------------------------------------------------------------------------------
# Check if Helium is already installed
# ------------------------------------------------------------------------------
if has_cmd helium || has_cmd helium-bin; then
    ensure_bin_alias helium-bin helium
    log_success "Helium browser is already installed ($((helium --version || helium-bin --version) 2>/dev/null | head -n 1 || echo 'helium'))"
    exit 0
fi

log_info "Installing Helium browser..."

# ------------------------------------------------------------------------------
# Helper: Install AppImage from GitHub releases (Universal Linux fallback)
# ------------------------------------------------------------------------------
install_helium_appimage() {
    log_info "Attempting Helium AppImage installation from GitHub releases..."
    if ! has_cmd curl; then
        log_error "curl is required to download Helium AppImage."
        exit 1
    fi

    local arch
    arch="$(uname -m)"
    local app_arch=""
    case "$arch" in
        x86_64) app_arch="x86_64" ;;
        aarch64|arm64) app_arch="arm64" ;;
        *)
            log_error "Unsupported architecture for Helium AppImage: $arch"
            exit 1
            ;;
    esac

    ensure_dir "$HOME/.local/bin"
    local appimage_url=""
    local release_json=""
    release_json="$(curl -fsSL https://api.github.com/repos/imputnet/helium-linux/releases/latest 2>/dev/null || true)"

    if [[ -n "$release_json" ]]; then
        appimage_url="$(echo "$release_json" | grep -E "browser_download_url.*${app_arch}\.AppImage" | head -n 1 | cut -d '"' -f 4)"
        if [[ -z "$appimage_url" ]]; then
            appimage_url="$(echo "$release_json" | grep -E "browser_download_url.*\.AppImage" | grep -i "$app_arch" | head -n 1 | cut -d '"' -f 4)"
        fi
    fi

    if [[ -z "$appimage_url" ]]; then
        log_dim "Querying GitHub release page for AppImage asset..."
        local rel_path
        rel_path="$(curl -fsSL https://github.com/imputnet/helium-linux/releases/latest 2>/dev/null | grep -oE '/imputnet/helium-linux/releases/download/[^"]+' | grep -E "${app_arch}\.AppImage" | head -n 1 || true)"
        if [[ -n "$rel_path" ]]; then
            appimage_url="https://github.com${rel_path}"
        fi
    fi

    if [[ -z "$appimage_url" ]]; then
        log_error "Unable to resolve Helium AppImage download URL for $app_arch."
        exit 1
    fi

    log_info "Downloading Helium AppImage: $appimage_url"
    local target_bin="$HOME/.local/bin/helium"
    download_file "$target_bin" "$appimage_url"
    chmod +x "$target_bin"

    # Set up desktop entry if user applications directory exists or can be created
    if ensure_dir "$HOME/.local/share/applications" 2>/dev/null; then
        cat <<EOF > "$HOME/.local/share/applications/helium.desktop"
[Desktop Entry]
Name=Helium
Comment=Privacy-respecting Chromium-based web browser
Exec=$HOME/.local/bin/helium %U
Terminal=false
Type=Application
Icon=helium
Categories=Network;WebBrowser;
MimeType=text/html;text/xml;application/xhtml+xml;x-scheme-handler/http;x-scheme-handler/https;
EOF
    fi
}

# ------------------------------------------------------------------------------
# Install based on package manager
# ------------------------------------------------------------------------------
PKG="$(detect_pkg_manager)"

case "$PKG" in
    apt)
        # Official Helium APT repository (https://helium.computer/download#all-downloads)
        if has_cmd curl; then
            log_info "Configuring official Helium APT repository..."
            arch="$(dpkg --print-architecture 2>/dev/null || echo 'amd64')"
            add_apt_repo \
                "https://raw.githubusercontent.com/imputnet/helium-linux/main/pubkey.asc" \
                "/etc/apt/keyrings/helium.gpg" \
                "deb [arch=${arch} signed-by=/etc/apt/keyrings/helium.gpg] https://pkg.helium.computer/deb stable main" \
                "/etc/apt/sources.list.d/helium.list" \
                "--dearmor"

            # Also link to /usr/share/keyrings if directory exists for backwards compatibility
            if [[ -d /usr/share/keyrings ]] && [[ ! -e /usr/share/keyrings/helium.gpg ]]; then
                run_privileged ln -sf /etc/apt/keyrings/helium.gpg /usr/share/keyrings/helium.gpg 2>/dev/null || true
            fi

            if ! run_privileged apt-get install -y helium-bin; then
                log_warn "APT installation failed. Falling back to AppImage..."
                install_helium_appimage
            fi
        else
            log_warn "curl is missing, unable to configure Helium APT repository. Trying AppImage..."
            install_helium_appimage
        fi
        ;;
    dnf)
        # Official Helium COPR repository (https://helium.computer/download#all-downloads)
        log_info "Configuring Helium COPR repository..."
        if run_privileged dnf copr enable -y imput/helium; then
            run_privileged dnf install -y helium-bin
        else
            log_warn "Failed to enable COPR repository. Falling back to AppImage..."
            install_helium_appimage
        fi
        ;;
    pacman)
        # Arch User Repository (AUR)
        if has_cmd yay; then
            log_info "Installing Helium via yay (AUR)..."
            yay -S --noconfirm helium-browser-bin 2>/dev/null || yay -S --noconfirm helium-bin
        elif has_cmd paru; then
            log_info "Installing Helium via paru (AUR)..."
            paru -S --noconfirm helium-browser-bin 2>/dev/null || paru -S --noconfirm helium-bin
        else
            log_info "No AUR helper found on Arch Linux. Installing via AppImage..."
            install_helium_appimage
        fi
        ;;
    brew)
        log_info "Installing Helium on macOS..."
        if has_cmd curl; then
            mac_json="$(curl -fsSL https://api.github.com/repos/imputnet/helium-macos/releases/latest 2>/dev/null || true)"
            dmg_url="$(echo "$mac_json" | grep -E "browser_download_url.*\.dmg" | head -n 1 | cut -d '"' -f 4)"
            if [[ -n "$dmg_url" ]]; then
                (
                    tmp_dir="$(mktemp -d)"
                    trap 'rm -rf "$tmp_dir"' EXIT
                    tmp_dmg="$tmp_dir/helium.dmg"
                    download_file "$tmp_dmg" "$dmg_url"
                    hdiutil attach "$tmp_dmg" -nobrowse -quiet
                    cp -R /Volumes/*[Hh]elium*/*.app /Applications/ 2>/dev/null || true
                    hdiutil detach /Volumes/*[Hh]elium* -quiet 2>/dev/null || true
                )
                ensure_dir "$HOME/.local/bin"
                ln -sf "/Applications/Helium.app/Contents/MacOS/Helium" "$HOME/.local/bin/helium" 2>/dev/null || true
            else
                brew install --cask helium 2>/dev/null || true
            fi
        else
            brew install --cask helium 2>/dev/null || true
        fi
        ;;
    *)
        log_info "Universal installation using AppImage..."
        install_helium_appimage
        ;;
esac

# ------------------------------------------------------------------------------
# Verify and symlink
# ------------------------------------------------------------------------------
ensure_bin_alias helium-bin helium

if has_cmd helium || has_cmd helium-bin; then
    log_success "Helium browser installed successfully: $((helium --version || helium-bin --version) 2>/dev/null | head -n 1 || echo 'helium')"
else
    log_warn "Helium installation completed, but binary was not found in PATH."
fi
