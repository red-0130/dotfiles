#!/usr/bin/env bash

if ! source "$BIN/path_exist.sh"; then exit 1; fi
main() {
  source "$BIN/update_repo.sh"
  if source "$INSTALL/whiptail.sh"; then
    startInteractive
  fi
}
startInteractive() {
  log_info setup "Starting interactive App install..."
  whiptail --title "DOTFILES Setup" --separate-output --checklist "Select Config to apply" 25 78 16 \
    "eza" "A better ls" OFF \
    "flatpak" "Install Flatpak+FlatHub" OFF \
    "nvim" "Modular terminal text editor" OFF \
    "starship" "The minimal, blazing-fast, and infinitely customizable prompt for any shell!" OFF \
    "superfile" "A Modern Terminal File Manager" OFF \
    3>&1 1>&2 2>&3 |
    while read CHOICE; do
      source "$INSTALL/$CHOICE.sh"
    done

  log_success SETUP "Finished installing apps."
}
main
