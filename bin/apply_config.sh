#!/usr/bin/env bash

copy_config() {
  local APP="$1"
  local REMOTE_CONFIG="$CONFIG/$APP/config/$APP"

  if [[ ! -d "$REMOTE_CONFIG" ]]; then
    exit 1
  fi

  if ln -sf "$REMOTE_CONFIG" "$HOME/.config/"; then
    return 0
  else
    return 1
  fi
}

apply_config() {
  local APP="$1"
  shift

  source "$CONFIG/$APP/install_config.sh"
}
