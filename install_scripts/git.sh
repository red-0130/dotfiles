#!/usr/bin/env bash

if ! source "$BIN/path_exist.sh"; then exit 1; fi

main() {
  local APP=git
  if ! command -v add-apt-repository &>/dev/null; then
    log -e "The software-properties-common package is not installed. Exiting."
    return 1
  fi

  if sudo add-apt-repository ppa:git-core/ppa; then
    log -i "Apt sources added. Starting installation..."
  else
    log -e "Apt sources could not be added."
    return 1
  fi

  if sudo apt-get install -y git; then
    log -s "Successfully installed."
    return 0
  else
    log -e "There was an error installing."
    return 1
  fi
}

main
