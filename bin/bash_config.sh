#!/bin/env bash

main() {
  echo "Copying bash config into config directory"
  source "$BIN/config_apply.sh" "bashrc"

  if ! -L "$HOME/.config.bak"; then
    mkdir "$HOME/.config.bak"
  fi

  echo "Making backup of current bashrc config"
  mv "$HOME/.bashrc" "$HOME/.config.bak/bashrc/"
  mv "$HOME/.profile" "$HOME/.config.bak/bashrc/"

  echo "Applying bashrc file"
  ln -s "$ROOT_DIR/bashrc/.bashrc" "$HOME/.bashrc"
  ln -s "$ROOT_DIR/bashrc/.profile" "$HOME/.profile"
  echo "Transfer complete."
  echo "You may need to restart the terminal for config to apply"
}

main "$@"
