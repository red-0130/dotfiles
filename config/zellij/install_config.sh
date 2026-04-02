main() {
  local APP="zellij"
  backup zellij "$HOME/.config/zellij"
  log -i "Applying config"
  if copy_config zellij; then
    log -s "Config was applied successfuly."
  else
    log -e "There was an error applying config for ${APP^^}"
    exit 1
  fi
}

main
