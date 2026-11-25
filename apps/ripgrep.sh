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

prepend_path "$HOME/.local/bin"

LATEST_VERSION="$(get_github_latest_version "BurntSushi/ripgrep" "14.1.1")"

# ------------------------------------------------------------------------------
# Check if Ripgrep is already installed and up to date
# ------------------------------------------------------------------------------
if is_cmd_up_to_date "ripgrep" "$LATEST_VERSION" rg; then
    exit 0
fi

log_info "Installing ripgrep..."

# ------------------------------------------------------------------------------
# Helper: Install latest prebuilt binary from GitHub releases
# ------------------------------------------------------------------------------
install_ripgrep_github_binary() {
    local version="${1:-$LATEST_VERSION}"
    log_info "Downloading latest ripgrep prebuilt binary (v${version}) from GitHub..."

    if ! has_cmd tar; then
        log_error "tar is required to extract ripgrep binary."
        exit 1
    fi

    local arch os rg_arch=""
    arch="$(uname -m)"
    os="$(uname -s)"

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

    (
        local tmp_dir extracted_dir
        tmp_dir="$(mktemp -d)" || exit 1
        trap 'rm -rf "$tmp_dir"' EXIT

        if ! download_file "$tmp_dir/$tar_file" \
            "https://github.com/BurntSushi/ripgrep/releases/download/${version}/${tar_file}" \
            "https://github.com/BurntSushi/ripgrep/releases/download/v${version}/${tar_file}" \
            "https://github.com/BurntSushi/ripgrep/releases/latest/download/${tar_file}"; then
            log_error "Failed to download ripgrep binary archive."
            exit 1
        fi

        tar -xzf "$tmp_dir/$tar_file" -C "$tmp_dir"

        if [[ -d "$tmp_dir/$folder_name" ]]; then
            extracted_dir="$tmp_dir/$folder_name"
        else
            extracted_dir="$(find "$tmp_dir" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
        fi

        if [[ -f "$extracted_dir/rg" ]]; then
            install_binary "$extracted_dir/rg" "rg"
        else
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
    )
}

# ------------------------------------------------------------------------------
# Install based on package manager
# ------------------------------------------------------------------------------
if [[ "$(detect_pkg_manager)" == "apt" ]]; then
    # On Debian/Ubuntu, apt repositories frequently package outdated versions.
    # Use official prebuilt binary release from GitHub instead.
    if has_cmd apt-get && dpkg -l ripgrep 2>/dev/null | grep -q '^ii'; then
        log_info "Removing outdated ripgrep package from apt..."
        run_privileged apt-get remove -y ripgrep 2>/dev/null || true
    fi
    install_ripgrep_github_binary "$LATEST_VERSION"
else
    rc=0
    pkg_install ripgrep || rc=$?
    if [[ $rc -eq 2 ]]; then
        install_ripgrep_github_binary "$LATEST_VERSION"
    elif [[ $rc -ne 0 ]]; then
        exit "$rc"
    fi
fi

# ------------------------------------------------------------------------------
# Verify installation
# ------------------------------------------------------------------------------
prepend_path "$HOME/.local/bin"

if has_cmd rg; then
    log_success "ripgrep installed successfully: $(rg --version 2>/dev/null | head -n 1 || echo 'rg in PATH')"
else
    log_error "ripgrep installation could not be verified."
    exit 1
fi
