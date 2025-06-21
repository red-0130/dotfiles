#!/bin/env bash

main() {
  local ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
  local BIN="$ROOT_DIR/bin"
  source "$BIN/message.sh"
  source "$BIN/shell_logger.sh"

  nonInteractive() {
    log_info setup "Starting non-interactive setup script."

    # Apply bashrc config
    source "$BIN"/bash_config.sh
    bash_config

    # Install latest Neovim release and import config
    source "$BIN"/config_nvim.sh

    # Apply Superfile config
    source "$BIN"/config_spf.sh

    # Apply SSH config
    source "$BIN"/config_ssh.sh

    log_success setup "Script is finished executing"

  }

  if [[ "$1" == "-i" ]]; then
    # Update APT repo
    source "$BIN"/update_repo.sh
    source "$BIN/start_interactive.sh"
  else
    nonInteractive
  fi
}

main $@
