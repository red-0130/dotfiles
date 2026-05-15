if ! source "$BIN/path_exist.sh"; then exit 1; fi

main() {
  local APP=neovim
  log -i "Installing Neovim"
  curl -LO --output-dir /tmp https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
  [[ -d /opt/nvim-linux-x86_64 ]] && sudo rm -rf /opt/nvim-linux-x86_64
  sudo tar -C /opt -xzf /tmp/nvim-linux-x86_64.tar.gz
  sudo ln -sf "/opt/nvim-linux-x86_64/bin/nvim" "/usr/local/bin/nvim" &&
    log -s "Finished installing $(nvim -v | head -n 1)"
  log -i "Cleaning up..."
  rm /tmp/nvim-linux-x86_64.tar.gz && log -i "Residual files removed."
}

main
