#!/usr/bin/env bash

if source $BIN/path_exist.sh; then return 0; else exit 1; fi

main() {
  log_info superfile "Starting installation."

  if bash -c "$(curl -sLo- https://superfile.netlify.app/install.sh)"; then
    log_success superfile "Finished installing."
  else
    log_error superfile "There was an error installing."
  fi
}

main
