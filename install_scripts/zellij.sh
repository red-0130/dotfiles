#!/usr/bin/env bash

if ! source "$BIN/path_exist.sh"; then exit 1; fi

main() {
  local APP="zellij"
  log -i "Starting Zellij installation..."

  local LATEST_VERSION=$(curl -sL https://api.github.com/repos/zellij-org/zellij/releases/latest | grep -oP '"tag_name": "\K[^"]+' | sed 's/^v//')
  log -i "Found latest version: $LATEST_VERSION"

  local REPO_ADDRESS="https://github.com/zellij-org/zellij/releases/download/v$LATEST_VERSION/zellij-x86_64-unknown-linux-musl.tar.gz"

  log -i "Downloading latest version..."
  if _download; then
    log -i "Finished downloading the latest version. Starting installation..."
  else
    log -e "There was an error downloading the latest version of Zellij."
    exit 1
  fi

  log -i "Starting binary extraction..."
  if _extract; then
    log -i "Successfully extracted. Importing to /usr/local/bin"
    chmod a+x zellij
  else
    log -e "There was an error in extraction."
    exit 1
  fi

  log -i "Starting import..."
  if _import; then
    log -s "Successfully imported binary files."
  else
    log -e "Could not import binary files."
    return 1
  fi

  log -i "Cleaning up files..."
  if _cleanup; then
    log -i "Done."
  else
    log -e "Could not remove residual files."
  fi
}

_download() {
  if curl -sLO $REPO_ADDRESS; then
    return 0
  else
    return 1
  fi
}

_extract() {
  if tar -xvf zellij*.tar.gz; then
    return 0
  else
    return 1
  fi
}

_import() {
  if sudo mv zellij /usr/local/bin/; then
    return 0
  else
    return 1
  fi
}

_cleanup() {
  if rm zellij*; then
    return 0
  else
    return 1
  fi
}

main

unset -f main _download _extract _import
