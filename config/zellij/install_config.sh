main() {
  local APP="zellij"
  backup zellij "$HOME/.config/zellij"
  log -i "Applying config"
  if copy_config zellij; then
    log -s "Config was applied successfully."
  else
    log -e "There was an error applying config for ${APP^^}"
    return 1
  fi
}

main
