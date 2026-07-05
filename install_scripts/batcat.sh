#!/usr/bin/env bash
if ! source "$BIN/path_exist.sh"; then exit 1; fi

main() {
  local APP=batcat
  log -i "Starting installation..."
  if sudo apt install bat -y; then
    log -s "Finished installing."
  else
    log -e "There was an error in installation."
    return 1
  fi
}

main
