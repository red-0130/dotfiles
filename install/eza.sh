#!/usr/bin/env bash

if source $BIN/path_exist.sh; then return 0; else exit 1; fi

main() {
  log_info eza "Starting installation."
  if command -v eza &>/dev/null; then
    log_warning eza "Already installed."
  else
    sudo mkdir -p /etc/apt/keyrings
    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
    sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
    sudo apt update
    sudo apt install -y eza
    log_success eza "Finished installing."
    return 0
  fi
}
main
