#!/usr/bin/env bash
# ==============================================================================
# Antigravity 2.0 Desktop App Installer
# Reference: https://antigravity.google
# description: AI-first desktop application for orchestrating agents (Antigravity 2.0)
# command: antigravity
# ==============================================================================
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DIR/lib/utils.sh"

if [[ -d "$HOME/.local/bin" ]] && [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

# ------------------------------------------------------------------------------
# Detect install method (for upgrade routing)
# ------------------------------------------------------------------------------
INSTALL_DIR="/opt/antigravity"

detect_install_method() {
    # Snap: snap list will show the package if installed via snap
    if has_cmd snap && snap list antigravity &>/dev/null 2>&1; then
        echo "snap"
    # Homebrew cask (macOS)
    elif has_cmd brew && brew list --cask antigravity &>/dev/null 2>&1; then
        echo "brew"
    # Tarball: /opt/antigravity directory exists
    elif [[ -x "$INSTALL_DIR/antigravity" ]]; then
        echo "tarball"
    # Installed but method unknown (e.g. system package, manual PATH)
    elif has_cmd antigravity; then
        echo "unknown"
    else
        echo "none"
    fi
}

INSTALL_METHOD="$(detect_install_method)"

# ------------------------------------------------------------------------------
# Already installed — update via the same method
# ------------------------------------------------------------------------------
if [[ "$INSTALL_METHOD" != "none" ]]; then
    log_info "Antigravity 2.0 is already installed (method: ${INSTALL_METHOD}). Updating..."

    case "$INSTALL_METHOD" in
        snap)
            log_step "Refreshing Antigravity via Snap..."
            if run_privileged snap refresh antigravity; then
                log_success "Antigravity 2.0 updated via Snap."
            else
                log_warn "Snap refresh failed (may already be up to date)."
            fi
            exit 0
            ;;
        brew)
            log_step "Upgrading Antigravity via Homebrew Cask..."
            if brew upgrade --cask antigravity 2>/dev/null || brew reinstall --cask antigravity; then
                log_success "Antigravity 2.0 updated via Homebrew."
            else
                log_warn "Homebrew upgrade encountered an issue (may already be up to date)."
            fi
            exit 0
            ;;
        tarball)
            log_step "Re-installing Antigravity from tarball to apply update..."
            # Fall through to the tarball install path below (INSTALL_METHOD=tarball forces it)
            ;;
        unknown)
            log_warn "Antigravity is installed but the install method could not be determined."
            log_dim "  Please update it manually via https://antigravity.google/download"
            exit 0
            ;;
    esac
fi

if [[ "$INSTALL_METHOD" == "none" ]]; then
    log_info "Installing Antigravity 2.0 desktop application..."
fi

# ==============================================================================
# macOS — Homebrew Cask
# ==============================================================================
if [[ "$(detect_os)" == "macos" ]]; then
    if has_cmd brew; then
        log_info "Installing Antigravity via Homebrew Cask..."
        brew install --cask antigravity
        log_success "Antigravity 2.0 installed via Homebrew."
        exit 0
    else
        log_error "Homebrew is required to install Antigravity on macOS."
        exit 1
    fi
fi

# ==============================================================================
# Linux — architecture detection
# ==============================================================================
ARCH="$(uname -m)"
case "$ARCH" in
    x86_64)        ARCH_SLUG="x64"   ;;
    aarch64|arm64) ARCH_SLUG="arm64" ;;
    *)
        log_error "Unsupported architecture for Antigravity 2.0: $ARCH"
        exit 1
        ;;
esac

# ==============================================================================
# Linux Tier 1 — Snap (preferred; version-agnostic, auto-updating)
# Skip if we're here to update a tarball installation.
# ==============================================================================
if [[ "${AGY_PREFER_TAR:-0}" != "1" ]] && [[ "$INSTALL_METHOD" != "tarball" ]] && has_cmd snap; then
    log_info "Installing Antigravity via Snap (classic confinement)..."
    if run_privileged snap install antigravity --classic; then
        log_success "Antigravity 2.0 installed via Snap."
        log_dim "  Run: antigravity"
        exit 0
    else
        log_warn "Snap installation failed; falling back to tarball method..."
    fi
fi

# ==============================================================================
# Linux fallback — Tarball (GCS bucket, URL scraped from download page)
# ==============================================================================
if ! has_cmd curl; then
    log_error "curl is required to download Antigravity 2.0."
    exit 1
fi
if ! has_cmd tar; then
    log_error "tar is required to extract the Antigravity 2.0 archive."
    exit 1
fi

# ------------------------------------------------------------------------------
# Resolve the full arch-specific tarball download URL
# The GCS path uses a compound key: {semver}-{build}, e.g. 2.26.0-6546645232517120
#
# Strategy A: AGY_VERSION env override — construct URL from version-build slug
# Strategy B: scrape antigravity.google/download for the full arch-specific URL
# ------------------------------------------------------------------------------
GCS_BASE="https://storage.googleapis.com/antigravity-public/antigravity-hub"
AGY_DL_PAGE="https://antigravity.google/download"

resolve_download_url() {
    # Strategy A — honour manual version-build override
    # (e.g. AGY_VERSION=2.26.0-6546645232517120)
    if [[ -n "${AGY_VERSION:-}" ]]; then
        echo "${GCS_BASE}/${AGY_VERSION}/linux-${ARCH_SLUG}/Antigravity.tar.gz"
        return 0
    fi

    local url=""

    # Strategy B — scrape download page for the full arch-specific tarball URL
    url="$(curl -fsSL --proto '=https' --proto-redir '=https' --compressed \
        "$AGY_DL_PAGE" 2>/dev/null \
        | grep -Eo "https://[^\" ]+/linux-${ARCH_SLUG}/Antigravity\\.tar\\.gz" \
        | sort -u | tail -n 1 || true)"

    echo "$url"
}

DOWNLOAD_URL="$(resolve_download_url)"

if [[ -n "$DOWNLOAD_URL" ]]; then
    log_info "Resolved download URL: $DOWNLOAD_URL"
else
    log_error "Could not resolve Antigravity 2.0 download URL."
    log_dim "  Visit https://antigravity.google/download to find the current URL."
    log_dim "  Then re-run with: AGY_VERSION=2.x.y-<build> ./apps/antigravity.sh"
    exit 1
fi

TMP_DIR="$(mktemp -d)"
ARCHIVE="$TMP_DIR/antigravity.tar.gz"

log_info "Downloading Antigravity 2.0 (linux-${ARCH_SLUG})..."
if ! curl -fsSL "$DOWNLOAD_URL" -o "$ARCHIVE" 2>/dev/null; then
    rm -rf "$TMP_DIR"
    log_error "Download failed. Visit https://antigravity.google/download for the current URL."
    log_dim "  You can also set: AGY_VERSION=<version> and re-run this script."
    exit 1
fi

log_info "Extracting archive..."
tar -xzf "$ARCHIVE" -C "$TMP_DIR"

# Locate extracted dir (may be Antigravity-x64, Antigravity-linux-x64, etc.)
EXTRACTED_DIR="$(find "$TMP_DIR" -maxdepth 1 -type d -name "Antigravity*" | head -n 1)"
if [[ -z "$EXTRACTED_DIR" ]]; then
    EXTRACTED_DIR="$(find "$TMP_DIR" -maxdepth 1 -type d | grep -v "^${TMP_DIR}$" | head -n 1)"
fi
if [[ -z "$EXTRACTED_DIR" || ! -d "$EXTRACTED_DIR" ]]; then
    rm -rf "$TMP_DIR"
    log_error "Could not locate extracted Antigravity directory."
    exit 1
fi

# ------------------------------------------------------------------------------
# Install to /opt/antigravity
# ------------------------------------------------------------------------------
log_step "Installing to $INSTALL_DIR ..."

if [[ -d "$INSTALL_DIR" ]]; then
    run_privileged rm -rf "$INSTALL_DIR"
fi
run_privileged mv "$EXTRACTED_DIR" "$INSTALL_DIR"
rm -rf "$TMP_DIR"

# Electron chrome-sandbox requires setuid root for sandboxed rendering
if [[ -f "$INSTALL_DIR/chrome-sandbox" ]]; then
    log_step "Fixing chrome-sandbox permissions (setuid root)..."
    run_privileged chown root:root "$INSTALL_DIR/chrome-sandbox"
    run_privileged chmod 4755 "$INSTALL_DIR/chrome-sandbox"
fi

# System-wide symlink
run_privileged ln -sf "$INSTALL_DIR/antigravity" /usr/local/bin/antigravity

# ------------------------------------------------------------------------------
# .desktop entry
# ------------------------------------------------------------------------------
ICON_PATH="$INSTALL_DIR/resources/app/icons/png/512x512.png"
[[ -f "$ICON_PATH" ]] || ICON_PATH="antigravity"

ensure_dir "$HOME/.local/share/applications"
cat > "$HOME/.local/share/applications/antigravity.desktop" <<DESKTOP
[Desktop Entry]
Name=Antigravity
Comment=AI-first desktop application for orchestrating agents
Exec=$INSTALL_DIR/antigravity %U
Terminal=false
Type=Application
Icon=$ICON_PATH
Categories=Development;Utility;
StartupWMClass=antigravity
DESKTOP

if has_cmd update-desktop-database; then
    update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
fi

# ------------------------------------------------------------------------------
# Verify
# ------------------------------------------------------------------------------
if has_cmd antigravity || [[ -x "$INSTALL_DIR/antigravity" ]]; then
    if [[ "$INSTALL_METHOD" == "tarball" ]]; then
        log_success "Antigravity 2.0 updated successfully!"
    else
        log_success "Antigravity 2.0 installed successfully!"
    fi
    log_dim "  Binary:  $INSTALL_DIR/antigravity"
    log_dim "  Symlink: /usr/local/bin/antigravity"
    log_dim "  Desktop: $HOME/.local/share/applications/antigravity.desktop"
else
    log_error "Antigravity 2.0 installation could not be verified."
    exit 1
fi
