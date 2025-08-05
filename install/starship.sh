#!/usr/bin/env bash

if ! source "$BIN/path_exist.sh"; then exit 1; fi

main() {
  log_info starship "Installing Starship Prompt"
  install_starship && modify_theme &&
    log_info starship "Starship installation script finished."

  install_starship() {
    if bash -c "$(curl -sSLO- https://starship.rs/install.sh) --yes"; then
      log_success starship "Finished installing."
      return 0
    else
      log_error starship "There was an error in installation."
      return 1
    fi
  }
  modify_theme() {
    if starship preset bracketed-segments -o ~/.config/starship.toml; then
      log_success bashrc "Starship was successfully configured."
      return 0
    else
      log_error bashrc "There was an error changing Starship configuration."
      return 1
    fi
  }

}

if command -v starship &>/dev/null; then
  log_warning bashrc "Starship is already installed. Skipping installation."
else
  main
fi
