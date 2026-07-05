#!/usr/bin/env bash

if ! source "$BIN/path_exist.sh"; then exit 1; fi

main() {
  local APP=kitty
  backup kitty "$HOME/.config/kitty"
  log -i "Applying config..."
  if copy_config kitty; then
    log -s "Successfully applied the config."
  fi
}
main
