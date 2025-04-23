#!/bin/env bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

# Update APT repo
printf "Updating APT repo\n"
sudo apt update &>/dev/null

# Install Oh-My-Bash and import config
printf "Installing Oh-My-Bash\n"
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)"
rm $HOME/.bashrc
ln -s $SCRIPT_DIR/bashrc/.bashrc $HOME/.bashrc

# Install latest Neovim release and import config
printf "Installing Neovim\n"
source "$SCRIPT_DIR"/bin/install_nvim.sh

# Install Superfile and import config
printf "Installing Superfile\n"
bash -c "$(curl -sLo- https://superfile.netlify.app/install.sh)"
ln -s $SCRIPT_DIR/superfile/.config/superfile $HOME/.config/superfile

printf "Script is finished executing\n"
