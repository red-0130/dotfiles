# Includes existing profile config
if [[ -f "$HOME/.profile" ]]; then
  source "$HOME/.profile"
fi

# Change directory on remote connect if workspace is set
if [[ -f "$HOME/.workspace" ]]; then
  source "$HOME/.workspace"
  cd "$PROJECT_WORKSPACE"
fi
