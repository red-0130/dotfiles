#!/bin/env bash

if ! sudo command -v whiptail &>/dev/null; then
  echo "Whiptail is not installed. Starting installation now."

  if sudo apt install whiptail -y &>/dev/null; then
    echo "Done."
  else
    printf "There was an error installing Whiptail\n"
    exit 1
  fi

else
  echo "Whiptail is installed. Proceeding to interactive script."
fi
