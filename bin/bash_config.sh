#!/bin/env bash
bash_config() {
  source "$BIN/message.sh"
  log_info bashrc "Copying bash config into config directory"

  source "$BIN/config_apply.sh" "bashrc"

  local TIMESTAMP=$(date "+%Y%m%d-%H%M%S")
  local BACKUP_DIR="$HOME/.config.bak/bashrc-$TIMESTAMP"

  log_info BASHRC "Making backup of current bashrc config"
  mkdir -p "$BACKUP_DIR"
  mv "$HOME/.bashrc" "$BACKUP_DIR"
  mv "$HOME/.profile" "$BACKUP_DIR"

  log_info BASHRC "Applying bashrc file"
  ln -sf "$ROOT_DIR/bashrc/.bashrc" "$HOME/.bashrc"
  ln -sf "$ROOT_DIR/bashrc/.profile" "$HOME/.profile"
  ln -sf "$ROOT_DIR/bashrc/.bash_profile" "$HOME/.bash_profile"
  log_success BASHRC "Transfer complete."
  log_warning BASHRC "You may need to restart the terminal for config to apply"
}
