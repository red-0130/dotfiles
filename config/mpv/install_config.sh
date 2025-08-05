#!/usr/bin/env bash
if ! source "$BIN/path_exist.sh"; then exit 1; fi

main() {
  log_info mpv "Applying config..."
  if copy_config mpv; then
    log_success mpv "Successfully applied config."
  fi
}
main
