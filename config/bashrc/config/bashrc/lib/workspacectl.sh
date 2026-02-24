#!/usr/bin/env bash

wsctl() {
  set-workspace() {
    local WORKSPACE
    if [[ -n "$1" ]]; then
      WORKSPACE="$1"
    else
      WORKSPACE="$PWD"
    fi
    echo "Setting PROJECT_WORKSPACE to $WORKSPACE"
    echo "PROJECT_WORKSPACE=$WORKSPACE" >"$HOME/.workspace"
  }

  set-gemini-api() {
    local API="$1"
    if [[ -z "$API" ]]; then
      echo "API key not provided"
      return 1
    else
      echo "Setting GEMINI CLI API..."
      echo "export GEMINI_API_KEY=$API" >"$HOME/.gemini_api"
      echo "Done."
      return 0
    fi
  }

  get-workspace() {
    [ -z "$PROJECT_WORKSPACE" ] && echo "Default workspace is not set" && exit 1
    echo "$PROJECT_WORKSPACE"
  }

  --reset() {
    if [[ -f "$HOME/.workspace" ]]; then rm "$HOME/.workspace"; fi
    if [[ -f "$HOME/.gemini_api" ]]; then rm "$HOME/.gemini_api"; fi
    unset PROJECT_WORKSPACE
    unset GEMINI_API_KEY
  }

  "$@"
}

complete -W "set-workspace set-gemini-api get-workspace" wsctl
