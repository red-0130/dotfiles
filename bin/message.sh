#!/bin/env bash

main() {
  local NOCOLOR='\e[0m'
  local GREEN='\e[32m'
  local BLUE='\e[34m'
  local RED='\e[31m'
  local YELLOW='\e[33m'
  local TYPE="$1"
  local APPLICATION="$BLUE[$2]$NOCOLOR"
  local MESSAGE=$3
  local MESSAGE_TYPE=""

  case "$TYPE" in
  "success")
    MESSAGE_TYPE="$GREEN[SUCCESS]$NOCOLOR"
    ;;
  "error")
    MESSAGE_TYPE="$RED[ERROR]$NOCOLOR"
    ;;
  "warning")
    MESSAGE_TYPE="$YELLOW[WARNING]$NOCOLOR"
    ;;
  *)
    MESSAGE_TYPE="$NOCOLOR[INFO]"
    ;;
  esac

  echo -e "$APPLICATION$MESSAGE_TYPE: $MESSAGE"

}

main "$@"
