#!/bin/env bash

main () {
  local APP=apt
  log -i "Updating APT repo"
  if ! sudo dpkg -s apt &>/dev/null; then
    log -e "APT is not installed.\n"
    exit 1
  else
    sudo apt update && log -s "APT sources updated."
  fi
}

main
