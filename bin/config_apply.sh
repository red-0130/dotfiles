#!/bin/env bash

local CONFIG_NAME="$1"
local LOCAL_CONFIG="$HOME/.config/$CONFIG_NAME"
local MAKE_BACKUP="source "$BIN/config_backup.sh""
local CONFIG_MAIN="$ROOT_DIR/$CONFIG_NAME/.config/$CONFIG_NAME"

main() {
  if [[ -e "$LOCAL_CONFIG" ]]; then
    $MAKE_BACKUP "$CONFIG_NAME"
  fi

  if [[ ! -d "$HOME/.config" ]]; then
    mkdir "$HOME/.config"
  fi

  if ln -sf "$CONFIG_MAIN" "$HOME/.config/"; then
    echo "Finished applying config."
  else
    echo "There was an error applying config for $CONFIG_NAME"
  fi
}

main "$@"
