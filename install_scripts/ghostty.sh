#!/usr/bin/env bash

if ! source "$BIN/path_exist.sh"; then exit 1; fi

main() {
  local APP="ghostty"
  log_info ghostty "Starting installation..."
  if curl -fsSL https://raw.githubusercontent.com/mkasberg/ghostty-ubuntu/HEAD/install.sh | bash; then
    log_success ghostty "Successfully installed."
    return 0
  else
    log_error ghostty "There was an error installing."
    log -w "Downloading universal AppImage as an alternative"
    if download; then
      log -s "AppImage downloaded to the user\'s Downloads directory."
      return 0
    else
      log -e "AppImage could not be downloaded."
      return 1
    fi
  fi
}

download() {
  local LATEST_VERSION="$(curl -sL https://api.github.com/repos/pkgforge-dev/ghostty-appimage/releases/latest |
    grep -Po "(?<=\"tag\_name\":\s\"v).*(?=\"\,)")"
  local ARCH="$(uname -m)"
  if curl -sSL https://github.com/pkgforge-dev/ghostty-appimage/releases/download/v${LATEST_VERSION}/Ghostty-${LATEST_VERSION}-${ARCH}.AppImage \
    --output "$HOME/Downloads" \
    --create-dirs; then
    return 0
  else
    return 1
  fi
}

main
