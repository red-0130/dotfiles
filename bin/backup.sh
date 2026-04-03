#!/usr/bin/env bash

createBackup() {
  local TARGET="$1"
  local APP=$(basename $TARGET)
  local TIMESTAMP=$(date "+%Y%m%d-%H%M%S")
  local DESTINATION="$HOME/.config.bak/"

  if mv -t $DESTINATION "$@" -b --suffix="-$TIMESTAMP"; then
    return 0
  fi
  return 1
}

checkExistingConfig() {
  local TARGET="$1"

  if [[ ! -e "$TARGET" ]]; then
    return 1
  fi

  if [[ -L "$TARGET" ]]; then
    return 1
  fi

  return 0
}

createBackupDirectory() {
  if [[ ! -d $HOME/.config.bak ]]; then
    mkdir -p $HOME/.config.back
    return 0
  fi
  return 0
}

backup() {
  local APP="$1"
  shift
  local TIMESTAMP=$(date "+%Y%m%d-%H%M%S")

  createBackupDirectory

  for ENTRY in "$@"; do
    if ! checkExistingConfig $ENTRY; then
      log -w "No config found skipping backup"
      return
    fi

    if createBackup $ENTRY; then
      log -s "Backup successfully created."
    else
      log -e "There was an error creating a backup."
      return 1
    fi
  done
  return 0
}
