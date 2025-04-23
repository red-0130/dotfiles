#!/bin/env bash
main() {
  echo "Installing Oh-My-Bash"
  if installOhMyBash; then
    echo "Finished installing oh-my-bash"
    changeTheme
  fi
}
installOhMyBash() {
  bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)"
}
changeTheme() {
  BASHRC="$HOME/.bashrc"
  echo "Changing oh-my-bash theme"
  sed -i '/OSH_THEME/c\OSH_THEME=\"ht\"' "$BASHRC"
}

main "$@"
exit
