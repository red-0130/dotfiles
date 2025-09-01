#!/usr/bin/env bash

if ! source "$BIN/path_exist.sh"; then exit 1; fi

main() {
  log_info ghostty "Starting installation..."
  if curl -fsSL https://raw.githubusercontent.com/mkasberg/ghostty-ubuntu/HEAD/install.sh | bash; then
    log_success ghostty "Successfully installed."
    return 0
  else
    log_error ghostty "There was an error installing."
    return 1
  fi
}

main
