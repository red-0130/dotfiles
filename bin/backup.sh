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
      ERROR=true
    fi
    if [[ -L $ENTRY ]]; then
      ERROR=true
    fi
  done
  if $ERROR; then
    log_error "$APP" "There was an error creating a backup of config files."
    exit 1
  fi

  if mv -t $DESTINATION "$@"; then
    log_info "$APP" "Successfully created a backup"
  fi
}
