#!/bin/env bash

SCRIPT_DIR=$(dirname "$0")

main() {
  transferBashrc
}

transferBashrc() {
  echo "Making backup of local bashrc and profile config"
  makeBackup "$HOME/.bashrc"
  makeBackup "$HOME/.profile"
  echo "Transferring bashrc and profile config"
  ln -s "$SCRIPT_DIR/bashrc/.bashrc" "$HOME/.bashrc"
  ln -s "$SCRIPT_DIR/bashrc/.profile" "$HOME/.profile"
  echo "Transfer complete."
  echo "You may need to restart the terminal for config to apply"
}

main "$@"
exit
