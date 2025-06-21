#!/bin/env bash

nonInteractive() {

  # Apply bashrc config
  source "$BIN"/bash_config.sh
  bash_config

  # Install latest Neovim release and import config
  source "$BIN"/config_nvim.sh

  # Apply Superfile config
  source "$BIN"/config_spf.sh

  # Apply SSH config
  source "$BIN"/config_ssh.sh

  printf "Script is finished executing\n"

}

main() {
  local ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
  local BIN="$ROOT_DIR/bin"
  source "$BIN/message.sh"
  source "$BIN/shell_logger.sh"

  if [[ "$1" == "-i" ]]; then
    # Update APT repo
    source "$BIN"/update_repo.sh
    source "$BIN/start_interactive.sh"
  else
    nonInteractive
  fi
}

main $@
