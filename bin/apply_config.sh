#!/usr/bin/env bash

copy_config() {
  local APP="$1"
  local REMOTE_CONFIG="$CONFIG/$APP/config/$APP"

  if [[ ! -e "$REMOTE_CONFIG" ]]; then
    log -e "Config source not found at $REMOTE_CONFIG"
    return 1
  fi

  mkdir -p "$HOME/.config"

  if [[ -L "$HOME/.config/$APP" ]]; then
    rm -f "$HOME/.config/$APP"
  fi

  if ln -sfn "$REMOTE_CONFIG" "$HOME/.config/$APP"; then
    return 0
  else
    return 1
  fi
}

apply_config() {
  local APP="$1"
  shift

  if [[ -f "$CONFIG/$APP/install_config.sh" ]]; then
    source "$CONFIG/$APP/install_config.sh"
  else
    log -e "Configuration script for $APP not found."
    return 1
  fi
}
