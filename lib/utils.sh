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
