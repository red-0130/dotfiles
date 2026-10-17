#!/usr/bin/env bash

main() {
  local STARSHIP='eval "$(starship init bash)"'
  backup starship "$HOME/.config/starship.toml"
  if ! grep "$STARSHIP" "$HOME/.bashrc"; then
    log -i "Appending Starship startup in bashrc."
    echo "#####################" >>"$HOME/.bashrc"
    echo "###STARSHIP INIT#####" >>"$HOME/.bashrc"
    echo "#####################" >>"$HOME/.bashrc"
    echo "$STARSHIP" >>"$HOME/.bashrc"
    echo "#####################" >>"$HOME/.bashrc"
    log -s "Bashrc config updated."
  fi
  if command -v starship &>/dev/null; then
    log -i "Importing Starship config..."
    if ln -sf $CONFIG/starship/config/starship.toml $HOME/.config/; then
      log -s "Config imported."
    else
      log -e "Config was not imported."
    fi
  fi
}
main
