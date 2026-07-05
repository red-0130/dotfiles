#!/usr/bin/env bash
if ! source "$BIN/path_exist.sh"; then exit 1; fi

main() {
  local APP=thorium
  log -i "Starting installation..."
  sudo rm -fv /etc/apt/sources.list.d/thorium.list &&
    sudo wget --no-hsts -P /etc/apt/sources.list.d/ \
      http://dl.thorium.rocks/debian/dists/stable/thorium.list &&
    sudo apt update &&
    sudo apt install -y thorium-browser &&
    log -s "Finished installing."
}

main
