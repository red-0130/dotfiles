#!/usr/bin/env bash

if ! source "$BIN/path_exist.sh"; then exit 1; fi

main() {
  source "$BIN/multiselect.sh"
  startInteractive
}

startInteractive() {
  local APP=setup
  log -i "Starting interactive configuration install..."

  local choices
  choices=$(multiselect "DOTFILES Setup" "Select Configurations to apply" \
    "bashrc" "Apply bashrc config" OFF \
    "fonts" "Copy font files" OFF \
    "ghostty" "Apply Ghostty Terminal config" OFF \
    "gitconfig" "Apply Git config" OFF \
    "kitty" "Apply Kitty Terminal config" OFF \
    "mpv" "Apply MPV config" OFF \
    "nvim" "Apply Neovim config" OFF \
    "ssh" "Apply SSH config" OFF \
    "starship" "Append Starship init" OFF \
    "superfile" "Apply Superfile config" OFF \
    "zellij" "Apply Zellij config" OFF \
  ) || {
    log -w "Installation cancelled."
    return 1
  }

  if [[ -z "$choices" ]]; then
    log -i "No configurations selected."
    return 0
  fi

  local CHOICE
  for CHOICE in $choices; do
    apply_config "$CHOICE"
  done

  log -s "Finished installing configurations."
}

main
