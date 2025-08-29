#!/usr/bin/env bash

log() {
  local COLOR
  local -u APP="$APP"
  if [[ -z "$APP" ]]; then
    APP="script"
  fi
  local MESSAGE
  local -u MESSAGE_TYPE="info"
  local -r OPTIONS=":i:w:s:e:a:h"
  local OPTIND MESSAGE=""

  _logMessage() {
    echo -e "\e[39;1m$COLOR[$APP][$MESSAGE_TYPE]:\e[0m $MESSAGE"
  }

  _help() {
    cat <<EOF
    Description: A shell logger with colours.

    log -i|w|s|e [MESSAGE] [-a APP_NAME]
         w  Log an info type message
         s  Log an success type message
         e  Log an error type message
EOF
  }

  while getopts "$OPTIONS" OPT; do
    case "$OPT" in
    i)
      COLOR=""
      MESSAGE_TYPE="info"
      MESSAGE="$OPTARG"
      ;;
    w)
      COLOR="\e[33m"
      MESSAGE_TYPE="warning"
      MESSAGE="$OPTARG"
      ;;
    s)
      COLOR="\e[32m"
      MESSAGE_TYPE="success"
      MESSAGE="$OPTARG"
      ;;
    e)
      COLOR="\e[31m"
      MESSAGE_TYPE="error"
      MESSAGE="$OPTARG"
      ;;
    a)
      APP="$OPTARG"
      ;;
    h)
      _help
      return 1
      ;;
    ?)
      COLOR="\e[31m"
      MESSAGE_TYPE="error"
      APP="log-script"
      MESSAGE="Unknown option/argument provided."
      _logMessage
      _help
      return 1
      ;;
    esac
  done

  shift $((OPTIND - 1))

  if [[ -n "$MESSAGE" ]]; then
    _logMessage
  else
    _help
    return 1
  fi
}
