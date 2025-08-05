#!/usr/bin/env bash
if ! source "$BIN/path_exist.sh"; then exit 1; fi

apply_config() {
  local APP="$1"
  shift

  source "$CONFIG/$APP/install_config.sh"
}
