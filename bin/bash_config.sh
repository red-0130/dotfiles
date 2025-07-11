#!/bin/env bash
bash_config() {
  source "$BIN/message.sh"
  log_info bashrc "Copying bash config into config directory"

  source "$BIN/config_apply.sh" "bashrc"

  local TIMESTAMP=$(date "+%Y%m%d-%H%M%S")
  local BACKUP_DIR="$HOME/.config.bak/bashrc-$TIMESTAMP"
  local BASHRC="$HOME/.bashrc"
  local CUSTOM_BASH="# Custom bash sourcing"
  local SPF_PATH="# Superfile cd_on_quit\nsource "\$HOME/.config/superfile/cd_on_quit.sh""
  local ALIASES_PATH="# Bash custom alias location\nsource "\$HOME/.config/bashrc/aliases.sh""
  local CUSTOM_PATH="# Bash custom PATHS\nsource "\$HOME/.config/bashrc/paths.sh""
  local ENV_PATH="# Bash custom ENV\nsource "\$HOME/.config/bashrc/env.sh""

  log_info BASHRC "Making backup of current bashrc config"
  mkdir -p "$BACKUP_DIR"
  cp "$HOME/.bashrc" "$BACKUP_DIR"
  mv "$HOME/.profile" "$BACKUP_DIR"

  log_info BASHRC "Applying bashrc file"
  if ! grep $CUSTOM_BASH $BASHRC; then
    echo -e "\n##################################################" >>$BASHRC
    echo $CUSTOM_BASH >>$BASHRC
    echo "eval \"\$(starship init bash)\"" >>$HOME/.bashrc
    echo -e $SPF_PATH >>$BASHRC
    echo -e $ALIASES_PATH >>$BASHRC
    echo -e $CUSTOM_PATH >>$BASHRC
    echo -e $ENV_PATH >>$BASHRC
    echo -e "\n##################################################" >>$BASHRC
  fi
  ln -sf "$ROOT_DIR/bashrc/.profile" "$HOME/.profile"
  ln -sf "$ROOT_DIR/bashrc/.bash_profile" "$HOME/.bash_profile"
  log_success BASHRC "Transfer complete."
  log_warning BASHRC "You may need to restart the terminal for config to apply"
}
