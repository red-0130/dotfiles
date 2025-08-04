#!/usr/bin/env bash

if source "$BIN/path_exist.sh"; then return 0; else exit 1; fi
main() {
  source "$BIN/update_repo.sh"
  if source "$INSTALL/whiptail.sh"; then
    startInteractive
  fi
}

startInteractive() {
  log_info setup "Starting interactive script"
  whiptail --title "DOTFILES Setup" --separate-output \ --checklist "Select Config to apply" 25 78 16 \
    "bashrc" "Apply bashrc config" OFF \
    "fonts" "Copy font files" OFF \
    "ghostty" "Apply Ghostty Terminal config" OFF \
    "kitty" "Apply Kitty Terminal config" \
    "mpv" "Apply MPV config" OFF \
    "nvim" "Apply Neovim config" OFF \
    "ssh" "Apply SSH config" OFF \
    "superfile" "Apply Superfile config" OFF \
    3>&1 1>&2 2>&3 |
    while read CHOICE; do
      apply_config "$CHOICE"
    done

  log_success SETUP "Finished installing config"

}

main "$@"
exit
