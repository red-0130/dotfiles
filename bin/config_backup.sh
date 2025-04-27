#!/bin/env bash

main() {
  local CONFIG_NAME="$1"
  local CONFIG_LOCAL="$HOME/.config/$CONFIG_NAME"
  local BACKUP_DIR="$HOME/.config.bak"
  local TIMESTAMP=$(date "+%Y%m%d-%H%M%S")

  printf "Making backup of config for "$CONFIG_NAME""

  if [[ ! -L "$BACKUP_DIR" ]]; then
    echo "Backup directory not found. Creating one now..."
    mkdir "$BACKUP_DIR"
  else
    echo "Backup directory exists. Beginning backup..."
  fi
    echo "Moving local config to the backup directory..."
    mv "$CONFIG_LOCAL" "$BACKUP_DIR/$CONFIG_NAME-$TIMESTAMP"
    echo "Done."

}

main $@
