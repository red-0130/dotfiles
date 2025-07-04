#!/usr/bin/env bash

wsctl() {
  set-workspace() {
    local WORKSPACE
    if [[ "$1" != "" ]]; then
      WORKSPACE="$1"
    else
      WORKSPACE="$PWD"
    fi
    echo "Setting PROJECT_WORKSPACE to $WORKSPACE"
    echo "PROJECT_WORKSPACE=$WORKSPACE" >"$HOME/.workspace"
  }

  set-gemini-api() {
    local API
    if [[ "$1" != "" ]]; then
      echo "API not provided"
      exit 1
    else
      API="$PWD"
      echo "Setting GEMINI CLI API..."
      echo "export GEMINI_API_KEY=$API" >"$HOME/.gemini_api"
      echo "Done."
      exit 0
    fi
  }

  "$@"
}
