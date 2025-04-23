#!/bin/env bash

# @param {directory/file} $1
LOCAL_CONFIG="$1"
main() {
  if [[ ! -L "$LOCAL_CONFIG" ]]; then
    makeBackup "$LOCAL_CONFIG"
  else
    echo "Local config is a sym link. Skipping backup."
  fi
}
makeBackup() {
  DIRNAME=$(basename $LOCAL_CONFIG)
  TIMESTAMP=$(date '+%Y%m%d%H%M%S')
  BACKUP_DIR="$HOME/.config.bak/$TIMESTAMP-$DIRNAME"
  if [[ ! -d "$BACKUP_DIR" ]]; then
    echo "Backup directory not detected."
    echo "Creating backup directory now."
    mkdir "$BACKUP_DIR"
  fi
  echo "Moving existing configuration to backup directory($BACKUP_DIR)"
  mv "$LOCAL_CONFIG" "$BACKUP_DIR"
}

main "$@"
exit
