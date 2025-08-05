#!/usr/bin/env bash

if ! source "$BIN/path_exist.sh"; then exit 1; fi

main() {
  log_info superfile "Applying config..."
  copy_config superfile
  log_success superfile "Successfully applied config."
}
main
