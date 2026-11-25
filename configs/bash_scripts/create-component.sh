_mkcomp_help() {
  cat <<-EOF
mkcomp NAME [OPTIONS...]

Create a jsx component bundle

Options:
  --css           Create and import a css stylesheet
  --ui            Create a UI component
  --features      Create a FEATURE component
  --context       Create a CONTEXT component
  --layout        Create a LAYOUT component
  --pages         Create a PAGE component
  --common        Create a COMMON component
  
  --help          Show this help

See https://github.com/red-0130/frontend-mentor-template
to see how to use the template
EOF
}

_mkcomp_create_dir() {
  local component_dir="$1"
  if mkdir --parent "$component_dir"; then
    echo "[MKCOMP][SUCCESS]: Component directory created."
    return 0
  fi
  echo "[MKCOMP][ERROR]: Component directory not created."
  return 1
}

_mkcomp_create_css() {
  local component_dir="$1"
  local component_name="$2"
  touch "$component_dir/$component_name.module.css"
}

_mkcomp_import_css() {
  local component_file="$1"
  local component_name="$2"
  printf 'import styled from "./%s.module.css"\n\n%s\n' "$component_name" "$(cat "$component_file")" >"$component_file"
}

_mkcomp_create_component() {
  local component_file="$1"
  local component_name="$2"
  cat <<-EOF >"$component_file"
function $component_name() {
  return (
    <p>This is the $component_name component</p>
  )
}

export default $component_name;
EOF
}

_mkcomp_create_index() {
  local component_dir="$1"
  local component_name="$2"
  cat <<-EOF >"$component_dir/index.js"
export * from "./$component_name.jsx";
export { default } from "./$component_name.jsx";
EOF
}

function mkcomp() {
  local CSS=false
  local COMPONENT_NAME=""
  local COMPONENT_TYPE=""
  local SRC="$(pwd)/src"

  if [[ $# -eq 0 ]]; then
    _mkcomp_help
    return 0
  fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
    --css)
      CSS=true
      shift
      ;;
    --context)
      COMPONENT_TYPE="context/"
      shift
      ;;
    --features)
      COMPONENT_TYPE="features/"
      shift
      ;;
    --layout)
      COMPONENT_TYPE="layout/"
      shift
      ;;
    --pages)
      COMPONENT_TYPE="pages/"
      shift
      ;;
    --ui)
      COMPONENT_TYPE="ui/"
      shift
      ;;
    --common)
      COMPONENT_TYPE="common/"
      shift
      ;;
    --help | -h)
      _mkcomp_help
      return 0
      ;;
    -*)
      echo "Unknown flag provided"
      return 1
      ;;
    *)
      COMPONENT_NAME="$1"
      shift
      ;;
    esac
  done

  if [[ -z "$COMPONENT_NAME" ]]; then
    echo "[MKCOMP][ERROR]: Component name is required." >&2
    _mkcomp_help
    return 1
  fi

  local COMPONENT_DIR="$SRC/$COMPONENT_TYPE$COMPONENT_NAME"
  local COMPONENT_FILE="$COMPONENT_DIR/$COMPONENT_NAME.jsx"

  if [[ ! -d "$SRC" ]]; then
    echo "[MKCOMP][ERROR]: 'src' directory not found. Make sure you are in a React project root."
    return 1
  fi

  _mkcomp_create_dir "$COMPONENT_DIR" \
    && _mkcomp_create_component "$COMPONENT_FILE" "$COMPONENT_NAME" \
    && _mkcomp_create_index "$COMPONENT_DIR" "$COMPONENT_NAME" \
    && echo "[MKCOMP][SUCCESS]: Component created."

  if [[ "$CSS" == true ]]; then
    _mkcomp_create_css "$COMPONENT_DIR" "$COMPONENT_NAME" \
      && _mkcomp_import_css "$COMPONENT_FILE" "$COMPONENT_NAME" \
      && echo "[MKCOMP][SUCCESS]: Stylesheet created and imported."
  fi
}

complete -W "--css --context --features --layout --pages --ui --common --help" mkcomp
