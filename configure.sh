#!/bin/env bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
if [[ dpkg -s apt ]]; then
  sudo apt update
fi
if ! [[ "sudo dpkg -s stow" ]]; then
  echo "Installing GNU Stow"
  sudo apt install stow
fi

if ! [[ "sudo dpkg -s whiptail" ]]; then
  sudo apt install whiptail
fi

whiptail --title "Which config do you want to install?" --checklist --separate-output \
  "bashrc" "bashrc config" OFF \
  "nvim" "Neovim configuration and application" OFF \
  "kitty" "Kitty terminal configuration" OFF \
  "mpv" "MPV config" OFF \
  "superfile" "Superfile config" OFF \
  "fonts" "Install fonts" OFF \
  "gitconfig" "Git config" OFF \
  "ssh" "SSH config" OFF \
  3>&1 1>&2 2>&3 |
  while read choice; do
    if [[ "$choice" -eq "bashrc" ]]; then
      echo "Installing Oh-My-Bash"
      bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)"
    fi

    if [[ "sudo dpkg -s stow" ]]; then
      stow -R "$SCRIPT_DIR/$choice"
    fi

    if [[ "$choice" -eq "fonts" ]]; then
      echo "Installing fonts"
      fc-cache -v $HOME/.local/share/fonts
    fi

    if [[ "$choice" -eq "nvim" ]]; then
      echo "Installing Neovim"
      curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
      sudo rm -rf /opt/nvim
      sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
    fi

    if [[ "$choice" -eq "superfile" ]]; then
      echo "Installing Superfile"
      bash -c "$(curl -sLo- https://superfile.netlify.app/install.sh)"
    fi

  done
