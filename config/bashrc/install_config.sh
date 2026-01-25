#!/usr/bin/env bash

if ! source "$BIN/path_exist.sh"; then exit 1; fi

main() {
  local APP="bashrc"
  local BASHRC="$HOME/.bashrc"
  local CUSTOM_BASH="# Custom bash sourcing"
  local ALIASES_PATH="# Bash custom alias location\nsource "\$HOME/.config/bashrc/aliases.sh""
  local CUSTOM_PATH="# Bash custom PATHS\nsource "\$HOME/.config/bashrc/paths.sh""
  local ENV_PATH="# Bash custom ENV\nsource "\$HOME/.config/bashrc/env.sh""
  local FZF='[ -f ~/.fzf.bash ] && source ~/.fzf.bash'

  log -i "Making backup of current bashrc config"
  backup bashrc "$HOME/.bashrc" "$HOME/.profile" "$HOME/.bash_profile"

  log -i "Applying bashrc file"
  if ! grep "$CUSTOM_BASH" "$BASHRC"; then
    echo -e "\n##################################################" >>$BASHRC
    echo $CUSTOM_BASH >>"$BASHRC"
    echo -e $ALIASES_PATH >>"$BASHRC"
    echo -e $CUSTOM_PATH >>"$BASHRC"
    echo -e $ENV_PATH >>"$BASHRC"
    echo "$FZF" >>"$BASHRC"
    echo -e "\n##################################################" >>$BASHRC
  fi

  _createBashProfile
  copy_config bashrc

  log -s "Transfer complete."
  log -w "You may need to restart the terminal for config to apply"
}

_createBashProfile() {
  tee -a "$HOME/.bash_profile" >/dev/null <<EOF
# BASH_PROFILE
# Includes existing profile config
[[ -f "\$HOME/.profile" ]] && source "\$HOME/.profile"

# Change directory on remote connect if workspace is set
[[ -f "\$HOME/.workspace" ]] && \
  source "\$HOME/.workspace" &&\
  cd "\$PROJECT_WORKSPACE"
  
export TERM=xterm
EOF
}

main

unset -f _createBashProfile
