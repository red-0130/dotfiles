#!/usr/bin/env bash
# ==============================================================================
# lib/utils.sh - Core utilities, colors, logging, and platform detection
# ==============================================================================

# Enable color output if terminal supports it and NO_COLOR is not set
if [[ -t 1 ]] && [[ -z "${NO_COLOR:-}" ]]; then
    COLOR_RESET="\033[0m"
    COLOR_BOLD="\033[1m"
    COLOR_DIM="\033[2m"
    COLOR_RED="\033[31m"
    COLOR_GREEN="\033[32m"
    COLOR_YELLOW="\033[33m"
    COLOR_BLUE="\033[34m"
    COLOR_MAGENTA="\033[35m"
    COLOR_CYAN="\033[36m"
    COLOR_GRAY="\033[90m"
else
    COLOR_RESET=""
    COLOR_BOLD=""
    COLOR_DIM=""
    COLOR_RED=""
    COLOR_GREEN=""
    COLOR_YELLOW=""
    COLOR_BLUE=""
    COLOR_MAGENTA=""
    COLOR_CYAN=""
    COLOR_GRAY=""
fi

# ------------------------------------------------------------------------------
# Logging Functions
# ------------------------------------------------------------------------------
log_header() {
    local text="$1"
    echo -e "\n${COLOR_BOLD}${COLOR_BLUE}==>${COLOR_RESET} ${COLOR_BOLD}${text}${COLOR_RESET}"
}

log_info() {
    echo -e "  ${COLOR_CYAN}ℹ${COLOR_RESET} $*"
}

log_success() {
    echo -e "  ${COLOR_GREEN}✔${COLOR_RESET} $*"
}

log_warn() {
    echo -e "  ${COLOR_YELLOW}⚠${COLOR_RESET} $*" >&2
}

log_error() {
    echo -e "  ${COLOR_RED}✖${COLOR_RESET} $*" >&2
}

log_step() {
    echo -e "  ${COLOR_MAGENTA}→${COLOR_RESET} $*"
}

log_dim() {
    echo -e "  ${COLOR_GRAY}$*${COLOR_RESET}"
}

# ------------------------------------------------------------------------------
# Platform & System Detection
# ------------------------------------------------------------------------------
has_cmd() {
    command -v "$1" >/dev/null 2>&1
}

is_codespaces() {
    [[ -n "${CODESPACES:-}" ]] || [[ -n "${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN:-}" ]]
}

detect_os() {
    local os
    os="$(uname -s | tr '[:upper:]' '[:lower:]')"
    case "$os" in
        linux*)
            if [[ -f /etc/alpine-release ]]; then
                echo "alpine"
            elif [[ -f /etc/arch-release ]]; then
                echo "arch"
            elif [[ -f /etc/debian_version ]] || [[ -f /etc/ubuntu-release ]]; then
                echo "debian"
            elif [[ -f /etc/fedora-release ]] || [[ -f /etc/redhat-release ]]; then
                echo "rhel"
            else
                echo "linux"
            fi
            ;;
        darwin*)
            echo "macos"
            ;;
        msys*|cygwin*|mingw*)
            echo "windows"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

detect_pkg_manager() {
    if has_cmd apt-get; then
        echo "apt"
    elif has_cmd brew; then
        echo "brew"
    elif has_cmd pacman; then
        echo "pacman"
    elif has_cmd dnf; then
        echo "dnf"
    elif has_cmd apk; then
        echo "apk"
    elif has_cmd zypper; then
        echo "zypper"
    else
        echo "unknown"
    fi
}

# Execute with sudo if needed and permitted, otherwise run directly
run_privileged() {
    if [[ $EUID -eq 0 ]]; then
        "$@"
    elif has_cmd sudo; then
        sudo "$@"
    else
        "$@"
    fi
}

ensure_dir() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
    fi
}

prepend_path() {
    local dir="${1:-}"
    if [[ -n "$dir" && -d "$dir" && ":$PATH:" != *":$dir:"* ]]; then
        export PATH="${dir}${PATH:+:$PATH}"
    fi
}

# Fetch latest release tag (without leading 'v') from GitHub, with optional fallback.
get_github_latest_version() {
    local repo="${1:?repo required (owner/repo)}"
    local fallback="${2:-}"
    local version=""

    if has_cmd curl; then
        version="$(curl -fsSL "https://api.github.com/repos/${repo}/releases/latest" 2>/dev/null | grep -m 1 '"tag_name":' | sed -nE 's/.*"tag_name":[[:space:]]*"v?([^"]+)".*/\1/p' || true)"
        if [[ -z "$version" ]]; then
            version="$(curl -fsSIL "https://github.com/${repo}/releases/latest" 2>/dev/null | tr -d '\r' | grep -iE '^location:.*/tag/' | head -n 1 | sed -nE 's/.*\/tag\/v?([^[:space:]]+).*/\1/p' || true)"
        fi
    fi

    if [[ -z "$version" ]] && has_cmd wget; then
        version="$(wget -qO- "https://api.github.com/repos/${repo}/releases/latest" 2>/dev/null | grep -m 1 '"tag_name":' | sed -nE 's/.*"tag_name":[[:space:]]*"v?([^"]+)".*/\1/p' || true)"
    fi

    if [[ -z "$version" ]]; then
        version="$fallback"
    fi

    echo "$version"
}

# Try each URL in order via curl then wget; keep destination only if non-empty.
download_file() {
    local dest="$1"
    shift
    if ! has_cmd curl && ! has_cmd wget; then
        log_error "Neither curl nor wget is available."
        return 1
    fi
    local url
    for url in "$@"; do
        [[ -n "$url" ]] || continue
        rm -f "$dest"
        if has_cmd curl; then
            if curl -fsSL "$url" -o "$dest" 2>/dev/null && [[ -s "$dest" ]]; then
                return 0
            fi
        elif has_cmd wget; then
            if wget -qO "$dest" "$url" 2>/dev/null && [[ -s "$dest" ]]; then
                return 0
            fi
        fi
    done
    rm -f "$dest"
    return 1
}

# Download a remote script to a temp file and execute it only after a clean, non-empty fetch.
run_remote_script() {
    local shell_bin="$1" url="$2"
    shift 2
    local tmp_script rc=0
    tmp_script="$(mktemp)" || return 1

    if download_file "$tmp_script" "$url"; then
        "$shell_bin" "$tmp_script" "$@" || rc=$?
    else
        rc=$?
    fi

    rm -f "$tmp_script"
    return "$rc"
}

# Download an APT signing key to a temp file before writing the destination keyring.
install_apt_keyring() {
    local url="$1" dest="$2" mode="${3:-}"
    local tmp_key rc=0
    tmp_key="$(mktemp)" || return 1

    if ! curl -fsSL "$url" -o "$tmp_key" || [[ ! -s "$tmp_key" ]]; then
        rm -f "$tmp_key"
        return 1
    fi

    run_privileged mkdir -p -m 755 "$(dirname "$dest")" || { rm -f "$tmp_key"; return 1; }
    if [[ "$mode" == "--dearmor" ]] && has_cmd gpg; then
        if run_privileged gpg --dearmor --yes -o "$dest" "$tmp_key"; then
            run_privileged chmod 644 "$dest" || rc=$?
        else
            rc=$?
        fi
    else
        run_privileged install -m 644 "$tmp_key" "$dest" || rc=$?
    fi

    rm -f "$tmp_key"
    return "$rc"
}

# Return 0 if version $1 >= $2 (dot-separated integers, optional leading 'v')
version_ge() {
    local v1="${1:-}" v2="${2:-}"
    v1="${v1#[vV]}"
    v2="${v2#[vV]}"
    [[ -n "$v1" && -n "$v2" ]] || return 1

    local IFS='.'
    local -a a b
    read -r -a a <<< "$v1"
    read -r -a b <<< "$v2"

    local i max=${#a[@]}
    (( ${#b[@]} > max )) && max=${#b[@]}

    local ai bi
    for (( i = 0; i < max; i++ )); do
        ai="${a[i]:-0}"
        bi="${b[i]:-0}"
        ai="${ai%%[!0-9]*}"; ai="${ai:-0}"
        bi="${bi%%[!0-9]*}"; bi="${bi:-0}"
        if (( 10#$ai > 10#$bi )); then
            return 0
        elif (( 10#$ai < 10#$bi )); then
            return 1
        fi
    done
    return 0
}

# Check if any candidate command/path is installed and >= latest_version.
# Usage: is_cmd_up_to_date <label> <latest_version> [--keep-if-offline] <cmd_or_path...>
is_cmd_up_to_date() {
    local label="$1" latest="$2" keep_if_offline=false
    shift 2
    if [[ "${1:-}" == "--keep-if-offline" ]]; then
        keep_if_offline=true
        shift
    fi
    local found="" c current=""
    for c in "$@"; do
        if [[ "$c" == */* ]]; then
            if [[ -x "$c" ]]; then
                found="$c"; break
            fi
        elif has_cmd "$c"; then
            found="$c"; break
        fi
    done
    [[ -n "$found" ]] || return 1

    current="$("$found" --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n 1 || true)"
    if [[ -n "$current" && -n "$latest" ]]; then
        if version_ge "$current" "$latest"; then
            log_success "${label} is already at the latest version (v${current})"
            return 0
        fi
        log_info "Current ${label} (v${current}) is outdated. Upgrading to latest version (v${latest})..."
        return 1
    elif [[ -n "$current" && "$keep_if_offline" == "true" ]]; then
        log_success "${label} is already installed (v${current})"
        return 0
    fi
    log_info "${label} is installed. Verifying latest version..."
    return 1
}

# Install binary to target_dir (default ~/.local/bin) and mirror to /usr/local/bin if privileged.
install_binary() {
    local src="$1" name="$2" target_dir="${3:-$HOME/.local/bin}"
    [[ -f "$src" ]] || { log_error "Binary not found: $src"; return 1; }
    ensure_dir "$target_dir"
    install -m 755 "$src" "$target_dir/$name"
    if [[ "$target_dir" == "$HOME/.local/bin" ]] && { [[ $EUID -eq 0 ]] || has_cmd sudo; }; then
        run_privileged mkdir -p /usr/local/bin 2>/dev/null || true
        run_privileged install -m 755 "$src" "/usr/local/bin/$name" 2>/dev/null || true
    fi
}

# Create ~/.local/bin/<alias_name> symlink when target_cmd exists and alias_name is missing.
ensure_bin_alias() {
    local target_cmd="$1" alias_name="$2"
    if has_cmd "$target_cmd" && ! has_cmd "$alias_name"; then
        ensure_dir "$HOME/.local/bin"
        ln -sf "$(command -v "$target_cmd")" "$HOME/.local/bin/$alias_name"
    fi
}

# Download .tar.gz/.tgz from first working URL, extract in a subshell-trapped temp dir, and install binary.
# bin_patterns supports '|'-separated executable names (e.g. "spf|superfile").
install_tar_binary() {
    local bin_patterns="$1" dest_name="$2"
    shift 2
    has_cmd tar || { log_error "tar is required to extract archive."; return 1; }
    (
        local tmp_dir archive found="" name
        local -a names=()
        tmp_dir="$(mktemp -d)" || return 1
        trap 'rm -rf "$tmp_dir"' EXIT
        archive="$tmp_dir/archive.tar.gz"
        download_file "$archive" "$@" || return 1
        tar -xzf "$archive" -C "$tmp_dir" || return 1
        IFS='|' read -ra names <<< "$bin_patterns"
        for name in "${names[@]}"; do
            if [[ -f "$tmp_dir/$name" ]]; then
                found="$tmp_dir/$name"; break
            fi
            found="$(find "$tmp_dir" -type f -name "$name" 2>/dev/null | head -n 1)"
            [[ -n "$found" ]] && break
        done
        [[ -n "$found" && -f "$found" ]] || { log_error "Binary '${bin_patterns}' not found in archive."; return 1; }
        install_binary "$found" "$dest_name"
    )
}

# Install package using detected manager; pass manager=pkg overrides (empty value returns 2).
pkg_install() {
    local default_pkg="$1" pkg_mgr pkg_name arg
    shift
    pkg_mgr="$(detect_pkg_manager)"
    pkg_name="$default_pkg"
    for arg in "$@"; do
        if [[ "$arg" == "${pkg_mgr}="* ]]; then
            pkg_name="${arg#*=}"; break
        fi
    done
    [[ -n "$pkg_name" ]] || return 2
    case "$pkg_mgr" in
        apt)    run_privileged apt-get update -qq && run_privileged apt-get install -y "$pkg_name" ;;
        brew)   brew install "$pkg_name" ;;
        pacman) run_privileged pacman -Sy --noconfirm "$pkg_name" ;;
        dnf)    run_privileged dnf install -y "$pkg_name" ;;
        apk)    run_privileged apk add "$pkg_name" ;;
        zypper) run_privileged zypper install -y "$pkg_name" ;;
        *)      return 2 ;;
    esac
}

# Configure APT keyring + source list entry + update.
add_apt_repo() {
    local key_url="$1" keyring="$2" source_line="$3" list_file="$4" mode="${5:-}"
    install_apt_keyring "$key_url" "$keyring" "$mode" || return 1
    printf '%s\n' "$source_line" | run_privileged tee "$list_file" >/dev/null || return 1
    run_privileged chmod 644 "$list_file" || return 1
    run_privileged apt-get update -qq
}
