#!/usr/bin/env bash
if ! source "$BIN/path_exist.sh"; then exit 1; fi

main() {
  log_info mpv "Applying config..."
  local CONFIG_FLATPAK="$HOME/.var/app/io.mpv.Mpv/config/"
  if [[ -d "$CONFIG_FLATPAK" ]]; then
    log_info mpv "Flatpak installation detected. Copying to Flatpak app."
    ln -sf "$CONFIG/mpv/config/mpv" "$HOME/.var/app/io.mpv.Mpv/config/"
  fi
  if copy_config mpv; then
    log_success mpv "Successfully applied config."
  fi
}
main
