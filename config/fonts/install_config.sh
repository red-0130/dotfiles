#!/usr/bin/env bash

if ! source "$BIN/path_exist.sh"; then exit 1; fi
main() {
  local APP=fonts
  if [[ ! -d "$HOME/.local/share/fonts" ]]; then
    log -i "No fonts directory found. Creating one now..."
    mkdir -p "$HOME/.local/share/fonts"
  fi
  log -i "Copying font files..."
  cp -r "$CONFIG/fonts/font-files/" "$HOME/.local/share/fonts/"
  log -i "Creating cache..."
  fc-cache -f
  log -s "Done."
}
main
