#!/usr/bin/env bash
if ! source "$BIN/path_exist.sh"; then exit 1; fi

main() {
  local CONFIG_FLATPAK="$HOME/.var/app/io.mpv.Mpv/config"
  log_info mpv "Applying config..."
  if [[ -d "$CONFIG_FLATPAK" ]]; then
    backup mpv "$CONFIG_FLATPAK/mpv"
    log_info mpv "Flatpak installation detected. Copying to Flatpak app."
    ln -sf "$CONFIG/mpv/config/mpv" "$CONFIG_FLATPAK/"
    return 0
  fi
  backup mpv "$HOME/.config/mpv"
  if copy_config mpv; then
    log_success mpv "Successfully applied config."
  fi
}
main
