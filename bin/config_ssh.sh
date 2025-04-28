#!/bin/env bash

main() {
  local INCLUDES="Include "$HOME"/.config/ssh/config"
  local FILE="$HOME/.ssh/config"

  if [[ ! -z "$(grep "$INCLUDES" "$FILE")" ]]; then
    echo -e "$INCLUDES\n$(cat $FILE)" >"$FILE"
  fi

  applyConfig
}

applyConfig() {
  source "$BIN/config_apply.sh" "ssh"
}

main "$@"
