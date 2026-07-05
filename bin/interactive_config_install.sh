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
  log -i "Starting interactive script"
  whiptail --title "DOTFILES Setup" --separate-output --checklist "Select Config to apply" 25 78 16 \
    "bashrc" "Apply bashrc config" OFF \
    "fonts" "Copy font files" OFF \
    "ghostty" "Apply Ghostty Terminal config" OFF \
    "kitty" "Apply Kitty Terminal config" OFF \
    "mpv" "Apply MPV config" OFF \
    "nvim" "Apply Neovim config" OFF \
    "ssh" "Apply SSH config" OFF \
    "starship" "Append Starship init" OFF \
    "superfile" "Apply Superfile config" OFF \
    "zellij" "Apply Zellij config" OFF \
    3>&1 1>&2 2>&3 |
    while read CHOICE; do
      apply_config $CHOICE
    done

  log -s "Finished installing config"

}

main
