#!/usr/bin/env bash

main() {
  local STARSHIP='eval "$(starship init bash)"'
  backup starship "$HOME/.config/starship.toml"
  if ! grep "$STARSHIP"; then
    echo "#####################" >>"$HOME/.bashrc"
    echo "###STARSHIP INIT#####" >>"$HOME/.bashrc"
    echo "#####################" >>"$HOME/.bashrc"
    echo "$STARSHIP" >>"$HOME/.bashrc"
    echo "#####################" >>"$HOME/.bashrc"
  fi

  ln -sf $CONFIG/starship/config/starship.toml $HOME/.config/
}
main
