#!/usr/bin/env bash

if source "$BIN/path_exist.sh"; then return 0; else exit 1; fi

main() {
  log_info flatpak "Starting installation..."
  if sudo apt install flatpak -y; then
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    log_success flatpak "Successfully installed."
  else
    log_error flatpak "There was an error in installation."
  fi
  if command -v gnome-software &>/dev/null; then
    sudo apt install gnome-software-flatpak -y
  fi
}
main
