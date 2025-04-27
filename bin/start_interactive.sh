#!/bin/env bash

main() {
  if source "$BIN/install_whiptail.sh"; then
    startInteractive
  fi
}

startInteractive() {
  echo "Starting interactve script"
  whiptail --title "DOTFILES Setup" --separate-output \
    --checklist "Select Application/Config to apply" 20 60 10 \
    "nvim" "Install Neovim" OFF \
    "nvim-config" "Apply Neovim config" OFF \
    "superfile" "Superfile config" OFF \
    "ohmybash" "Install Oh-My-Bash" OFF \
    "bashrc" "Apply bashrc config" OFF \
    3>&1 1>&2 2>&3 |
    while read CHOICE; do
      CONFIG_MAIN="$ROOT_DIR/$CHOICE"
      CONFIG_LOCAL="$HOME/.config/$CHOICE"

      case "$CHOICE" in
      "ohmybash")
        source "$BIN/install_ohmybash.sh"
        ;;
      "bashrc")
        source "$BIN/bash_config.sh"
        ;;
      "superfile")
        source "$BIN/install_spf.sh"
        ;;
      "nvim")
        source "$BIN/install_nvim.sh"
        ;;
      "nvim-config")
        source "$BIN/config_nvim.sh"
        ;;
      *)
        echo default
        ;;
      esac

      if [[ "$CHOICE" = "fonts" ]]; then
        echo "Installing fonts"
        fc-cache -v $HOME/.local/share/fonts
      fi

    done

  echo "Finished installing config"

}

main "$@"
exit
