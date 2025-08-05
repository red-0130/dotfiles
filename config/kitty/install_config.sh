#!/usr/bin/env bash

if ! source "$BIN/path_exist.sh"; then exit 1; fi

main() {
  log_info kitty "Applying config..."
  if copy_config kitty; then
    log_success kitty "Successfully applied the config."
  fi
}
main
