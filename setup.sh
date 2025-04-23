#!/bin/env bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

# Install Oh-My-Bash and import config
echo "Installing Oh-My-Bash"
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)"
rm $HOME/.bashrc
ln -s $SCRIPT_DIR/bashrc/.bashrc $HOME/.bashrc

# Install latest Neovim release and import config
echo "Installing Neovim"
source "$SCRIPT_DIR"/bin/install_nvim.sh

# Install Superfile and import config
echo "Installing Superfile"
bash -c "$(curl -sLo- https://superfile.netlify.app/install.sh)"
ln -s $SCRIPT_DIR/superfile/.config/superfile $HOME/.config/superfile

echo "Script is finished executing"
