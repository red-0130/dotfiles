if ! source "$BIN/path_exist.sh"; then exit 1; fi

main() {
  local APP=ripgrep
  log -i "Installing ripgrep"
  [[ -d /tmp/ripgrep ]] && rm -rf /tmp/ripgrep
  local RIPGREP_VERSION=$(curl -s "https://api.github.com/repos/BurntSushi/ripgrep/releases/latest" | grep "tag_name" | cut -d '"' -f 4)
  local FILE="ripgrep_$RIPGREP_VERSION-1_amd64.deb"

  log -i "Downloading install files from repo..."
  if curl --create-dirs \
    -sLO --output-dir /tmp/ripgrep/ "https://github.com/BurntSushi/ripgrep/releases/download/$RIPGREP_VERSION/$FILE"; then
    log -i "Files downloaded. Starting installation..."
  else
    log -e "Install files could not be downloaded."
    return 1
  fi

  if sudo dpkg -i /tmp/ripgrep/$FILE; then
    log -s "Successfully installed."
    return 0
  else
    log -e "There was an error installing."
    return 1
  fi
}

main
