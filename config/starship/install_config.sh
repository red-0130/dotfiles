#!/usr/bin/env bash

main() {
  local STARSHIP='eval "$(starship init bash)"'
  backup starship "$HOME/.config/starship.toml"
  if ! grep "$STARSHIP" "$HOME/.bashrc"; then
    log_info starship "Appending Starship startup in bashrc."
    echo "#####################" >>"$HOME/.bashrc"
    echo "###STARSHIP INIT#####" >>"$HOME/.bashrc"
    echo "#####################" >>"$HOME/.bashrc"
    echo "$STARSHIP" >>"$HOME/.bashrc"
    echo "#####################" >>"$HOME/.bashrc"
    log_success starship "Bashrc config updated."
  fi
  if command -v starship &>/dev/null; then
    log_info starship "Importing Starship config..."
    if ln -sf $CONFIG/starship/config/starship.toml $HOME/.config/; then
      log_success starship "Config imported."
    else
      log_error starship "Config was not imported."
    fi
  fi
}
main
