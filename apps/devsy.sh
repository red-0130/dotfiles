#!/usr/bin/env bash
# ==============================================================================
# Devsy Desktop App Installer Script
# Reference: https://www.devsy.sh/docs/getting-started/install
# description: Standardized dev workspaces desktop app across Docker, Kubernetes, cloud, and SSH
# command: devsy-desktop
# ==============================================================================
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DIR/lib/utils.sh"

if [[ -d "$HOME/.local/bin" ]] && [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

get_latest_devsy_version() {
    local url="https://github.com/devsy-org/devsy/releases/latest"
    if has_cmd curl; then
        curl -fsSI "$url" 2>/dev/null | grep -iE '^location:.*/tag/' | sed -E 's/.*\/tag\/v?([^ \r\n]+).*/\1/' | head -n 1 || true
    fi
}

download_asset() {
    local asset="$1"
    local dest="$2"
    local base_url="https://github.com/devsy-org/devsy/releases/latest/download"
    if [[ -n "${LATEST_VERSION:-}" ]]; then
        base_url="https://github.com/devsy-org/devsy/releases/download/v${LATEST_VERSION}"
    fi
    log_info "Downloading ${asset}..."
    curl -fSL "${base_url}/${asset}" -o "$dest"
}

OS="$(detect_os)"

# ==============================================================================
# macOS — Homebrew Cask only
# ==============================================================================
if [[ "$OS" == "macos" ]]; then
    if ! has_cmd brew; then
        log_error "Homebrew is required to install Devsy Desktop on macOS."
        exit 1
    fi

    if brew list --cask devsy &>/dev/null || brew list --cask devsy-org/tap/devsy &>/dev/null; then
        log_info "Devsy Desktop is already installed via Homebrew Cask. Checking for updates..."
        brew upgrade --cask devsy-org/tap/devsy || true
    else
        log_info "Installing Devsy Desktop via Homebrew Cask..."
        brew install --cask devsy-org/tap/devsy
    fi

    if [[ -x "/Applications/Devsy.app/Contents/MacOS/Devsy" ]]; then
        ensure_dir "$HOME/.local/bin"
        ln -sf "/Applications/Devsy.app/Contents/MacOS/Devsy" "$HOME/.local/bin/devsy-desktop"
    fi

    if [[ -d "/Applications/Devsy.app" ]] || has_cmd devsy-desktop || [[ -x "$HOME/.local/bin/devsy-desktop" ]]; then
        log_success "Devsy Desktop installed successfully!"
        exit 0
    fi
    log_error "Devsy Desktop installation could not be verified."
    exit 1
fi

case "$OS" in
    alpine|arch|debian|rhel|linux) ;;
    *)
        log_error "Unsupported OS for Devsy Desktop installer: $OS"
        exit 1
        ;;
esac

# ==============================================================================
# Linux — x86_64 only
# ==============================================================================
ARCH="$(uname -m)"
if [[ "$ARCH" != "x86_64" ]]; then
    log_error "Unsupported Linux architecture for Devsy Desktop: $ARCH (x86_64 required)"
    exit 1
fi

if ! has_cmd curl; then
    log_error "curl is required to install Devsy Desktop."
    exit 1
fi

LATEST_VERSION="$(get_latest_devsy_version)"
APPIMAGE_PATH="$HOME/.local/bin/devsy-desktop"
APPIMAGE_VER_FILE="$HOME/.local/share/devsy-desktop.version"

detect_linux_method() {
    if has_cmd dpkg-query && dpkg-query -s devsy-desktop &>/dev/null; then
        echo "deb"
    elif has_cmd rpm && rpm -q devsy-desktop &>/dev/null; then
        echo "rpm"
    elif has_cmd flatpak && flatpak info sh.devsy.app &>/dev/null; then
        echo "flatpak"
    elif [[ -x "$APPIMAGE_PATH" ]]; then
        echo "appimage"
    else
        echo "none"
    fi
}

INSTALL_METHOD="$(detect_linux_method)"

check_existing_linux_version() {
    local current=""
    case "$INSTALL_METHOD" in
        deb)     current="$(dpkg-query -W -f='${Version}' devsy-desktop 2>/dev/null | sed 's/^v//' | cut -d- -f1 || true)" ;;
        rpm)     current="$(rpm -q --qf '%{VERSION}' devsy-desktop 2>/dev/null | sed 's/^v//' || true)" ;;
        flatpak) current="$(flatpak info sh.devsy.app 2>/dev/null | awk -F: '/^[[:space:]]*Version:/ {gsub(/^[ \t]+/, "", $2); print $2}' | sed 's/^v//' || true)" ;;
        appimage)
            if [[ -f "$APPIMAGE_VER_FILE" ]]; then
                current="$(tr -d '[:space:]' < "$APPIMAGE_VER_FILE" | sed 's/^v//')"
            fi
            ;;
    esac

    if [[ -n "$current" && -n "$LATEST_VERSION" ]] && version_ge "$current" "$LATEST_VERSION"; then
        log_success "Devsy Desktop is already at the latest version (v${current}, method: ${INSTALL_METHOD})"
        exit 0
    elif [[ -n "$current" && -z "$LATEST_VERSION" ]]; then
        log_success "Devsy Desktop is already installed (v${current}, method: ${INSTALL_METHOD})"
        exit 0
    elif [[ "$INSTALL_METHOD" == "appimage" && -z "$current" && -z "$LATEST_VERSION" ]]; then
        log_success "Devsy Desktop AppImage is already installed at $APPIMAGE_PATH"
        exit 0
    fi

    log_info "Updating Devsy Desktop (${INSTALL_METHOD}${current:+ v${current}} -> v${LATEST_VERSION:-latest})..."
}

if [[ "$INSTALL_METHOD" != "none" ]]; then
    check_existing_linux_version
else
    log_info "Installing Devsy Desktop..."
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

install_deb() {
    local pkg="$TMP_DIR/Devsy_linux_amd64.deb"
    download_asset "Devsy_linux_amd64.deb" "$pkg" || return 1
    run_privileged apt-get update -qq || return 1
    run_privileged apt-get install -y "$pkg" || return 1
}

install_rpm() {
    local pkg="$TMP_DIR/Devsy_linux_x86_64.rpm"
    download_asset "Devsy_linux_x86_64.rpm" "$pkg" || return 1
    if has_cmd dnf; then
        run_privileged dnf install -y "$pkg" || return 1
    elif has_cmd zypper; then
        run_privileged zypper --non-interactive install --allow-unsigned-rpm "$pkg" || return 1
    else
        return 1
    fi
}

install_flatpak() {
    local bundle="$TMP_DIR/Devsy.flatpak"
    download_asset "Devsy.flatpak" "$bundle" || return 1
    flatpak install --user -y --or-update "$bundle" || return 1
    ensure_dir "$HOME/.local/bin"
    cat > "$APPIMAGE_PATH" <<'EOF'
#!/usr/bin/env bash
exec flatpak run sh.devsy.app "$@"
EOF
    chmod +x "$APPIMAGE_PATH" || return 1
}

install_appimage() {
    local appimage="$TMP_DIR/Devsy_linux_x86_64.AppImage"
    download_asset "Devsy_linux_x86_64.AppImage" "$appimage" || return 1
    ensure_dir "$HOME/.local/bin"
    mv "$appimage" "$APPIMAGE_PATH" || return 1
    chmod +x "$APPIMAGE_PATH" || return 1

    if [[ -n "$LATEST_VERSION" ]]; then
        ensure_dir "$HOME/.local/share"
        printf '%s\n' "$LATEST_VERSION" > "$APPIMAGE_VER_FILE"
    fi

    if ensure_dir "$HOME/.local/share/applications" 2>/dev/null; then
        cat > "$HOME/.local/share/applications/sh.devsy.app.desktop" <<DESKTOP
[Desktop Entry]
Name=Devsy
Comment=Standardized dev workspaces across Docker, Kubernetes, cloud, and SSH
Exec=$APPIMAGE_PATH %U
Terminal=false
Type=Application
Icon=sh.devsy.app
Categories=Development;
StartupWMClass=sh.devsy.app
MimeType=x-scheme-handler/devsy;
DESKTOP
        if has_cmd update-desktop-database; then
            update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
        fi
    fi
}

INSTALLED=false
PKG="$(detect_pkg_manager)"

# Route updates to existing method; fresh installs prefer deb/rpm -> flatpak -> AppImage (last resort)
case "$INSTALL_METHOD" in
    deb)
        if install_deb; then INSTALLED=true; fi
        ;;
    rpm)
        if install_rpm; then INSTALLED=true; fi
        ;;
    flatpak)
        if install_flatpak; then INSTALLED=true; fi
        ;;
    appimage)
        if install_appimage; then INSTALLED=true; fi
        ;;
    none)
        if [[ "$PKG" == "apt" ]]; then
            if install_deb; then
                INSTALLED=true
            else
                log_warn "DEB installation failed; trying next available method..."
            fi
        elif [[ "$PKG" == "dnf" || "$PKG" == "zypper" ]]; then
            if install_rpm; then
                INSTALLED=true
            else
                log_warn "RPM installation failed; trying next available method..."
            fi
        fi

        if [[ "$INSTALLED" != "true" ]] && has_cmd flatpak; then
            if install_flatpak; then
                INSTALLED=true
            else
                log_warn "Flatpak installation failed; falling back to AppImage..."
            fi
        fi

        if [[ "$INSTALLED" != "true" ]]; then
            log_info "Using AppImage as last resort..."
            if install_appimage; then INSTALLED=true; fi
        fi
        ;;
esac

if [[ "$INSTALLED" == "true" ]] && (has_cmd devsy-desktop || [[ -x "$APPIMAGE_PATH" ]] || (has_cmd flatpak && flatpak info sh.devsy.app &>/dev/null)); then
    log_success "Devsy Desktop installed successfully!"
else
    log_error "Devsy Desktop installation could not be verified."
    exit 1
fi
