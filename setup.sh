#!/bin/env bash

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
BIN="$ROOT_DIR/bin"

nonInteractive() {

  # Apply bashrc config
  source "$BIN"/bash_config.sh

  # Install latest Neovim release and import config
  source "$BIN"/config_nvim.sh

  # Apply Superfile config
  source "$BIN"/config_spf.sh

  printf "Script is finished executing\n"

}

main() {

  if [[ "$1" == "-i" ]]; then
    # Update APT repo
    source "$BIN"/update_repo.sh
    source "$BIN/start_interactive.sh"
  else
    nonInteractive
  fi
}

main $@
