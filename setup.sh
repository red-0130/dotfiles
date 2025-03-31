#!/bin/env bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
if [[ "dpkg -s apt" ]]; then
  sudo apt update
fi
if ! [[ "sudo dpkg -s stow" ]]; then
  echo "Installing GNU Stow"
  sudo apt install stow
fi

if ! [[ "sudo dpkg -s whiptail" ]]; then
  sudo apt install whiptail
fi

# Install Oh-My-Bash and import config
echo "Installing Oh-My-Bash"
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)"
stow -R "$SCRIPT_DIR/bashrc"

# Install latest Neovim release and import config
echo "Installing Neovim"
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
sudo rm -rf /opt/nvim
sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
stow -R "$SCRIPT_DIR/nvim"

# Install Superfile and import config
echo "Installing Superfile"
bash -c "$(curl -sLo- https://superfile.netlify.app/install.sh)"
stow -R "$SCRIPT_DIR/superfile"

echo "Script is finished executing"
