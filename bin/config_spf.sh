#!/bin/env bash

main() {
  echo "Applying Superfile config"
  if ! grep "source "$HOME/.config/superfile/cd_on_quit.sh"" "$HOME/.bashrc"; then
    echo "Importing cd_on_quit script from config"
    echo -e "\n#Superfile cd_on_quit script" >>"$HOME/.bashrc"
    echo "source \""$HOME"/.config/superfile/cd_on_quit.sh\"" >>"$HOME/.bashrc"
  fi
  echo "Importing Superfile config..."
  source "$BIN/config_apply.sh" "superfile"
  echo "Done"
}

main "$@"
