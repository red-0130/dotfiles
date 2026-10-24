#!/usr/bin/env bash
# ==============================================================================
# Dotfiles Installer Script
# Entry point for personalizing development environments & GitHub Codespaces
# ==============================================================================
set -euo pipefail

# Determine script root directory
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES_DIR

# Config and Apps directories
if [[ -d "${DOTFILES_DIR}/configs" ]]; then
    CONFIG_DIR="${DOTFILES_DIR}/configs"
elif [[ -d "${DOTFILES_DIR}/config" ]]; then
    CONFIG_DIR="${DOTFILES_DIR}/config"
else
    CONFIG_DIR="${DOTFILES_DIR}/configs"
fi
export CONFIG_DIR

APPS_DIR="${DOTFILES_DIR}/apps"
export APPS_DIR

# Load configuration file if present
CONF_FILE="${DOTFILES_DIR}/dotfiles.conf"
if [[ -f "$CONF_FILE" ]]; then
    # shellcheck source=/dev/null
    source "$CONF_FILE"
fi

# Set defaults if not provided in config
PREDEFINED_CONFIGS=("${PREDEFINED_CONFIGS[@]:-git bash tmux}")
PREDEFINED_APPS=("${PREDEFINED_APPS[@]:-}")
DOTFILES_BACKUP_DIR="${DOTFILES_BACKUP_DIR:-$HOME/.dotfiles_backup}"
export DOTFILES_BACKUP_DIR

# Source library modules
source "${DOTFILES_DIR}/lib/utils.sh"
source "${DOTFILES_DIR}/lib/backup.sh"
source "${DOTFILES_DIR}/lib/link.sh"
source "${DOTFILES_DIR}/lib/config_installer.sh"
source "${DOTFILES_DIR}/lib/app_installer.sh"
source "${DOTFILES_DIR}/lib/ui.sh"

# ------------------------------------------------------------------------------
# Help & Usage
# ------------------------------------------------------------------------------
show_help() {
    echo -e "${COLOR_BOLD}Dotfiles Installer${COLOR_RESET}

${COLOR_BOLD}USAGE:${COLOR_RESET}
    ./install.sh [FLAGS] [ARGUMENTS...]

${COLOR_BOLD}FLAGS:${COLOR_RESET}
    (no flags)              Install configs of predefined applications (${PREDEFINED_CONFIGS[*]})
                            Completely non-interactive, standard for GitHub Codespaces.
    -c, --config [NAMES...] Start interactive terminal to select configs to install.
                            Optionally provide config names to install directly.
    -a, --app [NAMES...]    Start interactive terminal to select apps to install.
                            Optionally provide app names to install directly.
    -A, --all               Install all available configurations.
    -l, --list              List all available configs and apps.
    -h, --help              Show this help message.

${COLOR_BOLD}EXAMPLES:${COLOR_RESET}
    ./install.sh                     # Default: installs predefined configs (${PREDEFINED_CONFIGS[*]})
    ./install.sh -c                  # Launch interactive config selection terminal
    ./install.sh --config            # Launch interactive config selection terminal
    ./install.sh -a                  # Launch interactive app selection terminal
    ./install.sh --app               # Launch interactive app selection terminal
    ./install.sh -c git bash         # Directly install git and bash configs
    ./install.sh -a ripgrep fzf      # Directly install ripgrep and fzf apps
    ./install.sh -c -a               # Launch interactive configs then interactive apps"
}

# ------------------------------------------------------------------------------
# List Available Items
# ------------------------------------------------------------------------------
list_items() {
    log_header "Available Configurations in configs/"
    local available_configs=()
    readarray -t available_configs < <(get_available_configs)
    for c in "${available_configs[@]}"; do
        local desc
        desc="$(get_config_description "$c")"
        local pre=""
        for p in "${PREDEFINED_CONFIGS[@]}"; do
            if [[ "$p" == "$c" ]]; then
                pre="${COLOR_GREEN}[predefined]${COLOR_RESET} "
                break
            fi
        done
        printf "  • ${COLOR_BOLD}%-12s${COLOR_RESET} %b%b\n" "$c" "$pre" "${COLOR_GRAY}${desc}${COLOR_RESET}"
    done

    echo ""
    log_header "Available Applications in apps/"
    local available_apps=()
    readarray -t available_apps < <(get_available_apps)
    for a in "${available_apps[@]}"; do
        local desc
        desc="$(get_app_description "$a")"
        local status=""
        if is_app_installed "$a"; then
            status="${COLOR_GREEN}[installed]${COLOR_RESET} "
        fi
        printf "  • ${COLOR_BOLD}%-12s${COLOR_RESET} %b%b\n" "$a" "$status" "${COLOR_GRAY}${desc}${COLOR_RESET}"
    done
    echo ""
}

# ------------------------------------------------------------------------------
# Main Dispatcher
# ------------------------------------------------------------------------------
main() {
    # Detect environment
    local env_type="Local machine"
    if is_codespaces; then
        env_type="GitHub Codespaces"
    elif [[ -f /.dockerenv ]]; then
        env_type="Docker Container"
    fi

    # If no flags are provided, install configs of predefined applications
    if [[ $# -eq 0 ]]; then
        log_header "GitHub Dotfiles Installer"
        log_info "Detected environment: ${COLOR_BOLD}${env_type}${COLOR_RESET}"
        log_info "No flags provided. Installing predefined configs: ${COLOR_GREEN}${PREDEFINED_CONFIGS[*]}${COLOR_RESET}"
        install_configs "${PREDEFINED_CONFIGS[@]}"
        exit 0
    fi

    local interactive_config=false
    local interactive_app=false
    local install_all_configs=false
    local explicit_configs=()
    local explicit_apps=()

    # Parse command line flags
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -l|--list)
                list_items
                exit 0
                ;;
            -A|--all)
                install_all_configs=true
                shift
                ;;
            -c|--config)
                shift
                # Check if specific configs are passed as subsequent arguments
                local found_any=false
                while [[ $# -gt 0 && "$1" != -* ]]; do
                    explicit_configs+=("$1")
                    found_any=true
                    shift
                done
                if ! $found_any; then
                    interactive_config=true
                fi
                ;;
            -a|--app)
                shift
                # Check if specific apps are passed as subsequent arguments
                local found_any=false
                while [[ $# -gt 0 && "$1" != -* ]]; do
                    explicit_apps+=("$1")
                    found_any=true
                    shift
                done
                if ! $found_any; then
                    interactive_app=true
                fi
                ;;
            *)
                log_error "Unknown option: $1"
                echo "Run './install.sh --help' for usage details."
                exit 1
                ;;
        esac
    done

    # 1. Handle explicit config installations
    if [[ ${#explicit_configs[@]} -gt 0 ]]; then
        install_configs "${explicit_configs[@]}"
    fi

    # 2. Handle --all configs
    if $install_all_configs; then
        local all_configs=()
        readarray -t all_configs < <(get_available_configs)
        install_configs "${all_configs[@]}"
    fi

    # 3. Handle interactive config selection
    if $interactive_config; then
        local available_configs=()
        readarray -t available_configs < <(get_available_configs)

        if [[ ${#available_configs[@]} -eq 0 ]]; then
            log_warn "No configurations found in $CONFIG_DIR"
        else
            local selected_configs=()
            # Run interactive checklist; exit status 0 = items selected, 2 = 0 selected, 1 = cancelled
            set +e
            local menu_out
            menu_out="$(run_interactive_checklist "Select Configurations to Install" "config" "${available_configs[@]}")"
            local menu_status=$?
            set -e

            if [[ $menu_status -eq 0 ]]; then
                readarray -t selected_configs <<< "$menu_out"
                install_configs "${selected_configs[@]}"
            elif [[ $menu_status -eq 2 ]]; then
                log_warn "No configurations selected."
            else
                log_info "Configuration selection cancelled."
            fi
        fi
    fi

    # 4. Handle explicit app installations
    if [[ ${#explicit_apps[@]} -gt 0 ]]; then
        install_apps "${explicit_apps[@]}"
    fi

    # 5. Handle interactive app selection
    if $interactive_app; then
        local available_apps=()
        readarray -t available_apps < <(get_available_apps)

        if [[ ${#available_apps[@]} -eq 0 ]]; then
            log_warn "No applications found in $APPS_DIR"
        else
            local selected_apps=()
            set +e
            local menu_out
            menu_out="$(run_interactive_checklist "Select Applications to Install" "app" "${available_apps[@]}")"
            local menu_status=$?
            set -e

            if [[ $menu_status -eq 0 ]]; then
                readarray -t selected_apps <<< "$menu_out"
                install_apps "${selected_apps[@]}"
            elif [[ $menu_status -eq 2 ]]; then
                log_warn "No applications selected."
            else
                log_info "Application installation cancelled."
            fi
        fi
    fi
}

main "$@"
