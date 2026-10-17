#!/usr/bin/env bash

createBackupDirectory() {
  if [[ ! -d "$HOME/.config.bak" ]]; then
    log -i "Backup directory not found. It will now be created."
    mkdir -p "$HOME/.config.bak"
  fi
  return 0
}

checkExistingConfig() {
  local TARGET="$1"

  if [[ ! -e "$TARGET" && ! -L "$TARGET" ]]; then
    return 1
  fi

  if [[ -L "$TARGET" ]]; then
    return 1
  fi

  return 0
}

createBackup() {
  local TARGET="$1"
  local TIMESTAMP=$(date "+%Y%m%d-%H%M%S")
  local DESTINATION="$HOME/.config.bak"

  createBackupDirectory

  local base
  base=$(basename "$TARGET")

  # For shell init files, keep the original in place and copy to backup
  if [[ "$base" == ".bashrc" || "$base" == ".profile" || "$base" == ".bash_profile" ]]; then
    if cp -a "$TARGET" "$DESTINATION/${base}-${TIMESTAMP}"; then
      return 0
    fi
  else
    if mv -t "$DESTINATION" "$TARGET" -b --suffix="-$TIMESTAMP"; then
      return 0
    fi
  fi
  return 1
}

backup() {
  local APP="$1"
  shift

  createBackupDirectory

  for ENTRY in "$@"; do
    if ! checkExistingConfig "$ENTRY"; then
      log -w "No config found skipping backup"
      continue
    fi

    if createBackup "$ENTRY"; then
      log -s "Backup successfully created."
    else
      log -e "There was an error creating a backup."
      return 1
    fi
  done
  return 0
}
