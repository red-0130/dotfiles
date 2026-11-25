#!/usr/bin/env bash
# ==============================================================================
# Dotfiles Installer Script
# Entry point for personalizing development environments & GitHub Codespaces
# ==============================================================================
set -euo pipefail

if (( BASH_VERSINFO[0] < 4 )); then
  echo "Error: Bash 4.0+ is required (found ${BASH_VERSION:-unknown}). On macOS, install via 'brew install bash'." >&2
  exit 1
fi

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
PREDEFINED_CONFIGS=("${PREDEFINED_CONFIGS[@]:-git bash}")
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

# Run interactive checklist for "config" or "app" and dispatch selected items.
run_interactive_install() {
  local title="$1" kind="$2" install_fn="$3"
  shift 3

  local label="applications" empty_dir="$APPS_DIR" desc_fn="get_app_description"
  local predefined=("${PREDEFINED_APPS[@]:-}")
  if [[ "$kind" == "config" ]]; then
    label="configurations"
    empty_dir="$CONFIG_DIR"
    desc_fn="get_config_description"
    predefined=("${PREDEFINED_CONFIGS[@]:-}")
  fi

  if [[ $# -eq 0 ]]; then
    log_warn "No ${label} found in ${empty_dir}"
    return 0
  fi

  local entries=() item sel badge desc pre
  for item in "$@"; do
    sel=0
    for pre in "${predefined[@]}"; do
      if [[ -n "$pre" && "$pre" == "$item" ]]; then
        sel=1
        break
      fi
    done
    badge=""
    if [[ "$kind" == "app" ]] && is_app_installed "$item"; then
      badge="[installed]"
    fi
    desc="$("$desc_fn" "$item")"
    entries+=("${item}"$'\t'"${sel}"$'\t'"${badge}"$'\t'"${desc}")
  done

  # Exit status: 0 = items selected, 2 = 0 selected, 1 = cancelled
  local menu_out="" menu_status=0
  set +e
  menu_out="$(run_interactive_checklist "$title" "${entries[@]}")"
  menu_status=$?
  set -e

  if [[ $menu_status -eq 0 && -n "$menu_out" ]]; then
    local selected_items=()
    readarray -t selected_items <<<"$menu_out"
    "$install_fn" "${selected_items[@]}"
    return $?
  elif [[ $menu_status -eq 2 || $menu_status -eq 0 ]]; then
    log_warn "No ${label} selected."
  else
    log_info "Selection cancelled (${label})."
  fi
  return 0
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
    return
  fi

  local interactive_config=false
  local interactive_app=false
  local install_all_configs=false
  local explicit_configs=()
  local explicit_apps=()

  # Parse command line flags
  while [[ $# -gt 0 ]]; do
    case "$1" in
    -h | --help)
      show_help
      exit 0
      ;;
    -l | --list)
      list_items
      exit 0
      ;;
    -A | --all)
      install_all_configs=true
      shift
      ;;
    -c | --config)
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
    -a | --app)
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

  local rc=0

  # 1. Handle explicit config installations
  if [[ ${#explicit_configs[@]} -gt 0 ]]; then
    install_configs "${explicit_configs[@]}" || rc=1
  fi

  # 2. Handle --all configs
  if $install_all_configs; then
    local all_configs=()
    readarray -t all_configs < <(get_available_configs)
    install_configs "${all_configs[@]}" || rc=1
  fi

  # 3. Handle interactive config selection
  if $interactive_config; then
    local available_configs=()
    readarray -t available_configs < <(get_available_configs)
    run_interactive_install "Select Configurations to Install" "config" install_configs "${available_configs[@]}" || rc=1
  fi

  # 4. Handle explicit app installations
  if [[ ${#explicit_apps[@]} -gt 0 ]]; then
    install_apps "${explicit_apps[@]}" || rc=1
  fi

  # 5. Handle interactive app selection
  if $interactive_app; then
    local available_apps=()
    readarray -t available_apps < <(get_available_apps)
    run_interactive_install "Select Applications to Install" "app" install_apps "${available_apps[@]}" || rc=1
  fi

  return "$rc"
}

main "$@"
