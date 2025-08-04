#!/usr/bin/env bash
if source $BIN/path_exist.sh; then return 0; else exit 1; fi

apply_config() {
  local APP="$1"
  shift

  source "$CONFIG/$APP/install_config.sh"
}
