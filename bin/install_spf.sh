#!/bin/env bash

BACKUP_CONFIG=./backup_config.sh
main() {

  if [[ ! -d $HOME/.config ]]; then
    mkdir "$HOME/.config"
  fi

  if command spf -v &>/dev/null; then
    echo "Superfile is already installed"
  else
    installSpf
  fi
  echo "Importing config"
  source "$BIN/config_spf.sh"

}

installSpf() {
  echo "Installing Superfile"
  if bash -c "$(curl -sLo- https://superfile.netlify.app/install.sh)"; then
    echo "Finished installing Superfile and applying config."
  else
    echo "There was an error installing Superfile."
  fi
  echo "Done."
}

main $@
exit
