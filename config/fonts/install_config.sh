#!/usr/bin/env bash

if ! source "$BIN/path_exist.sh"; then exit 1; fi
main() {
  if [[ ! -d "$HOME/.local/share/fonts" ]]; then
    log_info fonts "No fonts directory found. Creating one now..."
    mkdir -p "$HOME/.local/share/fonts"
  fi
  log_info fonts "Copying font files..."
  cp "$CONFIG/fonts/font-files/*.ttf" "$HOME/.local/share/fonts/"
  log_info fonts "Creating cach..."
  fc-cache -f
  log_success fonts "Done."
}
main
