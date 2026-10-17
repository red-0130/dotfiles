#!/usr/bin/env bash

main() {
  export APP="setup"
  export ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
  export BIN="$ROOT_DIR/bin"
  export INSTALL="$ROOT_DIR/install_scripts"
  export CONFIG="$ROOT_DIR/config"

  source "$BIN/log.sh"
  source "$BIN/backup.sh"
  source "$BIN/apply_config.sh"

  default_install() {
    log -i "Starting default configuration installation..."
    mkdir -p "$HOME/.config"
    createBackupDirectory

    local DEFAULT_CONFIGS=("bashrc" "zellij" "nvim" "gitconfig" "ssh" "superfile")

    for cfg in "${DEFAULT_CONFIGS[@]}"; do
      log -i "Applying $cfg config..."
      apply_config "$cfg"
    done

    log -s "Finished applying default configurations."
  }

  show_help() {
    cat <<EOF
Dotfiles Installer

Usage:
  ./setup.sh [OPTIONS] [CONFIG_NAMES...]

Options:
  -c, --config     Interactive configuration selector
  -a, --app        Interactive application installer
  -h, --help       Show this help message

Default (no arguments):
  Applies essential configurations: bashrc, zellij, nvim, gitconfig, ssh, and superfile.

Examples:
  ./setup.sh              # Apply default configurations
  ./setup.sh --config     # Interactively select configs to apply
  ./setup.sh --app        # Interactively select apps to install
  ./setup.sh nvim zellij  # Apply specific configurations
EOF
  }

  case "$1" in
    -h|--help)
      show_help
      ;;
    -c|--config)
      log -i "Starting interactive config install." -a "setup"
      source "$BIN/interactive_config_install.sh"
      ;;
    -a|--app)
      log -i "Starting interactive app install." -a "setup"
      source "$BIN/interactive_app_install.sh"
      ;;
    "")
      default_install
      ;;
    *)
      mkdir -p "$HOME/.config"
      createBackupDirectory
      for cfg in "$@"; do
        if [[ -d "$CONFIG/$cfg" ]]; then
          log -i "Applying $cfg config..."
          apply_config "$cfg"
        else
          log -e "Configuration '$cfg' does not exist in $CONFIG."
          show_help
          return 1
        fi
      done
      log -s "Finished applying selected configurations."
      ;;
  esac
}

main "$@"
