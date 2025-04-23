#!/bin/env bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

# Update APT repo
printf "Updating APT repo\n"
sudo apt update &>/dev/null

# Install Oh-My-Bash and import config
printf "Installing Oh-My-Bash\n"
source "$SCRIPT_DIR"/bin/install_ohmybash.sh

# Install latest Neovim release and import config
printf "Installing Neovim\n"
source "$SCRIPT_DIR"/bin/install_nvim.sh

# Install Superfile and import config
printf "Installing Superfile\n"
source "$SCRIPT_DIR"/bin/install_spf.sh

printf "Script is finished executing\n"
