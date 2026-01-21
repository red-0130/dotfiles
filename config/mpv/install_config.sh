#!/usr/bin/env bash
if ! source "$BIN/path_exist.sh"; then exit 1; fi

main() {
  APP="mpv"
  local CONFIG_FLATPAK="$HOME/.var/app/io.mpv.Mpv/config"
  local CONFIG_SYSTEM="$HOME/.config"
  log -i "Applying config..."

  importFlatpakConfig() {
    if [[ ! -d "$CONFIG_FLATPAK/mpv" ]]; then
      log -i "Flatpak App config directory not found. Creating now..."
      mkdir -p "$CONFIG_FLATPAK" && log -i "Config directory created."
    else
      backup mpv "$CONFIG_FLATPAK/mpv"
      rm -rf "$CONFIG_FLATPAK/mpv"
    fi
    ln -sf "$CONFIG/mpv/config/mpv" "$CONFIG_FLATPAK/"
    return 0
  }

  importSystemConfig() {
    if [[ -d "$CONFIG_SYSTEM/mpv" ]]; then
      backup mpv "$CONFIG_SYSTEM/mpv"
      rm -rf "$CONFIG_SYSTEM/mpv"
    fi

    if copy_config mpv; then
      log -s "Successfully applied config."
    else
      log -e "Config was not applied."
    fi
    return 0
  }

  if command -v mpv &>/dev/null; then
    log -i "System installation detected. Copying config..."
    importSystemConfig && log -s "System config applied."
  fi

  if flatpak list | grep mpv &>/dev/null; then
    log -i "Flatpak installation detected. Importing config..."
    importFlatpakConfig && log -s "Flatpak config applied."
  fi
}

main
