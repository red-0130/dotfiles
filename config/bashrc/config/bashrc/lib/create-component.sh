function mkcomp() {
  local CSS=false
  local COMPONENT_NAME
  local COMPONENT_TYPE
  local SRC="$(pwd)/src"

  showHelp() {
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

  createDir() {
    if mkdir --parent "$COMPONENT_DIR"; then
      echo "[MKCOMP][SUCCESS]: Component directory created."
      return 0
    fi
    echo "[MKCOMP][ERROR]: Component directory not created."
    return 1
  }

  createCss() {
    touch "$COMPONENT_DIR/$COMPONENT_NAME.module.css" && return 0
  }

  importCss() {
    echo -e "import styled from \"./$COMPONENT_NAME.module.css\"\n\n$(cat "$COMPONENT_FILE")" >"$COMPONENT_FILE"
    return 0
  }

  createComponentFile() {
    cat <<-EOF >>$COMPONENT_FILE
function $COMPONENT_NAME() {
  return (
    <p>This is the $COMPONENT_NAME component</p>
  )
}

export default $COMPONENT_NAME;
EOF
    return 0
  }

  createIndex() {
    cat <<-EOF >"$COMPONENT_DIR/index.js"
export * from "./$COMPONENT_NAME.jsx";
export { default } from "./$COMPONENT_NAME.jsx";
EOF
    return 0
  }

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
      showHelp
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

  local COMPONENT_DIR="$SRC/$COMPONENT_TYPE$COMPONENT_NAME"
  local COMPONENT_FILE="$COMPONENT_DIR/$COMPONENT_NAME.jsx"

  if [[ ! -d "$SRC" ]]; then
    echo "[MKCOMP][ERROR]: 'src' directory not found. Make sure you are in a React project root."
    return 1
  fi

  createDir && createComponentFile && createIndex && echo "[MKCOMP][SUCCESS]: Component created."
  $CSS && createCss && importCss && echo "[MKCOMP][SUCCESS]: Stylesheet created and imported."

}

complete -W "--css --context --features --layout --pages --ui --common --help" mkcomp
