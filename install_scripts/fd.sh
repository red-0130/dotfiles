if ! source "$BIN/path_exist.sh"; then exit 1; fi

main() {
  local APP="fd-find"
  if command -v fdfind &>/dev/null; then
    log -w "FD-FIND is already installed."
    return 0
  fi

  log -i "Installing fd-find"
  [[ -d /tmp/fd ]]rm -rf /tmp/fd

  local VERSION=$(curl -sL "https://api.github.com/repos/sharkdp/fd/releases/latest" | grep -Po '"tag_name": *"v\K[^"]*')
  local FILE="fd-musl_${VERSION}_amd64.deb"

  log -i "Downloading install files from repo..."
  if curl --create-dirs \
    -sLO --output-dir /tmp/fd/ "https://github.com/sharkdp/fd/releases/download/v$VERSION/$FILE"; then
    log -i "Files downloaded. Starting installation..."
  else
    log -e "Install files could not be downloaded."
    return 1
  fi

  if sudo dpkg -i /tmp/fd/$FILE; then
    log -s "Successfully installed."
    return 0
  else
    log -e "There was an error installing."
    return 1
  fi
}

main
