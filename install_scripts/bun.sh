#!/usr/bin/env bash

main() {
  local APP="bun"
  log -i "Installing $APP..."
  if bash -c "$(curl -fsSL https://bun.com/install)"; then
    log -s "Finished installing."
  else
    log -e "There was an error installing."
  fi
}

main
