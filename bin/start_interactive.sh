#!/bin/env bash

main() {
  source "$BIN/message.sh"
  if source "$BIN/install_whiptail.sh"; then
    startInteractive
  fi
}

startInteractive() {
  message info INTERACTIVE "Starting interactive script"
  whiptail --title "DOTFILES Setup" --separate-output \
    --checklist "Select Application/Config to apply" 25 78 16 \
    "nvim" "Install Neovim" OFF \
    "nvim-config" "Apply Neovim config" OFF \
    "ssh" "Apply ssh config" OFF \
    "superfile" "Superfile config" OFF \
    "ohmybash" "Install Oh-My-Bash" OFF \
    "starship" "Install Starship Prompt" OFF \
    "bashrc" "Apply bashrc config" OFF \
    3>&1 1>&2 2>&3 |
    while read CHOICE; do
      CONFIG_MAIN="$ROOT_DIR/$CHOICE"
      CONFIG_LOCAL="$HOME/.config/$CHOICE"

      case "$CHOICE" in
      "ohmybash")
        source "$BIN/install_ohmybash.sh"
        ;;
      "starship")
        source "$BIN/install_starship.sh"
        ;;
      "bashrc")
        source "$BIN/bash_config.sh"
        bash_config
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
      "ssh")
        source "$BIN/config_ssh.sh"
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

  log_success SETUP "Finished installing config"

}

main "$@"
exit
