#!/usr/bin/env bash
if ! source "$BIN/path_exist.sh"; then exit 1; fi

main() {
  log_info batcat "Starting installation..."
  if sudo apt install bat -y; then
    log_success batcat "Finished installing."
  else
    log_error batcat "There was an error in installation."
    return 1
  fi
}

main
