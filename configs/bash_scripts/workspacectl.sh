#!/usr/bin/env bash

wsctl() {
  set-workspace() {
    local WORKSPACE
    if [[ -n "$1" ]]; then
      WORKSPACE="$1"
    else
      WORKSPACE="$PWD"
    fi
    echo "Setting PROJECT_WORKSPACE to $WORKSPACE"
    echo "PROJECT_WORKSPACE=$WORKSPACE" >"$HOME/.workspace"
  }

  set-gemini-api() {
    local API="$1"
    if [[ -z "$API" ]]; then
      echo "API key not provided"
      return 1
    else
      echo "Setting GEMINI CLI API..."
      echo "export GEMINI_API_KEY=$API" >"$HOME/.gemini_api"
      echo "Done."
      return 0
    fi
  }

  get-workspace() {
    [ -z "$PROJECT_WORKSPACE" ] && echo "Default workspace is not set" && exit 1
    echo "$PROJECT_WORKSPACE"
  }

  --reset() {
    if [[ -f "$HOME/.workspace" ]]; then rm "$HOME/.workspace"; fi
    if [[ -f "$HOME/.gemini_api" ]]; then rm "$HOME/.gemini_api"; fi
    unset PROJECT_WORKSPACE
    unset GEMINI_API_KEY
  }

  set-gitconfig() {
    if ! command -v git &>/dev/null; then
      echo "Error: git is not installed or not in PATH." >&2
      return 1
    fi

    # Helper function to extract numeric id from JSON response
    _extract_id() {
      local json="$1"
      if command -v jq &>/dev/null; then
        echo "$json" | jq -r 'if type == "array" then .[0].id else .id end // empty' 2>/dev/null
      else
        echo "$json" | grep -m1 -o '"id":[[:space:]]*[0-9]\+' | grep -o '[0-9]\+'
      fi
    }

    echo "=== Git Configuration Setup ==="

    # 1. Prevent Git from falling back to system username/hostname
    git config --global user.useConfigOnly true
    echo "Configured user.useConfigOnly = true"

    # 2. Default branch configuration
    local current_branch
    current_branch=$(git config --global init.defaultBranch 2>/dev/null)
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
    current_user=$(git config --global user.name 2>/dev/null)
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
            local provider_user=""
            while [[ -z "$provider_user" ]]; do
              read -r -p "Enter username for GitHub: " provider_user
            done

            echo "Fetching GitHub user ID for '$provider_user'..."
            local gh_id=""
            if command -v curl &>/dev/null; then
              local res
              res=$(curl -sSL -m 5 "https://api.github.com/users/${provider_user}" 2>/dev/null)
              gh_id=$(_extract_id "$res")
            fi

            if [[ -z "$gh_id" ]]; then
              echo "Could not automatically fetch GitHub user ID."
              read -r -p "Enter GitHub numeric ID (or press Enter to omit): " gh_id
            else
              echo "Found GitHub user ID: $gh_id"
            fi

            local provider_email
            if [[ -n "$gh_id" ]]; then
              provider_email="${gh_id}+${provider_user}@users.noreply.github.com"
            else
              provider_email="${provider_user}@users.noreply.github.com"
            fi

            local confirm_email
            read -r -p "Configure GitHub email as '$provider_email'? [Y/n]: " confirm_email
            if [[ "$confirm_email" =~ ^[Nn] ]]; then
              local custom_email
              read -r -p "Enter custom email for GitHub: " custom_email
              if [[ -n "$custom_email" ]]; then
                provider_email="$custom_email"
              fi
            fi

            git config --global "includeIf.hasconfig:remote.*.url:**/*github.com/**.email" "$provider_email"
            echo "Set [includeIf \"hasconfig:remote.*.url:**/*github.com/**\"] email = $provider_email"

            # Set global user.email fallback if not already set
            local current_email
            current_email=$(git config --global user.email 2>/dev/null)
            if [[ -z "$current_email" ]]; then
              git config --global user.email "$provider_email"
              echo "Set global fallback user.email to '$provider_email'."
            fi
            ;;

          2|gitlab|gl)
            local provider_user=""
            while [[ -z "$provider_user" ]]; do
              read -r -p "Enter username for GitLab: " provider_user
            done

            echo "Fetching GitLab user ID for '$provider_user'..."
            local gl_id=""
            if command -v curl &>/dev/null; then
              local res
              res=$(curl -sSL -m 5 "https://gitlab.com/api/v4/users?username=${provider_user}" 2>/dev/null)
              gl_id=$(_extract_id "$res")
            fi

            if [[ -z "$gl_id" ]]; then
              echo "Could not automatically fetch GitLab user ID."
              read -r -p "Enter GitLab numeric ID (or press Enter to omit): " gl_id
            else
              echo "Found GitLab user ID: $gl_id"
            fi

            local provider_email
            if [[ -n "$gl_id" ]]; then
              provider_email="${gl_id}-${provider_user}@users.noreply.gitlab.com"
            else
              provider_email="${provider_user}@users.noreply.gitlab.com"
            fi

            local confirm_email
            read -r -p "Configure GitLab email as '$provider_email'? [Y/n]: " confirm_email
            if [[ "$confirm_email" =~ ^[Nn] ]]; then
              local custom_email
              read -r -p "Enter custom email for GitLab: " custom_email
              if [[ -n "$custom_email" ]]; then
                provider_email="$custom_email"
              fi
            fi

            git config --global "includeIf.hasconfig:remote.*.url:**/*gitlab.com/**.email" "$provider_email"
            echo "Set [includeIf \"hasconfig:remote.*.url:**/*gitlab.com/**\"] email = $provider_email"

            local current_email
            current_email=$(git config --global user.email 2>/dev/null)
            if [[ -z "$current_email" ]]; then
              git config --global user.email "$provider_email"
              echo "Set global fallback user.email to '$provider_email'."
            fi
            ;;

          3|codeberg|cb)
            local provider_user=""
            while [[ -z "$provider_user" ]]; do
              read -r -p "Enter username for Codeberg: " provider_user
            done

            local provider_email="${provider_user}@noreply.codeberg.org"
            local confirm_email
            read -r -p "Configure Codeberg email as '$provider_email'? [Y/n]: " confirm_email
            if [[ "$confirm_email" =~ ^[Nn] ]]; then
              local custom_email
              read -r -p "Enter custom email for Codeberg: " custom_email
              if [[ -n "$custom_email" ]]; then
                provider_email="$custom_email"
              fi
            fi

            git config --global "includeIf.hasconfig:remote.*.url:**/*codeberg.org/**.email" "$provider_email"
            echo "Set [includeIf \"hasconfig:remote.*.url:**/*codeberg.org/**\"] email = $provider_email"

            local current_email
            current_email=$(git config --global user.email 2>/dev/null)
            if [[ -z "$current_email" ]]; then
              git config --global user.email "$provider_email"
              echo "Set global fallback user.email to '$provider_email'."
            fi
            ;;

          4|global)
            local current_global_email
            current_global_email=$(git config --global user.email 2>/dev/null)
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

  help() {
    cat <<'EOF'
Usage: wsctl <command> [arguments]

Workspace and development environment management helper.

Commands:
  set-workspace [PATH]    Set PROJECT_WORKSPACE in ~/.workspace (defaults to $PWD)
  get-workspace           Print current PROJECT_WORKSPACE
  set-gemini-api <KEY>    Save GEMINI_API_KEY to ~/.gemini_api
  set-gitconfig           Interactively configure Git settings (user, branch, provider email)
  --reset                 Reset workspace and Gemini API configuration files and variables
  help, -h, --help        Show this help message

Examples:
  wsctl set-workspace ~/projects/dotfiles
  wsctl get-workspace
  wsctl set-gemini-api "AIzaSy..."
  wsctl set-gitconfig
  wsctl --reset
  wsctl help
EOF
  }

  if [[ $# -eq 0 ]]; then
    help
    return 0
  fi

  case "$1" in
    set-workspace|set-gemini-api|get-workspace|set-gitconfig|--reset)
      "$@"
      ;;
    help|--help|-h)
      help
      ;;
    *)
      echo "Error: Unknown command '$1'" >&2
      echo "Run 'wsctl help' for usage information." >&2
      return 1
      ;;
  esac
}

complete -W "set-workspace set-gemini-api get-workspace set-gitconfig --reset help --help" wsctl

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  wsctl "$@"
fi
