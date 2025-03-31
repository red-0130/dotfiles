#!/bin/env bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

# Install Oh-My-Bash and import config
echo "Installing Oh-My-Bash"
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)"
rm $HOME/.bashrc
ln -s $SCRIPT_DIR/bashrc/.bashrc $HOME/.bashrc

# Install latest Neovim release and import config
echo "Installing Neovim"
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
sudo rm -rf /opt/nvim
sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
ln -s $SCRIPT_DIR/nvim/.config/nvim $HOME/.config/nvim

# Install Superfile and import config
echo "Installing Superfile"
bash -c "$(curl -sLo- https://superfile.netlify.app/install.sh)"
ln -s $SCRIPT_DIR/superfile/.config/superfile $HOME/.config/superfile

echo "Script is finished executing"
