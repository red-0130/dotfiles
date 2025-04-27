#!/bin/env bash

printf "Updating APT repo\n"
if ! sudo dpkg -s apt &>/dev/null; then
  printf "ERROR: APT is not installed.\n"
  exit 0
else
  printf "Updating apt repositories\n"
  sudo apt update
  # printf "Proceeding with system upgrade.\n"
  # sudo apt full-upgrade -y
fi
