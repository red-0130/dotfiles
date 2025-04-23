#!/bin/env bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

main() {
  checkApt
  if installWhiptail; then
    startInteractive
  fi
}

startInteractive() {
  echo "Starting interactve script"
  whiptail --title "DOTFILES Setup" --separate-output \
    --checklist "Select Application/Config to apply" 20 60 10 \
    "nvim" "Install Neovim and apply configuration" OFF \
    "superfile" "Superfile config" OFF \
    "ohmybash" "Install Oh-My-Bash" OFF \
    "bashrc" "Apply bashrc config" OFF \
    3>&1 1>&2 2>&3 |
    while read CHOICE; do
      CONFIG_MAIN="$SCRIPT_DIR/$CHOICE"
      CONFIG_LOCAL="$HOME/.config/$CHOICE"
      BIN="$SCRIPT_DIR/bin"

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
      *)
        echo default
        ;;
      esac

      if [[ "$CHOICE" = "fonts" ]]; then
        echo "Installing fonts"
        fc-cache -v $HOME/.local/share/fonts
      fi

      if [[ "$CHOICE" = "nvim" ]]; then
        # installLazyvimDependencies
        # installNeovim
        applyConfig "$CONFIG_MAIN/.config/$CHOICE" "$CONFIG_LOCAL"
      fi

      if [[ "$CHOICE" = "ssh" ]]; then
        source "$BIN/config_ssh.sh"

      fi

    done

  echo "Finished installing config"

}

checkApt() {
  if ! sudo dpkg -s apt &>/dev/null; then
    echo "ERROR: APT is not installed."
    exit 0
  else
    echo "Updating apt repositories"
    sudo apt update
    echo "Proceeding with system upgrade."
    sudo apt full-upgrade -y
  fi
}

installWhiptail() {
  if ! sudo dpkg -s whiptail &>/dev/null; then
    echo "Whiptail is not installed. Starting installation now."
    sudo apt install whiptail -y
    echo "Done."
  else
    echo "Whiptail is installed. Proceeding to interactive script."
  fi
}

applyConfig() {
  # @param {directory to be applied} $1
  # @param {directory on local} $2
  echo "Applying config from repo..."
  CONFIG="$1"
  CONFIG_DES="$2"
  if [[ -e "$CONFIG_DES" ]]; then
    makeBackup $CONFIG_DES
  fi
  if [[ ! -d "$HOME/.config" ]]; then
    mkdir "$HOME/.config"
  fi
  ln -sf "$CONFIG" "$CONFIG_DES"
  echo "Finished applying config."
}

main "$@"
exit
