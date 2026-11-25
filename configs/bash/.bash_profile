# BASH_PROFILE
# Includes existing profile config
[[ -f "$HOME/.profile" ]] && source "$HOME/.profile"

# Change directory on remote connect if workspace is set
if [[ -f "$HOME/.workspace" ]]; then
  source "$HOME/.workspace"
  export ZELLIJ_AUTO_EXIT=true
  if [[ -n "${PROJECT_WORKSPACE:-}" && -d "$PROJECT_WORKSPACE" ]]; then
    cd "$PROJECT_WORKSPACE"
  fi
fi
