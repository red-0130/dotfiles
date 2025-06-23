# Includes existing profile config
if [[ -f "$HOME/.profile" ]]; then
  source "$HOME/.profile"
fi

# Change directory on remote connect if workspace is set
if source "$HOME/.workspace" &>/dev/null; then
  cd "$PROJECT_WORKSPACE"
fi
