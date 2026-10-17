#!/usr/bin/env bash

if ! source "$BIN/path_exist.sh"; then exit 1; fi

main() {
  local APP=starship

  install_starship() {
    if curl -sS https://starship.rs/install.sh | sh -s -- --yes; then
      log -s "Finished installing."
      return 0
    else
      log -e "There was an error in installation."
      return 1
    fi
  }
  modify_theme() {
    if starship preset bracketed-segments -o ~/.config/starship.toml; then
      log -s "Starship was successfully configured."
      return 0
    else
      log -e "There was an error changing Starship configuration."
      return 1
    fi
  }

  log -i "Installing Starship Prompt"
  install_starship && modify_theme &&
    log -i "Starship installation script finished."

}

if command -v starship &>/dev/null; then
  log -w "Starship is already installed. Skipping installation."
else
  main
fi
