#!/bin/env bash

main() {
  INCLUDES="Include "$HOME"/.config/ssh/config"
  FILE="$HOME/.ssh/config"
  if [[ ! -z "$(grep "$INCLUDES" "$FILE")" ]]; then
    echo -e "$INCLUDES\n$(cat $FILE)" >"$FILE"
  fi
}

main "$@"
exit
