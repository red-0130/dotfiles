mkcomp() (
  local COMPONENT_NAME="$1"
  local CWD=$(pwd)
  local SRC="$CWD/src"
  local COMPONENT_DIR="$CWD/src/$COMPONENT_NAME"
  local INDEXFILE="$COMPONENT_DIR/index.js"
  local COMPONENT_FILE="$COMPONENT_DIR/$COMPONENT_NAME.jsx"

  createIndex() {
    if ! touch "$INDEXFILE"; then return 1; fi
    echo "export * from './$COMPONENT_NAME';" &>/dev/null >>$INDEXFILE
    echo "export { default } from './$COMPONENT_NAME';" &>/dev/null >>$INDEXFILE
    return 0
  }

  createComponentFile() {
    if ! touch "$COMPONENT_FILE"; then return 1; fi
    echo "function $COMPONENT_NAME() {" &>/dev/null >>$COMPONENT_FILE
    echo -e "\treturn (\n\t\t<p>This is the $COMPONENT_NAME component</p>\n\t);" &>/dev/null >>$COMPONENT_FILE
    echo "}" &>/dev/null >>$COMPONENT_FILE
    echo -e "\nexport default $COMPONENT_NAME;" &>/dev/null >>$COMPONENT_FILE
    return 0
  }

  createDir() {
    local TARGET_DIR="$SRC/$1"
    [[ ! -d "$TARGET_DIR" ]] && mkdir -p "$TARGET_DIR"
  }

  if [[ ! -d "$CWD/src" ]]; then
    echo "Project src/ directory not found."
    exit 1
  fi

  mkdir "$COMPONENT_DIR"

  if createIndex; then echo "Barrel file created"; fi
  if createComponentFile; then echo "Component file created"; fi

  case "$2" in
  --ui)
    createDir "ui"
    mv "$COMPONENT_DIR" "$SRC/ui"
    ;;
  --context)
    createDir "context"
    mv "$COMPONENT_DIR" "$SRC/context"
    ;;
  --features)
    createDir "features"
    mv "$COMPONENT_DIR" "$SRC/features"
    ;;
  --layout)
    createDir "layout"
    mv "$COMPONENT_DIR" "$SRC/layout"
    ;;
  --pages)
    createDir "pages"
    mv "$COMPONENT_DIR" "$SRC/pages"
    ;;
  2 | 3)
    echo 2 or 3
    ;;
  *)
    echo "Unknown component directory. Keeping component in 'src' directory"
    ;;
  esac
)
