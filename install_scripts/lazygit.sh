if ! source "$BIN/path_exist.sh"; then exit 1; fi

main() {
  local APP=lazygit
  log -i lazygit "Starting installation..."
  [[ -d "/tmp/lazygit"]] && rm -rf /tmp/lazygit
  local LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | \grep -Po '"tag_name": *"v\K[^"]*')
  local FILE="lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"

  if curl --create-dirs -sLO --output-dir /tmp/lazygit "https://github.com/jesseduffield/lazygit/releases/download/v$LAZYGIT_VERSION/$FILE"; then
    log -i "Filed downloaded. Starting installation..."
  else
    log -e "Install files could not be downloaded."
  fi

  tar xf "/tmp/lazygit/$FILE" lazygit

  if sudo install lazygit -D -t /usr/local/bin/; then
    log -s "Finished installing. Beginning cleanup..."
    if rm lazygit; then log -i "Done."; fi
  else
    log -r "There was an error installing Lazygit"
    return 1
  fi
}

main
