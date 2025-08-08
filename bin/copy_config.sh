copy_config() {
  local APP="$1"
  shift
  local REMOTE_CONFIG="$CONFIG/$APP/config/$APP"

  if [[ ! -d "$REMOTE_CONFIG" ]]; then
    log_error $APP "Could not find a config to apply. Please check that it exist."
    exit 1
  fi

  if ln -sf "$REMOTE_CONFIG" "$HOME/.config/"; then
    return 0
  else
    return 1
  fi
}
