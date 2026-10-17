#!/usr/bin/env bash
if ! source "$BIN/path_exist.sh"; then exit 1; fi

main() {
  log -i "Starting installation..."
  sudo apt install -y magic-wormhole &&
    log -s "Finished installing."
}

main
