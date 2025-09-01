#!/usr/bin/env bash
if ! source "$BIN/path_exist.sh"; then exit 1; fi

main() {
  log_info wormhole "Starting installation..."
  sudo apt install -y magic-wormhole &&
    log_success wormhole "Finished installing."
}

main
