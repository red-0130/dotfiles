#!/usr/bin/env bash

if ! source "$BIN/path_exist.sh"; then exit 1; fi

main() {
  if ! command -v add-apt-repository &>/dev/null; then
    log_error git "The software-properties-common package is not installed. Exiting."
    return 1
  fi

  if sudo add-apt-repository ppa:git-core/ppa; then
    log_info git "Apt sources added. Starting installation..."
  else
    log_error git "Apt sources could not be added."
    return 1
  fi

  if sudo apt-get install -y git; then
    log_success git "Successfully installed."
    return 0
  else
    log_error git "There was an error installing."
    return 1
  fi
}

main
