#!/usr/bin/env bash
# ==============================================================================
# lib/app_installer.sh - Application discovery and installation
# ==============================================================================

get_available_apps() {
  local apps=()
  if [[ -d "$APPS_DIR" ]]; then
    for item in "$APPS_DIR"/*; do
      [[ -e "$item" ]] || continue
      local name
      name="$(basename "$item")"
      [[ "$name" == .* ]] && continue
      [[ "$name" == "README"* ]] && continue
      # Strip .sh extension
      name="${name%.sh}"
      apps+=("$name")
    done
  fi
  printf '%s\n' "${apps[@]}"
}

get_app_script_path() {
  local app="$1"
  if [[ -f "$APPS_DIR/${app}.sh" ]]; then
    echo "$APPS_DIR/${app}.sh"
  elif [[ -f "$APPS_DIR/${app}" ]]; then
    echo "$APPS_DIR/${app}"
  elif [[ -f "$APPS_DIR/${app}/install.sh" ]]; then
    echo "$APPS_DIR/${app}/install.sh"
  else
    return 1
  fi
}

get_app_description() {
  local app="$1"
  local script_path
  script_path="$(get_app_script_path "$app" 2>/dev/null)"

  if [[ -n "$script_path" && -f "$script_path" ]]; then
    local desc
    desc="$(grep -m 1 -E '^#\s*(description|desc):' "$script_path" | sed -E 's/^#\s*(description|desc):\s*//')"
    if [[ -n "$desc" ]]; then
      echo "$desc"
      return 0
    fi
  fi

  # Built-in friendly descriptions
  case "$app" in
  git) echo "Distributed version control system" ;;
  fzf) echo "Command-line fuzzy interactive finder" ;;
  bat) echo "Cat clone with syntax highlighting and Git integration" ;;
  neovim) echo "Vim-fork focused on extensibility and usability (nvim)" ;;
  zsh) echo "Z shell interactive command interpreter" ;;
  *) echo "Installer for ${app}" ;;
  esac
}

get_app_command_name() {
  local app="$1"
  local script_path
  script_path="$(get_app_script_path "$app" 2>/dev/null)"

  if [[ -n "$script_path" && -f "$script_path" ]]; then
    local cmd
    cmd="$(grep -m 1 -E '^#\s*command:' "$script_path" | sed -E 's/^#\s*command:\s*//')"
    if [[ -n "$cmd" ]]; then
      echo "$cmd"
      return 0
    fi
  fi

  # Fallback mappings
  case "$app" in
  ripgrep) echo "rg" ;;
  neovim) echo "nvim" ;;
  *) echo "$app" ;;
  esac
}

is_app_installed() {
  local app="$1"
  local cmd
  cmd="$(get_app_command_name "$app")"
  has_cmd "$cmd"
}

install_single_app() {
  local app="$1"
  local script_path
  script_path="$(get_app_script_path "$app")"

  if [[ -z "$script_path" || ! -f "$script_path" ]]; then
    log_error "App installer script not found for: $app"
    return 1
  fi

  # Ensure executable permission
  chmod +x "$script_path" 2>/dev/null || true

  log_step "Installing application: ${COLOR_BOLD}${app}${COLOR_RESET}"

  if is_app_installed "$app"; then
    local cmd="$(get_app_command_name "$app")"
    log_info "${app} (${cmd}) is already installed on this system. Running installer script to update or verify..."
  fi

  if "$script_path"; then
    log_success "Application ${COLOR_BOLD}${app}${COLOR_RESET} installed successfully!"
    return 0
  else
    log_error "Failed to install application: ${app}"
    return 1
  fi
}

install_apps() {
  local apps=("$@")
  if [[ ${#apps[@]} -eq 0 ]]; then
    log_warn "No apps specified to install."
    return 0
  fi

  log_header "Installing Selected Applications (${#apps[@]})"
  local count=0
  local failed=0

  for app in "${apps[@]}"; do
    if install_single_app "$app"; then
      count=$((count + 1))
    else
      failed=$((failed + 1))
    fi
  done

  echo ""
  if [[ $failed -eq 0 ]]; then
    log_success "Completed: Installed ${count} application(s) successfully!"
  else
    log_warn "Finished with ${failed} failure(s). ${count} app(s) installed successfully."
  fi
}
