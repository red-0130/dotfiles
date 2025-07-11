#!/bin/env bash

source $BIN/shell_logger.sh
main() {
  log_info bashrc "Installing Starship Prompt"
  install_starship && modify_config

  install_starship() {
    if sh <(curl -sS https://starship.rs/install.sh) --yes; then
      log_success bashrc "Starship Prompt installed successfully."
      return 0
    else
      log_error bashrc "There was an error installing Starship."
      return 1
    fi
  }
  modify_config() {
    if starship preset bracketed-segments -o ~/.config/starship/starship.toml; then
      log_success bashrc "Starship was successfully configured."
      return 0
    else
      log_error bashrc "There was an error changing Starship configuration."
      return 1
    fi
  }

  log_info bashrc "Starship installation script finished."

}

if command -v starship &>/dev/null; then
  log_warning bashrc "Starship is already installed. Skipping installation."
else
  main
fi
