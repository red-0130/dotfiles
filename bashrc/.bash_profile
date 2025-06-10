# Includes existing profile config
if [[ -f "$HOME/.profile" ]]; then
  source "$HOME/.profile"
fi

# Change directory on remote connect if workspace is set
if [[ "$PROJECT_WORKSPACE" != "" ]]; then
  cd "$PROJECT_WORKSPACE"
fi
