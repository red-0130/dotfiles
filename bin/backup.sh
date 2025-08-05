#!/usr/bin/env bash

if ! source "$BIN/path_exist.sh"; then exit 1; fi

backup() {
  local APP="$1"
  shift
  local ERROR=false
  local TIMESTAMP=$(date "+%Y%m%d-%H%M%S")
  local DESTINATION="$HOME/.config.bak/$APP-$TIMESTAMP"

  log_info backup "Creating backup of config files..."
  for ENTRY in "$@"; do
    if [[ ! -e $ENTRY ]]; then
      log_warning $APP "No existing config found."
      ERROR=true
    fi
    if [[ -L $ENTRY ]]; then
      log_warning $APP "Existing config is a symbolic link."
      ERROR=true
    fi
  done
  if $ERROR; then
    log_error "$APP" "There was an error creating a backup of config files."
    return 0
  fi

  if mv -t $DESTINATION "$@"; then
    log_info "$APP" "Successfully created a backup"
  fi
}
