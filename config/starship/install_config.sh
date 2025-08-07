#!/usr/bin/env bash

main() {
  local STARSHIP='eval "$(starship init bash)"'
  if ! grep "$STARSHIP"; then
    echo "#####################" >>"$HOME/.bashrc"
    echo "###STARSHIP INIT#####" >>"$HOME/.bashrc"
    echo "#####################" >>"$HOME/.bashrc"
    echo "$STARSHIP" >>"$HOME/.bashrc"
    echo "#####################" >>"$HOME/.bashrc"
  fi

  if [[ ! -f "$HOME/.profile" ]] || [[ ! -L "$HOME/.profile" ]]; then
    echo 'if [[ -f "~/.bashrc" ]]; then' >>"$HOME/.profile"
    echo -e "\tsource ~/.bashrc" >>"$HOME/.profile"
    echo 'fi' >>"$HOME/.profile"
  fi
}
main
