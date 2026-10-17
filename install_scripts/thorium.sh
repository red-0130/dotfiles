#!/usr/bin/env bash
if ! source "$BIN/path_exist.sh"; then exit 1; fi

main() {
  local APP=thorium
  log -i "Starting installation..."
  if command -v apt &>/dev/null; then
    log -i "Installing using APT package manager."
    installDebian && log -s "Thorium is installed" || log -e "There was an error installing $APP"
    return 0
  fi
}

installDebian() {
  sudo rm -fv /etc/apt/sources.list.d/thorium.list &&
    sudo wget --no-hsts -P /etc/apt/sources.list.d/ \
      http://dl.thorium.rocks/debian/dists/stable/thorium.list &&
    sudo apt update &&
    sudo apt install -y thorium-browser
  return 0
}

main
