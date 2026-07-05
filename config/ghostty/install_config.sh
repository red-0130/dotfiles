#!/usr/bin/env bash
if ! source "$BIN/path_exist.sh"; then exit 1; fi

main() {
  local APP=ghostty
  backup ghostty "$HOME/.config/ghostty"
  log -i "Applying config..."
  if copy_config ghostty; then
    log -s "Finished applying config."
  fi
}
main
