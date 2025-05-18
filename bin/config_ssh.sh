#!/bin/env bash
main() {
  source "$BIN/message.sh"
  checkConfigFile && applyConfig && appendIncludes && addScript
}

checkConfigFile() {
  local FILE="$HOME/.ssh/config"
  if [[ ! -e "$FILE" ]]; then
    message warning SSH "Config file not found"
    message info SSH "Creating config file now"
    mkdir "$HOME/.ssh"
    touch "$FILE"
  else
    message info SSH "Config file found"
  fi
  return 0
}

appendIncludes() {
  local FILE="$HOME/.ssh/config"
  local INCLUDES="Include "$HOME"/.config/ssh/config"
  if ! grep "$INCLUDES" "$FILE"; then
    message info SSH "Appending config to config file"
    echo -e "$INCLUDES\n$(cat $FILE)" >"$FILE"
  fi
  return 0
}
applyConfig() {
  message info SSH "Copying config files..."
  if source "$BIN/config_apply.sh" "ssh"; then
    message success SSH "Config file copy was succesful"
    return 0
  else
    message error SSH "There was an error in copying config files"
    return 1
  fi
}

addScript() {
  if [[ ! -d "$HOME/.local/bin" ]]; then
    message info SSH "User bin directory does not exist and will be created"
    mkdir -p "$HOME/.local/bin"
  fi
  if ln -sf "$ROOT_DIR/ssh/bin/onsubnet" "$HOME/.local/bin/onsubnet"; then
    message success SSH "onsubnet script was successfully added"
    return 0
  else
    message error SSH "There was an error adding onsubnet script"
    return 1
  fi
}

main "$@"
