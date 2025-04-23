#!/bin/env bash

main() {
  installLazyvimDependencies
  installNeovim
  echo "Making backup of current config."
}

installNeovim() {
  if ! command nvim -v &>/dev/null; then
    echo "Installing Neovim"
    curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
    sudo rm -rf /opt/nvim
    sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
    echo "Finished installing $(nvim -v | head -n 1)"
    echo "Cleaning up..."
    rm nvim-linux-x86_64.tar.gz
    echo "Done."
  else
    echo "Neovim is already installed"
  fi
  NVIM_PATH='export PATH="$PATH:/opt/nvim-linux-x86_64/bin"'
  if ! grep -q "$NVIM_PATH" "$HOME/.bashrc"; then
    echo "export PATH=\"$PATH:/opt/nvim-linux-x86_64/bin\"" >>"$HOME/.bashrc"
  fi
}

installLazyvimDependencies() {
  installLazygit
  installFzf
  installRipgrep
  installFd
}

installLazygit() {
  printf "Installing Lazygit\n"
  LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | \grep -Po '"tag_name": *"v\K[^"]*') &&
    curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz" &&
    tar xf lazygit.tar.gz lazygit
  sudo install lazygit -D -t /usr/local/bin/
  printf "Finished installing. Beginning cleanup...\n"
  rm lazygit*
  printf "Done.\n"
}

installFzf() {
  echo "Installing fzf"
  sudo apt install fzf
  echo "Done."
}

installRipgrep() {
  printf "Installing ripgrep"
  sudo apt install ripgrep
  printf "Done.\n"
}

installFd() {
  echo "Installing fd-find"
  sudo apt install fd-find
  echo "Done."
}

main $@
