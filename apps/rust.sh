#!/usr/bin/env bash
# ==============================================================================
# Rust and Cargo Installer Script
# Reference: https://www.rust-lang.org/tools/install
# description: The Rust programming language compiler (rustc) and Cargo package manager
# command: cargo
# ==============================================================================
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DIR/lib/utils.sh"

# Ensure ~/.cargo/bin and ~/.local/bin are in PATH for current script execution
if [[ -d "$HOME/.cargo/bin" ]] && [[ ":$PATH:" != *":$HOME/.cargo/bin:"* ]]; then
    export PATH="$HOME/.cargo/bin:$PATH"
fi
if [[ -d "$HOME/.local/bin" ]] && [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

# Source ~/.cargo/env if available
if [[ -s "$HOME/.cargo/env" ]]; then
    # shellcheck source=/dev/null
    source "$HOME/.cargo/env"
fi

# ------------------------------------------------------------------------------
# Helper: Symlink cargo binaries into ~/.local/bin for guaranteed PATH availability
# ------------------------------------------------------------------------------
ensure_cargo_symlinks() {
    ensure_dir "$HOME/.local/bin"
    if [[ -d "$HOME/.cargo/bin" ]]; then
        for bin in cargo rustc rustup rustdoc rust-gdb rust-lldb; do
            if [[ -x "$HOME/.cargo/bin/$bin" ]]; then
                ln -sf "$HOME/.cargo/bin/$bin" "$HOME/.local/bin/$bin"
            fi
        done
    fi
}

# ------------------------------------------------------------------------------
# Check if already installed
# ------------------------------------------------------------------------------
if has_cmd rustup; then
    log_info "Rust & Cargo are already installed via rustup. Updating to latest stable..."
    rustup update stable
    ensure_cargo_symlinks
    log_success "Rust & Cargo are up to date: $(rustc --version 2>/dev/null || echo 'rustc') / $(cargo --version 2>/dev/null || echo 'cargo')"
    exit 0
elif has_cmd cargo && has_cmd rustc; then
    ensure_cargo_symlinks
    log_success "Rust & Cargo are already installed ($(rustc --version 2>/dev/null || echo 'rustc') / $(cargo --version 2>/dev/null || echo 'cargo'))"
    exit 0
fi

log_info "Installing Rust runtime and Cargo via rustup..."

# ------------------------------------------------------------------------------
# Ensure C toolchain/linker is available (required by rustc to link binaries)
# ------------------------------------------------------------------------------
if ! has_cmd cc && ! has_cmd gcc && ! has_cmd clang; then
    log_info "No C compiler/linker detected. Installing build prerequisites..."
    PKG="$(detect_pkg_manager)"
    case "$PKG" in
        apt)
            run_privileged apt-get update -qq
            run_privileged apt-get install -y build-essential curl
            ;;
        dnf)
            run_privileged dnf groupinstall -y "Development Tools" 2>/dev/null || run_privileged dnf install -y gcc gcc-c++ make curl
            ;;
        pacman)
            run_privileged pacman -Sy --noconfirm base-devel curl
            ;;
        apk)
            run_privileged apk add build-base curl
            ;;
        zypper)
            run_privileged zypper install -t pattern -y devel_basis 2>/dev/null || run_privileged zypper install -y gcc gcc-c++ make curl
            ;;
        *)
            log_warn "Could not automatically install C build tools. Rust linking may require a C compiler."
            ;;
    esac
fi

# ------------------------------------------------------------------------------
# Download and execute official rustup installer
# Reference: https://sh.rustup.rs
# ------------------------------------------------------------------------------
if ! has_cmd curl && ! has_cmd wget; then
    log_error "curl or wget is required to install rustup."
    exit 1
fi

TMP_DIR="$(mktemp -d)"
RUSTUP_INIT="$TMP_DIR/rustup-init.sh"

if has_cmd curl; then
    curl --proto '=https' --tlsv1.2 -fsSL https://sh.rustup.rs -o "$RUSTUP_INIT"
elif has_cmd wget; then
    wget -qO "$RUSTUP_INIT" https://sh.rustup.rs
fi

log_info "Running rustup installer non-interactively (default toolchain: stable)..."
sh "$RUSTUP_INIT" -y --default-toolchain stable --profile default
rm -rf "$TMP_DIR"

# Source cargo env in current session
if [[ -s "$HOME/.cargo/env" ]]; then
    # shellcheck source=/dev/null
    source "$HOME/.cargo/env"
fi

if [[ -d "$HOME/.cargo/bin" ]] && [[ ":$PATH:" != *":$HOME/.cargo/bin:"* ]]; then
    export PATH="$HOME/.cargo/bin:$PATH"
fi

ensure_cargo_symlinks

# ------------------------------------------------------------------------------
# Verify installation
# ------------------------------------------------------------------------------
if has_cmd cargo && has_cmd rustc; then
    log_success "Rust runtime and Cargo installed successfully:"
    log_info "  rustc: $(rustc --version)"
    log_info "  cargo: $(cargo --version)"
    if has_cmd rustup; then
        log_info "  rustup: $(rustup --version | head -n 1)"
    fi
else
    log_error "Rust / Cargo installation could not be verified."
    exit 1
fi
