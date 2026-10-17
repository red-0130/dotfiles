#!/usr/bin/env bash

if ! source "$BIN/path_exist.sh"; then exit 1; fi

main() {
  local APP=superfile
  backup superfile "$HOME/.config/superfile"
  log -i "Applying config..."
  if copy_config superfile; then
    log -s "Config applied successfully."
  else
    log -e "There was an error applying config."
  fi
}
main
