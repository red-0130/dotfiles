#!/usr/bin/env bash
if ! source "$BIN/path_exist.sh"; then exit 1; fi

main() {
  local CONFIG_FLATPAK="$HOME/.var/app/io.mpv.Mpv/config"
  local CONFIG_SYSTEM="$HOME/.config"
  log_info mpv "Applying config..."

  importFlatpakConfig() {
    if [[ ! -d "$CONFIG_FLATPAK/mpv" ]]; then
      log_info mpv "Flatpak App config directory not found. Creating now..."
      mkdir -p "$CONFIG_FLATPAK" && log_info mpv "Config directory created."
    else
      backup mpv "$CONFIG_FLATPAK/mpv"
      rm -rf "$CONFIG_FLATPAK/mpv"
    fi
    ln -sf "$CONFIG/mpv/config/mpv" "$CONFIG_FLATPAK/"
  }

  importSystemConfig() {
    if [[ -d "$CONFIG_SYSTEM/mpv" ]]; then
      backup mpv "$CONFIG_SYSTEM/mpv"
      rm -rf "$CONFIG_SYSTEM/mpv"
    fi

    if copy_config mpv; then
      log_success mpv "Successfully applied config."
    else
      log_error mpv "Config was not applied."
    fi
  }

  if command -v mpv &>/dev/null; then
    log_info mpv "System installation detected. Copying config..."
    importSystemConfig
  fi

  if ! flatpak list | grep mpv; then
    log_info mpv "Flatpak installation detected. Importing config..."
    importFlatpakConfig
  fi
}

main
