if ! source "$BIN/path_exist.sh"; then exit 1; fi

main() {
  local APP="tree-sitter-cli"
  log -i "Installing tree-sitter-cli"
  log -i "Downloading from repo..."
  curl -sL https://github.com/tree-sitter/tree-sitter/releases/latest/download/tree-sitter-linux-x64.gz |
    gunzip >/tmp/tree-sitter && log -s "Download successful."
  chmod +x /tmp/tree-sitter
  sudo mv /tmp/tree-sitter /usr/local/bin/
  log -i "Finished installing tree-sitter-cli"
}

main
