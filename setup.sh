#!/bin/env bash

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
BIN="$ROOT_DIR/bin"

nonInteractive() {

  # Install Oh-My-Bash and import config
  source "$BIN"/install_ohmybash.sh

  # Install latest Neovim release and import config
  source "$BIN"/install_nvim.sh

  # Install Superfile and import config
  source "$BIN"/install_spf.sh

  printf "Script is finished executing\n"

}

main() {
  # Update APT repo
  source "$BIN"/update_repo.sh

  if [[ "$1" == "int" ]]; then
    source "$BIN/start_interactive.sh"
  else
    nonInteractive
  fi
}

main $@
