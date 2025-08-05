#!/usr/bin/env bash

if ! source "$BIN/path_exist.sh"; then exit 1; fi

main() {
  log_info nvim "Applying Neovim config..."
  backup nvim "$HOME/.config/nvim"
  copy_config nvim
  log_success nvim "Finished applying Neovim config."
}
main
