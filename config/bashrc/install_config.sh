#!/usr/bin/env bash

if ! source "$BIN/path_exist.sh"; then exit 1; fi

main() {

  local BASHRC="$HOME/.bashrc"
  local CUSTOM_BASH="# Custom bash sourcing"
  local ALIASES_PATH="# Bash custom alias location\nsource "\$HOME/.config/bashrc/aliases.sh""
  local CUSTOM_PATH="# Bash custom PATHS\nsource "\$HOME/.config/bashrc/paths.sh""
  local ENV_PATH="# Bash custom ENV\nsource "\$HOME/.config/bashrc/env.sh""

  log_info BASHRC "Making backup of current bashrc config"
  backup bashrc "$HOME/.bashrc" "$HOME/.profile" "$HOME/.bash_profile"

  log_info BASHRC "Applying bashrc file"
  if ! grep $CUSTOM_BASH $BASHRC; then
    echo -e "\n##################################################" >>$BASHRC
    echo $CUSTOM_BASH >>$BASHRC
    echo -e $ALIASES_PATH >>$BASHRC
    echo -e $CUSTOM_PATH >>$BASHRC
    echo -e $ENV_PATH >>$BASHRC
    echo -e "\n##################################################" >>$BASHRC
  fi
  copy_config bashrc
  ln -sf "$CONFIG/bashrc/bash_profile" "$HOME/.bash_profile"
  ln -sf "$CONFIG/bashrc/profile" "$HOME/.profile"
  ln -sf "$CONFIG/bashrc/bashrc" "$HOME/.bashrc"
  log_success BASHRC "Transfer complete."
  log_warning BASHRC "You may need to restart the terminal for config to apply"
}

main
