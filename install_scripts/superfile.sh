#!/usr/bin/env bash

if ! source "$BIN/path_exist.sh"; then exit 1; fi

main() {
  log -i "Starting installation."

  if bash -c "$(curl -sLo- https://superfile.netlify.app/install.sh)"; then
    log -s "Finished installing."
  else
    log -e "There was an error installing."
  fi
}

main
