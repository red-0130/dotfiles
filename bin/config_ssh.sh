#!/bin/env bash

main() {
  local INCLUDES="Include "$HOME"/.config/ssh/config"
  local FILE="$HOME/.ssh/config"

  if [[ ! -z "$(grep "$INCLUDES" "$FILE")" ]]; then
    echo -e "$INCLUDES\n$(cat $FILE)" >"$FILE"
  fi

  applyConfig

  if addScript; then
    echo "SSH script added"
  else
    echo "There was an error adding the SSH script"
  fi
}

applyConfig() {
  source "$BIN/config_apply.sh" "ssh"
}

addScript() {
  if [[ ! -d "$HOME/.local/bin" ]]; then
    mkdir -p "$HOME/.local/bin"
  fi
  if ln -sf "$ROOT_DIR/ssh/bin/onsubnet" "$HOME/.local/bin/onsubnet"; then
    return 0
  else
    return 1
  fi
}

main "$@"
