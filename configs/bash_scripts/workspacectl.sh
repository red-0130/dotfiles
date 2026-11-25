#!/usr/bin/env bash

_wsctl_set_workspace() {
  local WORKSPACE
  if [[ -n "${1:-}" ]]; then
    WORKSPACE="$1"
  else
    WORKSPACE="$PWD"
  fi
  echo "Setting PROJECT_WORKSPACE to $WORKSPACE"
  printf 'PROJECT_WORKSPACE=%q\n' "$WORKSPACE" >"$HOME/.workspace"
}

_wsctl_set_gemini_api() {
  local API="${1:-}"
  if [[ -z "$API" ]]; then
    echo "API key not provided"
    return 1
  else
    echo "Setting GEMINI CLI API..."
    ( umask 077 && touch "$HOME/.gemini_api" && chmod 600 "$HOME/.gemini_api" && printf 'export GEMINI_API_KEY=%q\n' "$API" >"$HOME/.gemini_api" ) || return 1
    echo "Done."
    return 0
  fi
}

_wsctl_get_workspace() {
  [ -z "${PROJECT_WORKSPACE:-}" ] && echo "Default workspace is not set" && return 1
  echo "$PROJECT_WORKSPACE"
}

_wsctl_reset() {
  if [[ -f "$HOME/.workspace" ]]; then rm "$HOME/.workspace"; fi
  if [[ -f "$HOME/.gemini_api" ]]; then rm "$HOME/.gemini_api"; fi
  unset PROJECT_WORKSPACE
  unset GEMINI_API_KEY
}

# Helper function to extract numeric id from JSON response
_wsctl_extract_id() {
  local json="$1"
  if command -v jq &>/dev/null; then
    echo "$json" | jq -r 'if type == "array" then .[0].id else .id end // empty' 2>/dev/null || true
  else
    echo "$json" | grep -m1 -o '"id":[[:space:]]*[0-9]\+' | grep -o '[0-9]\+' || true
  fi
}

# Configure provider-specific noreply email and includeIf rule, with global fallback.
_wsctl_configure_provider() {
  local label="$1" host="$2" noreply_domain="$3" id_sep="${4:-}" api_url_prefix="${5:-}"
  local provider_user=""
  while [[ -z "$provider_user" ]]; do
    read -r -p "Enter username for ${label}: " provider_user
  done

  local provider_id=""
  if [[ -n "$api_url_prefix" ]]; then
    echo "Fetching ${label} user ID for '$provider_user'..."
    if command -v curl &>/dev/null; then
      local res
      res=$(curl -sSL -m 5 "${api_url_prefix}${provider_user}" 2>/dev/null || true)
      provider_id=$(_wsctl_extract_id "$res")
    fi

    if [[ -z "$provider_id" ]]; then
      echo "Could not automatically fetch ${label} user ID."
      read -r -p "Enter ${label} numeric ID (or press Enter to omit): " provider_id
    else
      echo "Found ${label} user ID: $provider_id"
    fi
  fi

  local provider_email
  if [[ -n "$provider_id" && -n "$id_sep" ]]; then
    provider_email="${provider_id}${id_sep}${provider_user}@${noreply_domain}"
  else
    provider_email="${provider_user}@${noreply_domain}"
  fi

  local confirm_email
  read -r -p "Configure ${label} email as '$provider_email'? [Y/n]: " confirm_email
  if [[ "$confirm_email" =~ ^[Nn] ]]; then
    local custom_email
    read -r -p "Enter custom email for ${label}: " custom_email
    if [[ -n "$custom_email" ]]; then
      provider_email="$custom_email"
    fi
  fi

  git config --global "includeIf.hasconfig:remote.*.url:**/*${host}/**.email" "$provider_email"
  echo "Set [includeIf \"hasconfig:remote.*.url:**/*${host}/**\"] email = $provider_email"

  # Set global user.email fallback if not already set
  local current_email
  current_email=$(git config --global user.email 2>/dev/null || true)
  if [[ -z "$current_email" ]]; then
    git config --global user.email "$provider_email"
    echo "Set global fallback user.email to '$provider_email'."
  fi
}

_wsctl_set_gitconfig() {
  if ! command -v git &>/dev/null; then
    echo "Error: git is not installed or not in PATH." >&2
    return 1
  fi

  echo "=== Git Configuration Setup ==="

  # 1. Prevent Git from falling back to system username/hostname
  git config --global user.useConfigOnly true
  echo "Configured user.useConfigOnly = true"

  # 2. Default branch configuration
  local current_branch
  current_branch=$(git config --global init.defaultBranch 2>/dev/null || true)
  if [[ -n "$current_branch" ]]; then
    local keep_branch
    read -r -p "Default branch is currently set to '$current_branch'. Keep it? [Y/n]: " keep_branch
    if [[ "$keep_branch" =~ ^[Nn] ]]; then
      local new_branch
      read -r -p "Enter new default branch name [main]: " new_branch
      new_branch="${new_branch:-main}"
      git config --global init.defaultBranch "$new_branch"
      echo "Default branch set to '$new_branch'."
    else
      echo "Keeping default branch '$current_branch'."
      git config --global init.defaultBranch "$current_branch"
    fi
  else
    local new_branch
    read -r -p "No default branch is set. Enter default branch name [main]: " new_branch
    new_branch="${new_branch:-main}"
    git config --global init.defaultBranch "$new_branch"
    echo "Default branch set to '$new_branch'."
  fi

  # 3. Git username configuration
  local current_user
  current_user=$(git config --global user.name 2>/dev/null || true)
  if [[ -z "$current_user" ]]; then
    local username=""
    while [[ -z "$username" ]]; do
      read -r -p "No git username is set. Enter git username: " username
    done
    git config --global user.name "$username"
    echo "Git username set to '$username'."
  else
    local keep_user
    read -r -p "Git username is currently '$current_user'. Keep it? [Y/n]: " keep_user
    if [[ "$keep_user" =~ ^[Nn] ]]; then
      local username=""
      while [[ -z "$username" ]]; do
        read -r -p "Enter new git username: " username
      done
      git config --global user.name "$username"
      echo "Git username set to '$username'."
    else
      echo "Keeping git username '$current_user'."
    fi
  fi

  # 4. Git user email & remote provider configuration
  local change_email
  read -r -p "Do you want to change/configure git user email? [y/N]: " change_email
  if [[ "$change_email" =~ ^[Yy] ]]; then
    while true; do
      echo ""
      echo "Select remote repo hosting provider:"
      echo "  1) GitHub (github.com)"
      echo "  2) GitLab (gitlab.com)"
      echo "  3) Codeberg (codeberg.org)"
      echo "  4) Global (fallback email)"
      local provider_choice
      read -r -p "Choice [1-4 or name]: " provider_choice

      case "${provider_choice,,}" in
        1|github|gh)
          _wsctl_configure_provider "GitHub" "github.com" "users.noreply.github.com" "+" "https://api.github.com/users/"
          ;;

        2|gitlab|gl)
          _wsctl_configure_provider "GitLab" "gitlab.com" "users.noreply.gitlab.com" "-" "https://gitlab.com/api/v4/users?username="
          ;;

        3|codeberg|cb)
          _wsctl_configure_provider "Codeberg" "codeberg.org" "noreply.codeberg.org"
          ;;

        4|global)
          local current_global_email
          current_global_email=$(git config --global user.email 2>/dev/null || true)
          local fallback_email=""
          while [[ -z "$fallback_email" ]]; do
            read -r -p "Enter global fallback email${current_global_email:+ [current: $current_global_email]}: " fallback_email
            fallback_email="${fallback_email:-$current_global_email}"
          done
          git config --global user.email "$fallback_email"
          echo "Global fallback email set to '$fallback_email'."
          ;;

        *)
          echo "Invalid selection. Please choose 1, 2, 3, 4, github, gitlab, codeberg, or global."
          continue
          ;;
      esac

      local another
      read -r -p "Configure another provider? [y/N]: " another
      if [[ ! "$another" =~ ^[Yy] ]]; then
        break
      fi
    done
  fi

  echo "Git configuration completed successfully."
}

_wsctl_help() {
  cat <<'EOF'
Usage: wsctl <command> [arguments]

Workspace and development environment management helper.

Commands:
  set-workspace [PATH]    Set PROJECT_WORKSPACE in ~/.workspace (defaults to $PWD)
  get-workspace           Print current PROJECT_WORKSPACE
  set-gemini-api <KEY>    Save GEMINI_API_KEY to ~/.gemini_api
  set-gitconfig           Interactively configure Git settings (user, branch, provider email)
  install-app [NAMES...]  Install applications (same as running install.sh -a)
  --reset                 Reset workspace and Gemini API configuration files and variables
  help, -h, --help        Show this help message

Examples:
  wsctl set-workspace ~/projects/dotfiles
  wsctl get-workspace
  wsctl set-gemini-api "AIzaSy..."
  wsctl set-gitconfig
  wsctl install-app
  wsctl --reset
  wsctl help
EOF
}

_wsctl_install_app() {
  local script_source="${BASH_SOURCE[0]}"
  if command -v realpath >/dev/null 2>&1; then
    script_source="$(realpath "$script_source" 2>/dev/null || echo "$script_source")"
  elif command -v readlink >/dev/null 2>&1; then
    script_source="$(readlink -f "$script_source" 2>/dev/null || echo "$script_source")"
  fi

  local repo_dir
  repo_dir="$(cd "$(dirname "$script_source")/../.." 2>/dev/null && pwd)"

  if [[ -z "$repo_dir" || ! -f "$repo_dir/install.sh" ]]; then
    echo "Error: Could not locate install.sh in repository root '$repo_dir'." >&2
    return 1
  fi

  if [[ -x "$repo_dir/install.sh" ]]; then
    "$repo_dir/install.sh" -a "$@"
  else
    bash "$repo_dir/install.sh" -a "$@"
  fi
}

wsctl() {
  if [[ $# -eq 0 ]]; then
    _wsctl_help
    return 0
  fi

  local cmd="$1"
  shift

  case "$cmd" in
    set-workspace) _wsctl_set_workspace "$@" ;;
    set-gemini-api) _wsctl_set_gemini_api "$@" ;;
    get-workspace) _wsctl_get_workspace "$@" ;;
    set-gitconfig) _wsctl_set_gitconfig "$@" ;;
    --reset) _wsctl_reset "$@" ;;
    install-app) _wsctl_install_app "$@" ;;
    help|--help|-h) _wsctl_help ;;
    *)
      echo "Error: Unknown command '$cmd'" >&2
      echo "Run 'wsctl help' for usage information." >&2
      return 1
      ;;
  esac
}

complete -W "set-workspace set-gemini-api get-workspace set-gitconfig install-app --reset help --help" wsctl

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  wsctl "$@"
fi
