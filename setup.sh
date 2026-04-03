#!/bin/env bash

main() {
  local APP="setup"
  local ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
  local BIN="$ROOT_DIR/bin"
  local INSTALL="$ROOT_DIR/install_scripts"
  local CONFIG="$ROOT_DIR/config"
  source "$BIN/log.sh"
  source "$BIN/backup.sh"
  source "$BIN/apply_config.sh"

  createBackupDirectory

  nonInteractive() {
    log -i "Starting config installation"
    log -i "Checking for config directory..."

    ! [ -d "$HOME/.config" ] && mkdir "$HOME/.config"

    # bashrc config
    apply_config "bashrc"

    # NVIM config
    apply_config "nvim"

    # SSH config
    apply_config "ssh"

    # Superfile config
    apply_config "superfile"

    # Git config
    apply_config "gitconfig"

    # Zellij config
    apply_config "zellij"

    log -i "Setup script end."

    exit 0
  }

  if [[ "$1" == "--config" ]] || [[ "$1" == "-c" ]]; then
    log -i "Starting interactive config install." -a "setup"
    source "$BIN/interactive_config_install.sh"
  elif [[ "$1" == "--app" ]] || [[ "$1" == "-a" ]]; then
    log -i "Starting interactive app install." -a "setup"
    source "$BIN/interactive_app_install.sh"
  else
    nonInteractive
  fi
}

main $@
