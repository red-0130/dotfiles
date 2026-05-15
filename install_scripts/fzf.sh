if ! source "$BIN/path_exist.sh"; then exit 1; fi

main() {
  local APP="fzf"
  log -i "Installing fzf..."
  log -i "Downloading install files from repo..."
  [[ -d "$HOME/.fzf" ]] && log -w "Removing existing installation..." && sudo rm -rf "$HOME/.fzf"
  if git clone --depth 1 https://github.com/junegunn/fzf.git $HOME/.fzf; then
    log -i "Files downloaded. Starting installation now."
  else
    log -e "Install files could not be downloaded."
    return 1
  fi

  if $HOME/.fzf/install --all; then
    log -s "Successfully installed."
    return 0
  else
    log -e "An error occured during installation."
    return 1
  fi
}

main
