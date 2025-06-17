function set-workspace {
  local WORKSPACE
  if [[ "$1" != "" ]]; then
    WORKSPACE="$1"
  else
    WORKSPACE="$PWD"
  fi
  echo "Setting PROJECT_WORKSPACE to $WORKSPACE"
  echo "PROJECT_WORKSPACE=$WORKSPACE" >"$HOME/.workspace"
}
