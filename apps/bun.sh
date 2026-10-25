#!/usr/bin/env bash
# ==============================================================================
# Bun Installer Script
# description: Fast all-in-one JavaScript runtime & toolkit
# command: bun
# ==============================================================================
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DIR/lib/utils.sh"

# Ensure ~/.bun/bin and ~/.local/bin are in PATH for current script execution
if [[ -d "$HOME/.bun/bin" ]]; then
  export PATH="$HOME/.bun/bin:$PATH"
fi
if [[ -d "$HOME/.local/bin" ]]; then
  export PATH="$HOME/.local/bin:$PATH"
fi

# ------------------------------------------------------------------------------
# Upgrade if already installed
# ------------------------------------------------------------------------------
if has_cmd bun; then
  CURRENT_VERSION="$(bun --version 2>/dev/null || echo 'unknown')"
  log_info "Bun is already installed (v${CURRENT_VERSION}). Upgrading to latest version..."

  # Check if installed via Homebrew
  if has_cmd brew && brew list bun &>/dev/null; then
    brew upgrade bun || true
  else
    # Try native self-upgrade
    if bun upgrade 2>&1; then
      log_success "Bun upgraded successfully: v$(bun --version 2>/dev/null || echo 'latest')"
    elif run_privileged bun upgrade 2>&1; then
      log_success "Bun upgraded successfully (privileged): v$(bun --version 2>/dev/null || echo 'latest')"
    else
      log_info "Native upgrade failed, attempting update via official install script..."
      if has_cmd curl; then
        curl -fsSL https://bun.sh/install | bash
      else
        log_error "Failed to upgrade Bun and curl is not available."
        exit 1
      fi
    fi
  fi

  # Ensure ~/.local/bin/bun symlink exists if installed in ~/.bun/bin
  if [[ -x "$HOME/.bun/bin/bun" ]]; then
    ensure_dir "$HOME/.local/bin"
    ln -sf "$HOME/.bun/bin/bun" "$HOME/.local/bin/bun"
  fi

  NEW_VERSION="$(bun --version 2>/dev/null || echo "$CURRENT_VERSION")"
  log_success "Bun upgrade check complete: v${NEW_VERSION}"
  exit 0
fi

# ------------------------------------------------------------------------------
# Install Bun
# ------------------------------------------------------------------------------
log_info "Installing Bun..."
PKG="$(detect_pkg_manager)"

# Bun official installer requires unzip
if ! has_cmd unzip; then
  log_info "unzip is required for Bun installation. Installing unzip..."
  case "$PKG" in
  apt)
    run_privileged apt-get update -qq
    run_privileged apt-get install -y unzip
    ;;
  pacman)
    run_privileged pacman -Sy --noconfirm unzip
    ;;
  dnf)
    run_privileged dnf install -y unzip
    ;;
  apk)
    run_privileged apk add unzip
    ;;
  brew)
    brew install unzip
    ;;
  *)
    log_warn "Could not automatically install unzip. Bun installer may fail if unzip is missing."
    ;;
  esac
fi

if [[ "$PKG" == "brew" ]]; then
  brew install oven-sh/bun/bun || brew install bun
elif has_cmd curl; then
  curl -fsSL https://bun.sh/install | bash
else
  log_error "curl is required to install Bun."
  exit 1
fi

# Ensure newly installed Bun binary is accessible
if [[ -d "$HOME/.bun/bin" ]]; then
  export PATH="$HOME/.bun/bin:$PATH"
  if [[ -x "$HOME/.bun/bin/bun" ]]; then
    ensure_dir "$HOME/.local/bin"
    ln -sf "$HOME/.bun/bin/bun" "$HOME/.local/bin/bun"
  fi
fi

if has_cmd bun; then
  log_success "Bun installed successfully: v$(bun --version 2>/dev/null || echo 'latest')"
else
  log_success "Bun installed to $HOME/.bun/bin/bun. Please ensure ~/.bun/bin or ~/.local/bin is in your PATH."
fi
