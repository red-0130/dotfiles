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
    "batcat" "A cat clone with wings" OFF \
    "eza" "A better ls" OFF \
    "flatpak" "Install Flatpak+FlatHub" OFF \
    "ghostty" "Fast and feature-rich terminal emulator" OFF \
    "git" "Latest version of git" OFF \
    "nvim" "Modular terminal text editor" OFF \
    "nvm" "Node Version Manager" OFF \
    "rust" "Install Rust and Cargo Package Manager" OFF \
    "starship" "Fast and customizable prompt shell" OFF \
    "superfile" "A Modern Terminal File Manager" OFF \
    "thorium" "The fastest browser on Earth" OFF \
    "wormhole" "A magical way to send files" OFF \
    3>&1 1>&2 2>&3 |
    while read CHOICE; do
      source "$INSTALL/$CHOICE.sh"
    done

  log_success SETUP "Finished installing apps."
}
main
