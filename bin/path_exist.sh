#!/usr/bin/env bash

path_exist() {
  log_error() {
    local -u APP="$1"
    local MESSAGE="$2"
    local -u MESSAGE_TYPE="error"
    local -r COLOR="\e[31m"
    echo -e "\e[39;1m$COLOR[$APP][$MESSAGE_TYPE]:\e[0m $MESSAGE"
  }
  if [[ -z $ROOT_DIR ]] | [[ -z $BIN ]]; then
    log_error "PATH CHECK" "Install script "root" directory not detected. This could mean that the install script was executed directly or environmental variables were not properly set."
    return 1
  else
    return 0
  fi
}

path_exist "$@"
