#!/bin/env bash
main() {
  if [[ ! -e "$HOME/.oh-my-bash" ]]; then
    echo "Installing Oh-My-Bash"

    if installOhMyBash &>/dev/null; then
      echo "Finished installing oh-my-bash"
      changeTheme
    fi
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
