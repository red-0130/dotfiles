#!/bin/env bash

message() {
  local NOCOLOR='\e[0m'
  local GREEN='\e[32m'
  local BLUE='\e[34m'
  local RED='\e[31m'
  local YELLOW='\e[33m'
  local BOLD='\e[39;1m'
  local RESET='\e[0m'
  local TYPE="$1"
  local APPLICATION="$BOLD[$2]$RESET"
  local MESSAGE=$3
  local MESSAGE_TYPE=""

  case "$TYPE" in
  "success")
    MESSAGE_TYPE="$GREEN[SUCCESS]$RESET"
    ;;
  "error")
    MESSAGE_TYPE="$RED[ERROR]$RESET"
    ;;
  "warning")
    MESSAGE_TYPE="$YELLOW[WARNING]$RESET"
    ;;
  *)
    MESSAGE_TYPE="$RESET[INFO]"
    ;;
  esac

  echo -e "$APPLICATION$MESSAGE_TYPE: $MESSAGE"

}
