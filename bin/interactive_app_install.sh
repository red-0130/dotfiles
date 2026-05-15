#!/usr/bin/env bash

if ! source "$BIN/path_exist.sh"; then exit 1; fi
main() {
  source "$BIN/update_repo.sh"
  if source "$INSTALL/whiptail.sh"; then
    startInteractive
  fi
}
startInteractive() {
  local APP=setup
  log -i "Starting interactive App install..."
  whiptail --title "DOTFILES Setup" --separate-output --checklist "Select Config to apply" 25 78 16 \
    "batcat" "A cat clone with wings" OFF \
    "bun" "Bun Package Manager" OFF \
    "eza" "A better ls" OFF \
    "fd" "A simple, fast and user-friendly alternative to 'find'" OFF \
    "flatpak" "Install Flatpak+FlatHub" OFF \
    "fzf" "A command-line fuzzy finder" OFF \
    "ghostty" "Fast and feature-rich terminal emulator" OFF \
    "git" "Latest version of git" OFF \
    "lazygit" "Simple terminal UI for git commands" OFF \
    "nvim" "Modular terminal text editor" OFF \
    "nvm" "Node Version Manager" OFF \
    "ripgrep" "ripgrep recursively searches directories for a regex pattern while respecting your gitignore" OFF \
    "rust" "Install Rust and Cargo Package Manager" OFF \
    "starship" "Fast and customizable prompt shell" OFF \
    "superfile" "A Modern Terminal File Manager" OFF \
    "thorium" "The fastest browser on Earth" OFF \
    "treesitter" "An incremental parsing system for programming tools" OFF \
    "wormhole" "A magical way to send files" OFF \
    "zellij" "A terminal workspace with batteries included" OFF \
    3>&1 1>&2 2>&3 |
    while read CHOICE; do
      source "$INSTALL/$CHOICE.sh"
    done

  log -s "Finished installing apps."
}
main
