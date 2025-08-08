#!/usr/bin/env bash

if ! source "$BIN/path_exist.sh"; then exit 1; fi

main() {
  backup superfile "$HOME/.config/superfile"
  log_info superfile "Applying config..."
  if copy_config superfile; then
    log_success superfile "Config applied successfully."
  else
    log_error superfile "There was an error applying config."
  fi
}
main
