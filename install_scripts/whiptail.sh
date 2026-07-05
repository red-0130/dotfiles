#!/bin/env bash

main() {
  local APP=setup
  if ! command -v whiptail &>/dev/null; then
    log -i "Whiptail is not installed. Starting installation now."

    if sudo apt install whiptail -y &>/dev/null; then
      echo "Done."
    else
      log -e "There was an error installing Whiptail."
      exit 1
    fi

  else
    log -i "Whiptail is installed. Proceeding to interactive script."
  fi
}

main
