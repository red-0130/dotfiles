#!/usr/bin/env bash

if ! source "$BIN/path_exist.sh"; then exit 1; fi

main() {
  log_info ssh "Applying SSH config"

  checkConfigFile() {
    local FILE="$HOME/.ssh/config"
    if [[ ! -e "$FILE" ]]; then
      log_warning SSH "Config file not found"
      log_info SSH "Creating config file now"
      mkdir "$HOME/.ssh"
      touch "$FILE"
    else
      log_info SSH "Config file found"
    fi
    return 0
  }

  appendIncludes() {
    local FILE="$HOME/.ssh/config"
    local INCLUDES="Include "$HOME"/.config/ssh/config"
    if ! grep "$INCLUDES" "$FILE"; then
      log_info ssh "Appending config to config file"
      echo -e "$INCLUDES\n$(cat $FILE)" >"$FILE"
    fi
    return 0
  }

  checkConfigFile && appendIncludes && copy_config ssh
  log_success ssh "Finished applying config."
}
main
