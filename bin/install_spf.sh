#!/bin/env bash

BACKUP_CONFIG=./backup_config.sh
main() {
  if command spf -v &>/dev/null; then exit 0; fi

  if [[ ! -d $HOME/.config ]]; then
    mkdir "$HOME/.config"
  fi

  if installSpf; then
    echo "Finished installing Superfile and applying config."
    echo "Importing config"
    source "$BIN/config_spf.sh"
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

main $@
exit
