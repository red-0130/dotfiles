#!/usr/bin/env bash

if ! source "$BIN/path_exist.sh"; then exit 1; fi

main() {
  source "$BIN/update_repo.sh"
  source "$BIN/multiselect.sh"
  startInteractive
}

startInteractive() {
  local APP=setup
  log -i "Starting interactive application install..."

  local choices
  choices=$(multiselect "DOTFILES Setup" "Select Applications to install" \
    "batcat" "A cat clone with wings" OFF \
    "bun" "Bun Package Manager" OFF \
    "eza" "A better ls" OFF \
    "fd" "A simple, fast and user-friendly alternative to 'find'" OFF \
    "flatpak" "Install Flatpak+FlatHub" OFF \
    "fzf" "A command-line fuzzy finder" OFF \
    "ghostty" "Fast and feature-rich terminal emulator" OFF \
    "git" "Latest version of git" OFF \
    "helium" "Private and secured chromium-based browser" OFF \
    "lazygit" "Simple terminal UI for git commands" OFF \
    "nvim" "Modular terminal text editor" OFF \
    "nvm" "Node Version Manager" OFF \
    "ripgrep" "ripgrep searches directories while respecting gitignore" OFF \
    "rust" "Install Rust and Cargo Package Manager" OFF \
    "starship" "Fast and customizable prompt shell" OFF \
    "superfile" "A Modern Terminal File Manager" OFF \
    "thorium" "The fastest browser on Earth" OFF \
    "treesitter" "An incremental parsing system for programming tools" OFF \
    "uv" "Extremely fast Python package installer and resolver" OFF \
    "wormhole" "A magical way to send files" OFF \
    "zellij" "A terminal workspace with batteries included" OFF \
  ) || {
    log -w "Installation cancelled."
    return 1
  }

  if [[ -z "$choices" ]]; then
    log -i "No apps selected."
    return 0
  fi

  local CHOICE
  for CHOICE in $choices; do
    source "$INSTALL/$CHOICE.sh"
  done

  log -s "Finished installing apps."
}

main
