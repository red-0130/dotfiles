#!/usr/bin/env bash
# ==============================================================================
# Git Installer Script
# Reference: https://git-scm.com/download/linux (https://git-scm.com/install/linux)
# description: Distributed revision control system (latest upstream release)
# command: git
# ==============================================================================
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DIR/lib/utils.sh"

log_info "Preparing latest Git installation (per https://git-scm.com/download/linux)..."

if has_cmd git; then
    CURRENT_VERSION="$(git --version 2>/dev/null || echo 'unknown')"
    log_info "Current Git version: ${CURRENT_VERSION}"
fi

# ------------------------------------------------------------------------------
# Helper: Add git-core/ppa for Debian / Ubuntu
# Documented on git-scm.com: "add-apt-repository ppa:git-core/ppa && apt update && apt install git"
# Handles Debian 13+ Sequoia (sqv) SHA-1 policy compatibility
# ------------------------------------------------------------------------------
add_git_core_ppa() {
    log_info "Configuring git-core/ppa repository to ensure latest upstream Git..."

    local os_id=""
    local codename=""
    if [[ -f /etc/os-release ]]; then
        # shellcheck source=/dev/null
        source /etc/os-release
        os_id="${ID:-}"
        codename="${VERSION_CODENAME:-}"
    fi

    # 1. On modern Debian 13+ (trixie) or systems using Sequoia sqv for apt signature verification:
    # Launchpad PPA signing keys created prior to 2026 contain SHA-1 self-certification signatures.
    # sqv enforces a strict cutoff rejecting SHA-1, causing 'Policy rejected non-revocation signature... SHA1 is not considered secure'.
    # Resolve by:
    #   a) Setting APT to use traditional /usr/bin/gpgv
    #   b) Configuring Sequoia policy to allow SHA-1 for backward compatibility
    if [[ -x /usr/bin/gpgv ]]; then
        log_info "Configuring APT to use gpgv verification for PPA compatibility..."
        echo 'APT::Key::gpgvcommand "/usr/bin/gpgv";' | run_privileged tee /etc/apt/apt.conf.d/99force-gpgv > /dev/null
    fi

    if [[ -x /usr/bin/sqv ]] || has_cmd sqv; then
        run_privileged mkdir -p /etc/crypto-policies/back-ends
        if [[ ! -f /etc/crypto-policies/back-ends/sequoia.config ]] || ! grep -q "sha1" /etc/crypto-policies/back-ends/sequoia.config 2>/dev/null; then
            echo -e "[hash_algorithms]\nsha1 = \"always\"" | run_privileged tee -a /etc/crypto-policies/back-ends/sequoia.config > /dev/null
        fi
    fi

    # 2. On Ubuntu with native add-apt-repository
    if [[ "$os_id" == "ubuntu" ]] && has_cmd add-apt-repository; then
        log_info "Adding ppa:git-core/ppa via add-apt-repository..."
        run_privileged add-apt-repository -y ppa:git-core/ppa
    else
        # 3. On Debian or Ubuntu without add-apt-repository:
        # Import Launchpad PPA signing keys and configure sources.list.d entry
        log_info "Configuring git-core/ppa repository and GPG signing keys..."
        run_privileged mkdir -p -m 755 /etc/apt/keyrings

        local KEYRING="/etc/apt/keyrings/git-core-ppa.gpg"
        local ubuntu_codename="noble"
        if [[ "$os_id" == "ubuntu" && -n "$codename" ]]; then
            ubuntu_codename="$codename"
        fi

        # Fetch both primary key (E1DD270288B4E6030699E45FA1715D88E1DF1F24)
        # and signing subkey (F911AB184317630C59970973E363C90F8F1B6217)
        if has_cmd curl; then
            local tmp_key
            tmp_key="$(mktemp)"
            curl -fsSL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xE1DD270288B4E6030699E45FA1715D88E1DF1F24" > "$tmp_key"
            curl -fsSL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xF911AB184317630C59970973E363C90F8F1B6217" >> "$tmp_key" 2>/dev/null || true
            if has_cmd gpg; then
                run_privileged gpg --dearmor --yes -o "$KEYRING" < "$tmp_key" 2>/dev/null || run_privileged cp "$tmp_key" "$KEYRING"
            else
                run_privileged cp "$tmp_key" "$KEYRING"
            fi
            rm -f "$tmp_key"
        elif has_cmd gpg; then
            run_privileged gpg --no-default-keyring --keyring "$KEYRING" --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys E1DD270288B4E6030699E45FA1715D88E1DF1F24 F911AB184317630C59970973E363C90F8F1B6217 2>/dev/null
        fi

        run_privileged chmod 644 "$KEYRING" 2>/dev/null || true

        # Write PPA apt source list
        echo "deb [signed-by=${KEYRING}] http://ppa.launchpad.net/git-core/ppa/ubuntu ${ubuntu_codename} main" | run_privileged tee /etc/apt/sources.list.d/git-core-ppa.list > /dev/null
        run_privileged chmod 644 /etc/apt/sources.list.d/git-core-ppa.list
    fi
}

# ------------------------------------------------------------------------------
# Install / Upgrade Git based on package managers documented by git-scm.com
# ------------------------------------------------------------------------------
PKG="$(detect_pkg_manager)"

case "$PKG" in
    apt)
        add_git_core_ppa
        log_info "Updating apt package cache and installing latest Git..."
        if ! run_privileged apt-get update -qq; then
            log_warn "Apt update returned warnings. Retrying with verbose output..."
            run_privileged apt-get update || true
        fi

        if ! run_privileged apt-get install -y git; then
            log_warn "Failed to install git from PPA repository, falling back to distribution package..."
            run_privileged rm -f /etc/apt/sources.list.d/git-core-ppa.list
            run_privileged apt-get update -qq
            run_privileged apt-get install -y git
        fi
        ;;
    dnf)
        log_info "Installing Git via dnf..."
        run_privileged dnf install -y git
        ;;
    pacman)
        log_info "Installing Git via pacman..."
        run_privileged pacman -Sy --noconfirm git
        ;;
    zypper)
        log_info "Installing Git via zypper..."
        run_privileged zypper install -y git
        ;;
    apk)
        log_info "Installing Git via apk..."
        run_privileged apk add --upgrade git
        ;;
    brew)
        log_info "Installing/upgrading Git via Homebrew..."
        brew install git 2>/dev/null || brew upgrade git 2>/dev/null || true
        ;;
    *)
        if has_cmd yum; then
            log_info "Installing Git via yum..."
            run_privileged yum install -y git
        elif has_cmd emerge; then
            log_info "Installing Git via emerge..."
            run_privileged emerge --ask=n --verbose dev-vcs/git
        elif has_cmd nix-env; then
            log_info "Installing Git via nix-env..."
            nix-env -i git
        elif has_cmd urpmi; then
            log_info "Installing Git via urpmi..."
            run_privileged urpmi --auto git
        elif has_cmd pkg; then
            log_info "Installing Git via pkg..."
            run_privileged pkg install -y git
        else
            log_error "No supported package manager found from git-scm.com documentation."
            exit 1
        fi
        ;;
esac

if has_cmd git; then
    log_success "Git installed/updated successfully: $(git --version)"
else
    log_error "Git installation failed: 'git' command not found."
    exit 1
fi
