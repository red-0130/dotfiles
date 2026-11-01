#!/usr/bin/env bash
# ==============================================================================
# Google Antigravity CLI Installer Script
# Reference: https://antigravity.google
# description: Google Antigravity CLI (agy) - AI-first agentic coding assistant
# command: agy
# ==============================================================================
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DIR/lib/utils.sh"

if [[ -d "$HOME/.local/bin" ]] && [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
  export PATH="$HOME/.local/bin:$PATH"
fi
if [[ -d "/usr/local/bin" ]] && [[ ":$PATH:" != *":/usr/local/bin:"* ]]; then
  export PATH="/usr/local/bin:$PATH"
fi

TARGET_DIR="${AGY_INSTALL_DIR:-$HOME/.local/bin}"
BINARY_PATH="$TARGET_DIR/agy"
DOWNLOAD_BASE_URL="https://antigravity-cli-auto-updater-974169037036.us-central1.run.app"
OFFICIAL_BOOTSTRAPPER_URL="https://antigravity.google/cli/install.sh"

# ------------------------------------------------------------------------------
# Platform Detection
# ------------------------------------------------------------------------------
detect_platform() {
  local os arch platform
  case "$(uname -s)" in
  Darwin) os="darwin" ;;
  Linux)
    if [[ "$(uname -o 2>/dev/null)" == "Android" ]]; then
      os="android"
    else
      os="linux"
    fi
    ;;
  *)
    log_error "Unsupported operating system: $(uname -s)"
    return 1
    ;;
  esac

  case "$(uname -m)" in
  x86_64 | amd64) arch="amd64" ;;
  arm64 | aarch64) arch="arm64" ;;
  *)
    log_error "Unsupported architecture: $(uname -m)"
    return 1
    ;;
  esac

  if [[ "$os" == "linux" ]]; then
    if [[ -f /lib/libc.musl-x86_64.so.1 ]] || [[ -f /lib/libc.musl-aarch64.so.1 ]] || (has_cmd ldd && ldd /bin/ls 2>&1 | grep -q musl); then
      platform="linux_${arch}_musl"
    else
      platform="linux_${arch}"
    fi
  else
    platform="${os}_${arch}"
  fi

  echo "$platform"
}

# ------------------------------------------------------------------------------
# Release Manifest Query Helpers
# ------------------------------------------------------------------------------
fetch_latest_manifest() {
  local platform="$1"
  local manifest_url="$DOWNLOAD_BASE_URL/manifests/${platform}.json"
  if has_cmd curl; then
    curl -fsSL "$manifest_url" 2>/dev/null || true
  elif has_cmd wget; then
    wget -q -O - "$manifest_url" 2>/dev/null || true
  fi
}

parse_json_value() {
  local json="$1"
  local key="$2"
  echo "$json" | sed -n 's/.*"'"$key"'"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p'
}

# ------------------------------------------------------------------------------
# Pre-existence & Version Check
# ------------------------------------------------------------------------------
PLATFORM="$(detect_platform || true)"
LATEST_VERSION=""
MANIFEST_JSON=""

if [[ -n "$PLATFORM" ]]; then
  MANIFEST_JSON="$(fetch_latest_manifest "$PLATFORM")"
  if [[ -n "$MANIFEST_JSON" ]]; then
    LATEST_VERSION="$(parse_json_value "$MANIFEST_JSON" "version")"
  fi
fi

if has_cmd agy || [[ -x "$BINARY_PATH" ]]; then
  CURRENT_VERSION="$($(agy --version 2>/dev/null || "$BINARY_PATH" --version 2>/dev/null) | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n 1 || echo '')"
  if [[ -n "$CURRENT_VERSION" && -n "$LATEST_VERSION" && "${AGY_FORCE_INSTALL:-0}" != "1" ]]; then
    if [[ "$(printf '%s\n%s' "$LATEST_VERSION" "$CURRENT_VERSION" | sort -V | head -n1)" == "$LATEST_VERSION" ]]; then
      log_success "Antigravity CLI (agy) is already up to date (v${CURRENT_VERSION})"
      exit 0
    else
      log_info "Antigravity CLI (v${CURRENT_VERSION}) is outdated. Upgrading to latest version (v${LATEST_VERSION})..."
    fi
  elif [[ -n "$CURRENT_VERSION" && "${AGY_FORCE_INSTALL:-0}" != "1" ]]; then
    log_success "Antigravity CLI (agy) is already installed (v${CURRENT_VERSION})"
    exit 0
  fi
fi

log_info "Installing Google Antigravity CLI (agy)..."

# ------------------------------------------------------------------------------
# Installation Method 1: macOS via Homebrew (if available)
# ------------------------------------------------------------------------------
installed_via_brew=false
if [[ "$(detect_os)" == "macos" ]] && has_cmd brew; then
  log_info "Attempting installation via Homebrew..."
  if brew list antigravity-cli &>/dev/null 2>&1; then
    if brew upgrade antigravity-cli 2>/dev/null; then
      installed_via_brew=true
    fi
  else
    if brew install antigravity-cli 2>/dev/null; then
      installed_via_brew=true
    fi
  fi
fi

# ------------------------------------------------------------------------------
# Installation Method 2: Official Unix Bootstrapper Script
# ------------------------------------------------------------------------------
install_via_bootstrapper() {
  log_info "Downloading and running official Antigravity CLI installer..."
  ensure_dir "$TARGET_DIR"

  # The official bootstrapper skips if BINARY_PATH already exists.
  # When upgrading or forcing install, move existing binary temporarily.
  local backup_bin=""
  if [[ -f "$BINARY_PATH" ]]; then
    backup_bin="$(mktemp "${BINARY_PATH}.tmp.XXXXXX")"
    mv "$BINARY_PATH" "$backup_bin"
  fi

  local install_cmd
  if has_cmd curl; then
    install_cmd="curl -fsSL \"$OFFICIAL_BOOTSTRAPPER_URL\" | bash -s -- --dir \"$TARGET_DIR\""
  elif has_cmd wget; then
    install_cmd="wget -qO- \"$OFFICIAL_BOOTSTRAPPER_URL\" | bash -s -- --dir \"$TARGET_DIR\""
  else
    log_error "Neither curl nor wget is available."
    [[ -n "$backup_bin" && -f "$backup_bin" ]] && mv "$backup_bin" "$BINARY_PATH"
    return 1
  fi

  if eval "$install_cmd"; then
    [[ -n "$backup_bin" && -f "$backup_bin" ]] && rm -f "$backup_bin"
    return 0
  else
    log_warn "Official bootstrapper failed. Falling back to direct download..."
    [[ -n "$backup_bin" && -f "$backup_bin" ]] && mv "$backup_bin" "$BINARY_PATH"
    return 1
  fi
}

# ------------------------------------------------------------------------------
# Installation Method 3: Direct Manifest-Guided Download Fallback
# ------------------------------------------------------------------------------
install_via_direct_download() {
  if [[ -z "$MANIFEST_JSON" && -n "$PLATFORM" ]]; then
    MANIFEST_JSON="$(fetch_latest_manifest "$PLATFORM")"
  fi

  if [[ -z "$MANIFEST_JSON" ]]; then
    log_error "Unable to retrieve release manifest for platform: $PLATFORM"
    return 1
  fi

  local dl_url dl_sha
  dl_url="$(parse_json_value "$MANIFEST_JSON" "url")"
  dl_sha="$(parse_json_value "$MANIFEST_JSON" "sha512")"

  if [[ -z "$dl_url" || -z "$dl_sha" ]]; then
    log_error "Failed to parse release manifest payload."
    return 1
  fi

  log_info "Downloading Antigravity CLI release package directly..."
  local tmp_dir
  tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/agy_install.XXXXXX")"
  # Ensure cleanup on function exit
  trap 'rm -rf "$tmp_dir"' RETURN

  local archive_file="$tmp_dir/agy_payload"
  if has_cmd curl; then
    curl -fsSL -o "$archive_file" "$dl_url"
  elif has_cmd wget; then
    wget -q -O "$archive_file" "$dl_url"
  else
    log_error "curl or wget is required for direct download."
    return 1
  fi

  # Verify SHA-512 Checksum
  local actual_sha=""
  if has_cmd sha512sum; then
    actual_sha="$(sha512sum "$archive_file" | cut -d' ' -f1)"
  elif has_cmd shasum; then
    actual_sha="$(shasum -a 512 "$archive_file" | cut -d' ' -f1)"
  fi

  if [[ -n "$actual_sha" && "$actual_sha" != "$dl_sha" ]]; then
    log_error "SHA-512 checksum mismatch! Expected: $dl_sha, Got: $actual_sha"
    return 1
  fi

  ensure_dir "$TARGET_DIR"

  if [[ "$dl_url" == *.tar.gz* ]]; then
    tar -xzf "$archive_file" -C "$tmp_dir"
    local extracted_bin
    extracted_bin="$(find "$tmp_dir" -maxdepth 2 -type f \( -name "antigravity" -o -name "agy" \) | head -n 1)"
    if [[ -z "$extracted_bin" || ! -f "$extracted_bin" ]]; then
      log_error "Could not find binary in extracted archive."
      return 1
    fi
    cp -f "$extracted_bin" "$BINARY_PATH"
  else
    cp -f "$archive_file" "$BINARY_PATH"
  fi

  chmod +x "$BINARY_PATH"

  if [[ "$(uname -s)" == "Darwin" ]] && has_cmd xattr; then
    xattr -d com.apple.quarantine "$BINARY_PATH" 2>/dev/null || true
  fi

  # Shell configuration handoff
  "$BINARY_PATH" install --dir "$TARGET_DIR" 2>/dev/null || "$BINARY_PATH" install 2>/dev/null || true
  return 0
}

# ------------------------------------------------------------------------------
# Execute Installation if not already done via brew
# ------------------------------------------------------------------------------
if [[ "$installed_via_brew" != true ]]; then
  if ! install_via_bootstrapper; then
    install_via_direct_download
  fi
fi

# ------------------------------------------------------------------------------
# System-wide symlink if permitted
# ------------------------------------------------------------------------------
if [[ -x "$BINARY_PATH" && ! -e "/usr/local/bin/agy" ]]; then
  if [[ -w "/usr/local/bin" ]]; then
    ln -sf "$BINARY_PATH" "/usr/local/bin/agy" 2>/dev/null || true
  elif has_cmd sudo; then
    run_privileged ln -sf "$BINARY_PATH" "/usr/local/bin/agy" 2>/dev/null || true
  fi
fi

# ------------------------------------------------------------------------------
# Verification
# ------------------------------------------------------------------------------
if has_cmd agy || [[ -x "$BINARY_PATH" ]]; then
  INSTALLED_VER="$($(agy --version 2>/dev/null || "$BINARY_PATH" --version 2>/dev/null) | head -n 1 || echo 'unknown')"
  log_success "Antigravity CLI (agy) installed successfully (${INSTALLED_VER})!"
  log_dim "  Binary:  $BINARY_PATH"
  log_dim "  Command: agy"
else
  log_error "Antigravity CLI installation could not be verified."
  exit 1
fi
