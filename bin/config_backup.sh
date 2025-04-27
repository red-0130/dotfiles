#!/bin/env bash

main() {
  local CONFIG_NAME="$1"
  local CONFIG_LOCAL="$HOME/.config/$CONFIG_NAME"
  local BACKUP_DIR="$HOME/.config.bak"
  local TIMESTAMP=$(date "+%Y%m%d-%H%M%S")

  printf "Making backup of config for "$CONFIG_NAME""

  if [[ ! -L $BACKUP_DIR ]]; then
    printf "Backup directory not found.\nCreating one now..."
    mkdir "$BACKUP_DIR"
  else
    printf "Moving local config to the backup directory...\n"
    mv "$CONFIG_LOCAL" "$BACKUP_DIR/$CONFIG_NAME-$TIMESTAMP"
    printf "Done.\n"
  fi

}

main $@
