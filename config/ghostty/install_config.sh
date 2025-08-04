#!/usr/bin/env bash
if source $BIN/path_exist.sh; then return 0; else exit 1; fi

main() {
  log_info ghostty "Applying config..."
  if copy_config ghostty; then
    log_success ghostty "Finished applying config."
  fi
}
main
