#!/bin/env bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
checkApt
installWhiptail

whiptail --title "Which config do you want to install?" --checklist --separate-output \
  "bashrc" "bashrc config" OFF \
  "nvim" "Install Neovim and apply configuration" OFF \
  "kitty" "Kitty terminal configuration" OFF \
  "mpv" "MPV config" OFF \
  "superfile" "Superfile config" OFF \
  "fonts" "Install fonts" OFF \
  "gitconfig" "Git config" OFF \
  "ssh" "SSH config" OFF \
  3>&1 1>&2 2>&3 |
  while read CHOICE; do
    CONFIG_MAIN="$SCRIPT_DIR/$CHOICE"
    CONFIG_LOCAL="$HOME/.config/$CHOICE"

    if [[ "$CHOICE" -eq "bashrc" ]]; then
      echo "bashrc configuration require the installation of 'ohmybash'."
      echo "Installing Oh-My-Bash"
      bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)"
    fi

    if [[ "$CHOICE" -eq "fonts" ]]; then
      echo "Installing fonts"
      fc-cache -v $HOME/.local/share/fonts
    fi

    if [[ "$CHOICE" -eq "nvim" ]]; then
      installNeovim
      applyConfig "$CONFIG_MAIN/.config/$CHOICE" "$CONFIG_LOCAL"
    fi

    if [[ "$CHOICE" -eq "superfile" ]]; then
      echo "Installing Superfile"
      bash -c "$(curl -sLo- https://superfile.netlify.app/install.sh)"
    fi

    if [[ "$CHOICE" -eq "ssh" ]]; then
      appendSshConfig

    fi

  done

echo "Finished installing config"

checkApt() {
  if ! sudo dpkg -s apt &>/dev/null; then
    exit 0
  else
    sudo apt update
    sudo apt full-upgrade
    exit 1
  fi
}

installWhiptail() {
  if ! sudo dpkg -s whiptail &>/null/dev; then
    echo "Whiptail is not installed. Starting installation now."
    sudo apt install whiptail
    echo "Done."
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
  ln -sf "$CONFIG" "$CONFIG_DES"
  echo "Finished applying config."
}

makeBackup() {
  BACKUP_DIR="$HOME/.config.bak"
  EXISTING_CONFIG=$1
  if [[ ! -d "$BACKUP_DIR" ]]; then
    echo "Backup directory not detected."
    echo "Creating backup directory now."
    mkdir "$BACKUP_DIR"
  fi
  echo "Moving existing configuration to backup directory($BACKUP_DIR)"
  mv "$EXISTING_CONFIG" "$BACKUP_DIR"
}

appendSshConfig() {
  INCLUDES="Include "$HOME"/.config/ssh/config"
  FILE="$HOME/.ssh/config"
  if [[ ! -z "$(grep "$INCLUDES" "$FILE")" ]]; then
    echo -e "$INCLUDES\n$(cat $FILE)" >"$FILE"
  fi
}

installNeovim() {
  echo "Installing Neovim"
  curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
  sudo rm -rf /opt/nvim
  sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
  echo "Finished installing $(nvim -v | head -n 1)"
  echo "Cleaning up..."
  rm nvim-linux-x86_64.tar.gz
  echo "Done."
}

installLazyvimDependencies() {
  installLazygit
  installFzf
  installRipgrep
  installFd
}

installLazygit() {
  echo "Installing Lazygit"
  LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | \grep -Po '"tag_name": *"v\K[^"]*')
  curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
  tar xf lazygit.tar.gz lazygit
  sudo install lazygit -D -t /usr/local/bin/
  echo "Finished installing. Beginning cleanup..."
  rm lazygit*
  echo "Done."
}

installFzf() {
  echo "Installing fzf"
  sudo apt install fzf
  echo "Done."
}

installRipgrep() {
  echo "Installing Ripgrep"
  sudo apt install ripgrep
  echo "Done."
}

installFd() {
  echo "Installing fd-find"
  sudo apt install fd-find
  echo "Done."
}
