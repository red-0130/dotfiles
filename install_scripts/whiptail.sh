#!/bin/env bash

if ! command -v whiptail &>/dev/null; then
  log_info setup "Whiptail is not installed. Starting installation now."

  if sudo apt install whiptail -y &>/dev/null; then
    echo "Done."
  else
    log_error "There was an error installing Whiptail."
    exit 1
  fi

else
  log_info setup "Whiptail is installed. Proceeding to interactive script."
fi
