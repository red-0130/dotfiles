#!/bin/env bash

main() {
  local ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
  local BIN="$ROOT_DIR/bin"
  local INSTALL="$ROOT_DIR/install_scripts"
  local CONFIG="$ROOT_DIR/config"
  source "$BIN/shell_logger.sh"
  source "$BIN/backup.sh"
  source "$BIN/copy_config.sh"
  source "$BIN/apply_config.sh"

  nonInteractive() {
    log_info setup "Starting config installation"

    # bashrc config
    source "$CONFIG/bashrc/install_config.sh"

    # NVIM config
    source "$CONFIG/nvim/install_config.sh"

    # SSH config
    source "$CONFIG/ssh/install_config.sh"

    # Superfile config
    source "$CONFIG/superfile/install_config.sh"

    # Starship config
    source "$CONFIG/starship/install_config.sh"

    log_info setup "Setup script end."
    exit 0
  }

  if [[ "$1" == "--config" ]] || [[ "$1" == "-c" ]]; then
    log_info config "Starting interactive config install."
    source "$BIN/interactive_config_install.sh"
  elif [[ "$1" == "--app" ]] || [[ "$1" == "-a" ]]; then
    log_info app "Starting interactive app install."
    source "$BIN/interactive_app_install.sh"
  else
    nonInteractive
  fi
}

main $@
