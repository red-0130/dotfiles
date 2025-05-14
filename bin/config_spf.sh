#!/bin/env bash

main() {
  echo "Applying Superfile config"
  if checkImports && checkIfLink ; then
    echo "Importing cd_on_quit script from config"
    echo -e "\n#Superfile cd_on_quit script" >>"$HOME/.bashrc"
    echo "source \""$HOME"/.config/superfile/cd_on_quit.sh\"" >>"$HOME/.bashrc"
  fi
  echo "Importing Superfile config..."
  source "$BIN/config_apply.sh" "superfile"
  echo "Done"
}

checkImports() {
  if grep "source "$HOME/.config/superfile/cd_on_quit.sh"" "$HOME/.bashrc"; then
    return 1
  else
    return 0
  fi
}

checkIfLink() {
  if [[ -L "$HOME/.bashrc" ]]; then
    echo "bashrc file is a symbolic link."
    return 1 
  else
    return 0
  fi
}

main "$@"
