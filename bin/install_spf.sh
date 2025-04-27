#!/bin/env bash

BACKUP_CONFIG=./backup_config.sh
main() {
  if command spf -v &>/dev/null; then exit 0; fi

  if [[ -L "$HOME/.config/superfile" ]]; then
    echo "Making backup of local config"
    source "$BIN/config_backup.sh" "superfile"
  fi

  if [[ ! -d $HOME/.config ]]; then
    mkdir "$HOME/.config"
  fi

  echo "Importing config"
  importConfig

  if installSpf; then
    echo "Finished installing Superfile and applying config."
  else
    echo "There was an error installing Superfile."
  fi

}

installSpf() {
  echo "Installing Superfile"
  bash -c "$(curl -sLo- https://superfile.netlify.app/install.sh)"
  ln -s "$SCRIPT_DIR/superfile/.config/superfile" "$HOME/.config/superfile"
  echo "Done."
}

importConfig() {
  if ! grep "source $HOME/.config/superfile/cd_on_quit.sh" "$HOME/.bashrc"; then
    echo "Importing cd_on_quit script from config"
    echo -e "\n#Superfile cd_on_quit script" >>"$HOME/.bashrc"
    echo "source $HOME/.config/superfile/cd_on_quit.sh" >>"$HOME/.bashrc"
  fi
}

main $@
exit
