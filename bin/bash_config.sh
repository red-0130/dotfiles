#!/bin/env bash

main() {
  echo "Copying bash config into config directory"
  source "$BIN/config_apply.sh" "bashrc"

  local TIMESTAMP=$(date "+%Y%m%d-%H%M%S")
  local BACKUP_DIR="$HOME/.config.bak/bashrc-$TIMESTAMP"

  echo "Making backup of current bashrc config"
  mkdir -p "$BACKUP_DIR"
  mv "$HOME/.bashrc" "$BACKUP_DIR"
  mv "$HOME/.profile" "$BACKUP_DIR"

  echo "Applying bashrc file"
  ln -s "$ROOT_DIR/bashrc/.bashrc" "$HOME/.bashrc"
  ln -s "$ROOT_DIR/bashrc/.profile" "$HOME/.profile"
  echo "Transfer complete."
  echo "You may need to restart the terminal for config to apply"
}

main "$@"
