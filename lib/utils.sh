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
    COLOR_REVERSE="\033[7m"
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
    COLOR_REVERSE=""
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

is_tty() {
    [[ -t 0 ]] || [[ -c /dev/tty ]]
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

# Download a remote script to a temp file and execute it only after a clean, non-empty fetch.
run_remote_script() {
    local shell_bin="$1" url="$2"
    shift 2
    local tmp_script rc=0
    tmp_script="$(mktemp)" || return 1

    if has_cmd curl; then
        curl -fsSL "$url" -o "$tmp_script" || rc=$?
    elif has_cmd wget; then
        wget -qO "$tmp_script" "$url" || rc=$?
    else
        log_error "Neither curl nor wget is available."
        rm -f "$tmp_script"
        return 1
    fi

    if [[ $rc -eq 0 && -s "$tmp_script" ]]; then
        "$shell_bin" "$tmp_script" "$@" || rc=$?
    elif [[ $rc -eq 0 ]]; then
        rc=1
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
