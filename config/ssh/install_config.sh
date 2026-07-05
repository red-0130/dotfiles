#!/usr/bin/env bash

if ! source "$BIN/path_exist.sh"; then exit 1; fi

main() {
  local APP=ssh
  log -i "Applying SSH config"

  checkConfigFile() {
    local FILE="$HOME/.ssh/config"
    if [[ ! -e "$FILE" ]]; then
      log -w "Config file not found"
      log -i "Creating config file now"
      mkdir "$HOME/.ssh"
      touch "$FILE"
    else
      log -i "Config file found"
    fi
    return 0
  }

  appendIncludes() {
    local FILE="$HOME/.ssh/config"
    local INCLUDES="Include "$HOME"/.config/ssh/config"
    if ! grep "$INCLUDES" "$FILE"; then
      log -i "Appending config to config file"
      echo -e "$INCLUDES\n$(cat $FILE)" >"$FILE"
    fi
    return 0
  }

  checkConfigFile && appendIncludes && copy_config ssh
  log -s "Finished applying config."
}
main
