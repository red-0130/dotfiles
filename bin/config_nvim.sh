#!/bin/env bash

main() {
  echo "Applying custom Neovim config and plugins"
  source "$BIN/config_apply.sh" "nvim"
}

main "$@"
