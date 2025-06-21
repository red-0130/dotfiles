#!/bin/env bash

log_info apt "Updating APT repo"
if ! sudo dpkg -s apt &>/dev/null; then
  log_error apt "ERROR: APT is not installed.\n"
  exit 1
else
  sudo apt update && log_success apt "APT sources updated."
fi
