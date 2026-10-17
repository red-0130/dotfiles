#!/usr/bin/env bash
if ! source "$BIN/path_exist.sh"; then exit 1; fi

main() {
  local APP="uv"
  log -i "Installing $APP..."
  if curl -LsSf https://astral.sh/uv/install.sh | sh; then
    log -s "Finished installing $APP."
  else
    log -e "There was an error installing $APP."
  fi
}

main
